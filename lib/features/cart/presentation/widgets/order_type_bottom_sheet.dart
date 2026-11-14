import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pizza_strada/core/models/saved_address_model.dart';
import 'package:pizza_strada/core/network/api_client.dart';
import 'package:pizza_strada/core/storage/secure_storage.dart';
import 'package:pizza_strada/core/theme/app_colors.dart';
import 'package:pizza_strada/core/theme/app_text_styles.dart';
import 'package:pizza_strada/core/widgets/app_button.dart';
import 'package:pizza_strada/features/cart/presentation/bloc/checkout/checkout_cubit.dart';
import 'package:pizza_strada/features/cart/presentation/bloc/checkout/checkout_state.dart';
import 'package:pizza_strada/features/cart/data/models/checkout_branch_model.dart';

/// Modal bottom sheet matching pizzastrada.uz order type modal.
class OrderTypeBottomSheet extends StatefulWidget {
  const OrderTypeBottomSheet({super.key});

  @override
  State<OrderTypeBottomSheet> createState() => _OrderTypeBottomSheetState();
}

class _OrderTypeBottomSheetState extends State<OrderTypeBottomSheet> {
  List<CheckoutBranch> _branches = [];
  bool _isLoadingBranches = false;

  List<SavedAddressModel> _savedAddresses = [];
  bool _isLoadingAddresses = false;
  bool _isPickedFromMap = false;

  @override
  void initState() {
    super.initState();
    _fetchBranches();
    _fetchSavedAddresses();
  }

  Future<void> _fetchBranches() async {
    setState(() => _isLoadingBranches = true);
    try {
      final list = await SecureStorage.getOrFetchBranches();
      if (mounted) {
        setState(() {
          _branches = list
              .map((e) => CheckoutBranch.fromJson(e))
              .toList();
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _branches = [];
        });
      }
    } finally {
      if (mounted) setState(() => _isLoadingBranches = false);
    }
  }

  Future<void> _fetchSavedAddresses() async {
    setState(() => _isLoadingAddresses = true);
    final addressMap = <String, SavedAddressModel>{};
    try {
      final localList = await SecureStorage.getSavedAddresses();
      for (final a in localList) {
        final key = a.address.trim().toLowerCase();
        if (key.isNotEmpty) addressMap[key] = a;
      }
      if (mounted && addressMap.isNotEmpty) {
        setState(() {
          _savedAddresses = addressMap.values.toList();
        });
      }

      final token = await SecureStorage.getToken();
      if (token != null && token.isNotEmpty) {
        final response = await ApiClient().get('addresses');
        final dynamic rawAddresses = (response is Map && response['data'] != null)
            ? response['data']
            : response;

        if (rawAddresses is List) {
          for (final item in rawAddresses) {
            if (item is Map<String, dynamic>) {
              final serverAddr = SavedAddressModel.fromJson(item);
              if (serverAddr.address.trim().isNotEmpty) {
                final key = serverAddr.address.trim().toLowerCase();
                addressMap[key] = serverAddr;
                await SecureStorage.saveAddress(serverAddr);
              }
            }
          }
        }
      }
    } catch (_) {
    } finally {
      if (mounted) {
        setState(() {
          _savedAddresses = addressMap.values.toList();
          _isLoadingAddresses = false;
        });
      }
    }
  }

