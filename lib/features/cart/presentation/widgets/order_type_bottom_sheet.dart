import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
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

  @override
  void initState() {
    super.initState();
    _fetchBranches();
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

          final cubit = context.read<CheckoutCubit>();
          if (_branches.isNotEmpty && cubit.state.branchId == null) {
            cubit.setBranch(_branches.first.id, branchTitle: _branches.first.title);
          }
        });
      }
    } catch (_) {
      // Clear branches on error so no hardcoded data is shown
      if (mounted) {
        setState(() {
          _branches = [];
        });
      }
    } finally {
      if (mounted) setState(() => _isLoadingBranches = false);
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

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: SafeArea(
        top: false,
        child: BlocBuilder<CheckoutCubit, CheckoutState>(
          builder: (context, state) {
            final isDelivery = state.isDelivery;

            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
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
              const SizedBox(height: 16),

              // Title
              Text(
                'checkout.delivery_type'.tr(),
                textAlign: TextAlign.center,
                style: AppTextStyles.h3.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.textTheme.headlineMedium?.color,
                ),
              ),
              const SizedBox(height: 16),

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
              const SizedBox(height: 20),

              // Delivery Mode Content
              if (isDelivery) ...[
                if (state.address != null && state.address!.trim().isNotEmpty) ...[
                  // Tanlangan manzil
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCard : AppColors.neutral50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? AppColors.darkBorder : AppColors.neutral200.withValues(alpha: 0.8),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.location_on_rounded, color: AppColors.primary, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'checkout.address'.tr(),
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: isDark ? AppColors.neutral400 : AppColors.neutral600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                state.address!,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.labelMedium.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: theme.textTheme.bodyLarge?.color,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Xaritadan manzil tanlash tugmasi
                InkWell(
                  onTap: () => _pickDeliveryLocation(useMyLocation: false),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCard : const Color(0xFFF8F9FA),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark ? AppColors.darkBorder : const Color(0xFFEDF2F7),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.map_rounded, color: AppColors.primary, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'checkout.pick_on_map'.tr(),
                          style: AppTextStyles.labelMedium.copyWith(
                            fontWeight: FontWeight.w700,
                            color: theme.textTheme.bodyLarge?.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ] else ...[
                // Pickup Mode Branch Picker
                Text(
                  'checkout.select_branch'.tr(),
                  style: AppTextStyles.labelMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.neutral300 : AppColors.neutral700,
                  ),
                ),
                const SizedBox(height: 8),
                if (_isLoadingBranches)
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _branches.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final branch = _branches[index];
                      final isSelected = state.branchId == branch.id;

                      return InkWell(
                        onTap: () {
                          context.read<CheckoutCubit>().setBranch(branch.id, branchTitle: branch.title);
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? (isDark ? AppColors.primary.withValues(alpha: 0.15) : AppColors.primaryLight)
                                : (isDark ? AppColors.darkCard : AppColors.neutral50),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary
                                  : (isDark ? AppColors.darkBorder : AppColors.neutral200.withValues(alpha: 0.8)),
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.storefront_rounded,
                                color: isSelected ? AppColors.primary : AppColors.neutral500,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      branch.title,
                                      style: AppTextStyles.labelMedium.copyWith(
                                        color: isSelected
                                            ? AppColors.primary
                                            : theme.textTheme.bodyMedium?.color,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 20),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
              ],
              const SizedBox(height: 24),

              // Confirm button
              AppButton(
                text: 'checkout.confirm'.tr(),
                onTap: () => Navigator.pop(context),
              ),
              ],
            ),
          );
        },
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