  Future<void> _pickDeliveryLocation({bool useMyLocation = false}) async {
    final checkoutState = context.read<CheckoutCubit>().state;
    final result = await context.push<Map<String, dynamic>>(
      '/map-picker',
      extra: {
        'lat': checkoutState.lat,
        'lng': checkoutState.lng,
        'useMyLocation': useMyLocation,
      },
    );
    if (result != null && mounted) {
      final lat = (result['lat'] as num?)?.toDouble();
      final lng = (result['lng'] as num?)?.toDouble();
      final address = result['address'] as String?;
      if (address != null && address.isNotEmpty) {
        setState(() {
          _isPickedFromMap = true;
        });
        context.read<CheckoutCubit>().setAddressAndCalculateDelivery(
              lat ?? 0.0,
              lng ?? 0.0,
              address,
            );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenHeight = MediaQuery.of(context).size.height;
    // Har ikkala tabda (Доставка / Самовывоз) bir xil va barqaror balandlik
    final sheetHeight = (screenHeight * 0.60).clamp(490.0, 560.0);

    return Container(
      height: sheetHeight,
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: SafeArea(
        top: false,
        child: BlocBuilder<CheckoutCubit, CheckoutState>(
          builder: (context, state) {
            final isDelivery = state.isDelivery;
            final hasAddress = state.address != null && state.address!.trim().isNotEmpty;
            final selectedSavedIndex = _savedAddresses.indexWhere((item) =>
                item.address.trim().toLowerCase() == state.address?.trim().toLowerCase() ||
                (state.lat != null &&
                    state.lng != null &&
                    (state.lat! - item.lat).abs() < 0.0001 &&
                    (state.lng! - item.lng).abs() < 0.0001));

            final effectiveSavedIndex = _isPickedFromMap ? -1 : selectedSavedIndex;
            final isMapSelected = _isPickedFromMap || (hasAddress && effectiveSavedIndex == -1);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Drag Handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.neutral700 : AppColors.neutral300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Title
                Text(
                  'checkout.delivery_type'.tr(),
                  textAlign: TextAlign.center,
                  style: AppTextStyles.h3.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.textTheme.headlineMedium?.color,
                  ),
                ),
                const SizedBox(height: 14),

                // Delivery / Pickup Segment Selector Buttons
                Row(
                  children: [
                    Expanded(
                      child: _buildTypeButton(
                        context,
                        title: 'checkout.delivery'.tr(),
                        icon: Icons.delivery_dining_rounded,
                        isSelected: isDelivery,
                        onTap: () {
                          context.read<CheckoutCubit>().setDeliveryType(true);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTypeButton(
                        context,
                        title: 'checkout.pickup'.tr(),
                        icon: Icons.storefront_rounded,
                        isSelected: !isDelivery,
                        onTap: () {
                          context.read<CheckoutCubit>().setDeliveryType(false);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Section Title
                Text(
                  isDelivery
                      ? 'checkout.delivery_location'.tr()
                      : 'checkout.select_branch'.tr(),
                  style: AppTextStyles.labelMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.neutral300 : AppColors.neutral700,
                  ),
                ),
                const SizedBox(height: 10),

                // Scrollable Content Area (Fixed Height Container: never resizes bottom sheet)
                Expanded(
                  child: isDelivery
                      ? ListView(
                          physics: const BouncingScrollPhysics(),
                          children: [
                            // 1. Xaritadan tanlash
                            _buildOptionCard(
                              context,
                              title: 'checkout.pick_on_map'.tr(),
                              subtitle: isMapSelected && hasAddress
                                  ? state.address!
                                  : 'map.pick_on_map_subtitle'.tr(),
                              icon: Icons.map_outlined,
                              isSelected: isMapSelected,
                              onTap: () => _pickDeliveryLocation(useMyLocation: false),
                            ),

                            // Loading indicator
                            if (_isLoadingAddresses && _savedAddresses.isEmpty)
                              const Padding(
                                padding: EdgeInsets.all(12.0),
                                child: Center(
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                                  ),
                                ),
                              ),

                            // Saqlangan manzillar (raqamlarsiz, toza format)
                            ..._savedAddresses.asMap().entries.map((entry) {
                              final index = entry.key;
                              final item = entry.value;
                              final isSelected = !isMapSelected && effectiveSavedIndex == index;

                              final title = item.label.isNotEmpty && item.label != item.address
                                  ? item.label
                                  : item.address;
                              final subtitle = item.detailsSummary.isNotEmpty
                                  ? item.detailsSummary
                                  : (item.label.isNotEmpty && item.label != item.address
                                      ? item.address
                                      : 'checkout.saved_address'.tr());

                              return _buildOptionCard(
                                context,
                                title: title,
                                subtitle: subtitle,
                                icon: Icons.location_on_rounded,
                                isSelected: isSelected,
                                onTap: () {
                                  setState(() {
                                    _isPickedFromMap = false;
                                  });
                                  context.read<CheckoutCubit>().setAddressAndCalculateDelivery(
                                        item.lat,
                                        item.lng,
                                        item.address,
                                      );
                                  context.read<CheckoutCubit>().setAddressDetails(
                                        apartment: item.apartment,
                                        floor: item.floor,
                                        entrance: item.entrance,
                                        doorPhone: null,
                                      );
                                },
                              );
                            }),
                          ],
                        )
                      : (_isLoadingBranches
                          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                          : ListView.builder(
                              physics: const BouncingScrollPhysics(),
                              itemCount: _branches.length,
                              itemBuilder: (context, index) {
                                final branch = _branches[index];
                                final isSelected = state.branchId == branch.id;

                                return _buildOptionCard(
                                  context,
                                  title: branch.title,
                                  subtitle: 'checkout.pickup_branch_hint'.tr(),
                                  icon: Icons.storefront_rounded,
                                  isSelected: isSelected,
                                  onTap: () {
                                    context.read<CheckoutCubit>().setBranch(branch.id, branchTitle: branch.title);
                                  },
                                );
                              },
                            )),
                ),

                const SizedBox(height: 12),

                // Confirm button (always pinned at the bottom)
                AppButton(
                  text: 'checkout.confirm'.tr(),
                  onTap: () => Navigator.pop(context),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildOptionCard(
    BuildContext context, {
    required String title,
    String? subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? AppColors.primary.withValues(alpha: 0.15) : AppColors.primaryLight)
                : (isDark ? AppColors.darkCard : const Color(0xFFF8F9FA)),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? AppColors.primary
                  : (isDark ? AppColors.darkBorder : const Color(0xFFEDF2F7)),
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary.withValues(alpha: 0.15)
                      : (isDark ? AppColors.neutral700 : AppColors.neutral200.withValues(alpha: 0.6)),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: isSelected ? AppColors.primary : AppColors.neutral500,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.labelMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : AppColors.neutral900,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subtitle != null && subtitle.trim().isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: isDark ? AppColors.neutral400 : AppColors.neutral500,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                color: isSelected ? AppColors.primary : AppColors.neutral400,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeButton(
    BuildContext context, {
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : (isDark ? AppColors.darkCard : AppColors.neutral100),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : (isDark ? AppColors.darkBorder : AppColors.neutral200),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? Colors.white : (isDark ? AppColors.neutral400 : AppColors.neutral700),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: AppTextStyles.labelMedium.copyWith(
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : (isDark ? AppColors.neutral300 : AppColors.neutral800),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
