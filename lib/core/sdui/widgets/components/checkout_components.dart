import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/models/saved_address_model.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../../features/cart/presentation/bloc/cart_cubit.dart';
import '../../../../features/cart/presentation/bloc/checkout/checkout_cubit.dart';
import '../../../../features/cart/presentation/bloc/checkout/checkout_state.dart';
import '../../../../features/cart/presentation/widgets/order_type_bottom_sheet.dart';
import '../../../../features/home/presentation/bloc/home_cubit.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../utils/number_formatter.dart';
import '../../models/section_model.dart';
import '../../registry/action_dispatcher.dart';

/// 🛵 Checkout: Yetkazish / Olib ketish Switcher
class SDUIOrderTypeComponent extends StatelessWidget {
  final SDUISectionModel section;
  final SDUIActionHandler onAction;

  const SDUIOrderTypeComponent({
    super.key,
    required this.section,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final props = section.properties;
    final deliveryText = props['delivery_title']?.toString() ?? 'checkout.delivery'.tr();
    final pickupText = props['pickup_title']?.toString() ?? 'checkout.pickup'.tr();

    return BlocBuilder<CheckoutCubit, CheckoutState>(
      builder: (context, state) {
        final isDelivery = state.isDelivery;

        return Container(
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 6),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : const Color(0xFFF1F3F5),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    context.read<CheckoutCubit>().setOrderType(true);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isDelivery
                          ? (isDark ? AppColors.darkSurface : Colors.white)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: isDelivery ? AppColors.softShadow(isDark) : null,
                    ),
                    child: Text(
                      deliveryText,
                      style: AppTextStyles.labelMedium.copyWith(
                        fontWeight: isDelivery ? FontWeight.w800 : FontWeight.w600,
                        color: isDelivery ? AppColors.primary : AppColors.neutral500,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    context.read<CheckoutCubit>().setOrderType(false);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: !isDelivery
                          ? (isDark ? AppColors.darkSurface : Colors.white)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: !isDelivery ? AppColors.softShadow(isDark) : null,
                    ),
                    child: Text(
                      pickupText,
                      style: AppTextStyles.labelMedium.copyWith(
                        fontWeight: !isDelivery ? FontWeight.w800 : FontWeight.w600,
                        color: !isDelivery ? AppColors.primary : AppColors.neutral500,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// 📍 Checkout: Manzil kiritish & Xarita (2x2 grid: Podyezd, Qavat, Xonadon, Domofon - zamonaviy UI)
class SDUIAddressSelectorComponent extends StatefulWidget {
  final SDUISectionModel section;
  final SDUIActionHandler onAction;

  const SDUIAddressSelectorComponent({
    super.key,
    required this.section,
    required this.onAction,
  });

  @override
  State<SDUIAddressSelectorComponent> createState() => _SDUIAddressSelectorComponentState();
}

class _SDUIAddressSelectorComponentState extends State<SDUIAddressSelectorComponent> {
  final _entranceController = TextEditingController();
  final _floorController = TextEditingController();
  final _apartmentController = TextEditingController();
  final _doorPhoneController = TextEditingController();

  List<SavedAddressModel> _savedAddresses = [];
  int _branchCount = 3;

  @override
  void initState() {
    super.initState();
    final cubitState = context.read<CheckoutCubit>().state;
    _entranceController.text = cubitState.entrance ?? '';
    _floorController.text = cubitState.floor ?? '';
    _apartmentController.text = cubitState.apartment ?? '';
    _doorPhoneController.text = cubitState.doorPhone ?? '';
    _loadSavedAddressesAndBranches();
  }

  Future<void> _loadSavedAddressesAndBranches() async {
    // 1. Filiallar sonini olish (keshdan yoki API dan)
    try {
      final branches = await SecureStorage.getOrFetchBranches();
      if (branches.isNotEmpty && mounted) {
        _branchCount = branches.length;
      }
    } catch (_) {}

    // 2. Mahalliy saqlangan manzillarni yuklash
    final localList = await SecureStorage.getSavedAddresses();
    final addressMap = <String, SavedAddressModel>{};
    for (final a in localList) {
      final key = a.address.trim().toLowerCase();
      if (key.isNotEmpty) addressMap[key] = a;
    }

    // 3. Agar bo'sh bo'lsa, foydalanuvchining avvalgi buyurtmalaridan manzillarni yuklash
    if (addressMap.isEmpty) {
      try {
        final token = await SecureStorage.getToken();
        if (token != null && token.isNotEmpty) {
          final response = await ApiClient().get('orders');
          final dynamic rawOrders = (response is Map && response['data'] != null)
              ? response['data']
              : response;

          if (rawOrders is List) {
            for (final order in rawOrders) {
              if (order is Map<String, dynamic>) {
                final addressStr = (order['address'] as String?)?.trim();
                if (addressStr != null && addressStr.isNotEmpty) {
                  final key = addressStr.toLowerCase();
                  if (!addressMap.containsKey(key)) {
                    final lat = double.tryParse(order['latitude']?.toString() ?? '') ?? 39.6542;
                    final lng = double.tryParse(order['longitude']?.toString() ?? '') ?? 66.9597;
                    final fromOrder = SavedAddressModel(
                      id: 'order_${order['id'] ?? DateTime.now().millisecondsSinceEpoch}',
                      label: addressStr,
                      address: addressStr,
                      lat: lat,
                      lng: lng,
                    );
                    addressMap[key] = fromOrder;
                    await SecureStorage.saveAddress(fromOrder);
                  }
                }
              }
            }
          }
        }
      } catch (_) {}
    }

    if (mounted) {
      setState(() {
        _savedAddresses = addressMap.values.toList();
      });
    }
  }

  void _syncDetailsToCubit() {
    context.read<CheckoutCubit>().setAddressDetails(
      entrance: _entranceController.text.trim(),
      floor: _floorController.text.trim(),
      apartment: _apartmentController.text.trim(),
      doorPhone: _doorPhoneController.text.trim(),
    );
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _floorController.dispose();
    _apartmentController.dispose();
    _doorPhoneController.dispose();
    super.dispose();
  }

  Widget _buildMiniInput({
    required BuildContext context,
    required String label,
    required IconData icon,
    required TextEditingController controller,
    required bool isDark,
  }) {
    return Expanded(
      child: SizedBox(
        height: 52,
        child: TextField(
          controller: controller,
          autocorrect: false,
          enableSuggestions: false,
          onChanged: (_) => _syncDetailsToCubit(),
          textInputAction: TextInputAction.next,
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 13.5,
            color: isDark ? Colors.white : AppColors.neutral900,
          ),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: AppTextStyles.bodySmall.copyWith(
              color: isDark ? AppColors.neutral400 : AppColors.neutral500,
              fontSize: 12.5,
            ),
            floatingLabelBehavior: FloatingLabelBehavior.auto,
            prefixIcon: Icon(icon, size: 18, color: AppColors.primary),
            prefixIconConstraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            filled: true,
            fillColor: isDark ? AppColors.darkSurface : Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: isDark ? AppColors.darkBorder : const Color(0xFFE5E7EB),
                width: 1.2,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: isDark ? AppColors.darkBorder : const Color(0xFFE5E7EB),
                width: 1.2,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 1.5,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickOnMap(BuildContext context, {bool useMyLocation = false}) async {
    HapticFeedback.lightImpact();
    context.read<CheckoutCubit>().setLocationError(false);
    final checkoutState = context.read<CheckoutCubit>().state;
    final result = await context.push<Map<String, dynamic>>(
      '/map-picker',
      extra: {
        'lat': checkoutState.lat,
        'lng': checkoutState.lng,
        'useMyLocation': useMyLocation,
      },
    );
    if (result != null && context.mounted) {
      final lat = (result['lat'] as num?)?.toDouble();
      final lng = (result['lng'] as num?)?.toDouble();
      final address = result['address'] as String?;
      if (lat != null && lng != null && address != null && address.trim().isNotEmpty) {
        final trimmed = address.trim();
        context.read<CheckoutCubit>().setAddressAndCalculateDelivery(
              lat,
              lng,
              trimmed,
            );
        await SecureStorage.saveAddress(
          SavedAddressModel(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            label: trimmed,
            address: trimmed,
            lat: lat,
            lng: lng,
          ),
        );
        _loadSavedAddressesAndBranches();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final props = widget.section.properties;
    final title = props['title']?.toString() ?? 'checkout.delivery_location'.tr();

    return BlocBuilder<CheckoutCubit, CheckoutState>(
      builder: (context, state) {
        if (!state.isDelivery) return const SizedBox.shrink();

        final hasLocationError = state.showLocationError &&
            (state.address == null || state.address!.trim().isEmpty);
        final displayedSaved = _savedAddresses.take(_branchCount).toList();

        return Container(
          margin: const EdgeInsets.fromLTRB(16, 6, 16, 6),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: hasLocationError
                  ? AppColors.error
                  : (isDark ? AppColors.darkBorder : AppColors.neutral200),
              width: hasLocationError ? 1.8 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: hasLocationError
                    ? AppColors.error.withValues(alpha: 0.15)
                    : Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sarlavha
              Text(
                title,
                style: AppTextStyles.h4.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: isDark ? Colors.white : AppColors.neutral900,
                ),
              ),
              if (hasLocationError) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'checkout.address_required'.tr(),
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 12),

              // 1. Xaritadan tanlang
              InkWell(
                onTap: () => _pickOnMap(context),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: isDark ? 0.12 : 0.06),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.35),
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.map_outlined,
                          color: AppColors.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '1. ${'checkout.pick_on_map'.tr()}',
                              style: AppTextStyles.labelMedium.copyWith(
                                fontWeight: FontWeight.w800,
                                color: isDark ? Colors.white : AppColors.neutral900,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Xaritada belgilash yoki GPS orqali',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: isDark ? AppColors.neutral400 : AppColors.neutral500,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded, color: AppColors.primary, size: 22),
                    ],
                  ),
                ),
              ),

              // 2, 3, ... Eski locationlar (max: branch sonigacha)
              if (displayedSaved.isNotEmpty) ...[
                const SizedBox(height: 6),
                ...displayedSaved.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  final isSelected = state.address == item.address ||
                      (state.lat != null &&
                          state.lng != null &&
                          (state.lat! - item.lat).abs() < 0.0001 &&
                          (state.lng! - item.lng).abs() < 0.0001);

                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: InkWell(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        context.read<CheckoutCubit>().setAddressAndCalculateDelivery(
                              item.lat,
                              item.lng,
                              item.address,
                            );
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary.withValues(alpha: isDark ? 0.15 : 0.08)
                              : (isDark ? AppColors.neutral800 : const Color(0xFFF8F9FA)),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : (isDark ? AppColors.darkBorder : const Color(0xFFEDF2F7)),
                            width: isSelected ? 1.5 : 1.2,
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
                                Icons.location_on_rounded,
                                color: isSelected ? AppColors.primary : AppColors.neutral500,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${index + 2}. ${item.label.isNotEmpty && item.label != item.address ? item.label : item.address}',
                                    style: AppTextStyles.labelMedium.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? Colors.white : AppColors.neutral900,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (item.label.isNotEmpty && item.label != item.address) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      item.address,
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
                }),
              ],

              // ── 2x2 Grid (Podyezd, Qavat, Xonadon, Domofon - ixtiyoriy) ──
              const SizedBox(height: 14),
              Row(
                children: [
                  _buildMiniInput(
                    context: context,
                    label: 'checkout.entrance'.tr(),
                    icon: Icons.meeting_room_outlined,
                    controller: _entranceController,
                    isDark: isDark,
                  ),
                  const SizedBox(width: 10),
                  _buildMiniInput(
                    context: context,
                    label: 'checkout.floor'.tr(),
                    icon: Icons.stairs_outlined,
                    controller: _floorController,
                    isDark: isDark,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _buildMiniInput(
                    context: context,
                    label: 'checkout.apartment'.tr(),
                    icon: Icons.home_outlined,
                    controller: _apartmentController,
                    isDark: isDark,
                  ),
                  const SizedBox(width: 10),
                  _buildMiniInput(
                    context: context,
                    label: 'checkout.doorphone'.tr(),
                    icon: Icons.dialpad_outlined,
                    controller: _doorPhoneController,
                    isDark: isDark,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

/// 🏪 Checkout: Filial tanlash (Pickup Branch)
class SDUIPickupBranchComponent extends StatelessWidget {
  final SDUISectionModel section;
  final SDUIActionHandler onAction;

  const SDUIPickupBranchComponent({
    super.key,
    required this.section,
    required this.onAction,
  });

  void _openBranchSelector(BuildContext context) {
    HapticFeedback.selectionClick();
    context.read<CheckoutCubit>().setLocationError(false);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const OrderTypeBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final props = section.properties;
    final title = props['title']?.toString() ?? 'checkout.select_branch'.tr();

    return BlocBuilder<CheckoutCubit, CheckoutState>(
      builder: (context, state) {
        if (state.isDelivery) return const SizedBox.shrink();

        final hasBranch = state.branchId != null && state.branchId!.trim().isNotEmpty;
        final hasBranchError = state.showLocationError && !hasBranch;
        final branchTitle = hasBranch
            ? (state.branchTitle ?? 'checkout.selected_branch'.tr())
            : 'checkout.no_branch_selected'.tr();

        return Container(
          margin: const EdgeInsets.fromLTRB(16, 6, 16, 6),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: hasBranchError
                  ? AppColors.error
                  : (hasBranch
                      ? (isDark ? AppColors.darkBorder : AppColors.neutral200)
                      : AppColors.primary.withValues(alpha: 0.6)),
              width: (hasBranchError || !hasBranch) ? 1.8 : 1.0,
            ),
            boxShadow: hasBranchError
                ? [
                    BoxShadow(
                      color: AppColors.error.withValues(alpha: 0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.neutral500,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _openBranchSelector(context),
                    child: Text(
                      'common.change'.tr(),
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              if (hasBranchError) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'checkout.branch_required'.tr(),
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 10),
              InkWell(
                onTap: () => _openBranchSelector(context),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.neutral800 : const Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.storefront_rounded, color: AppColors.primary, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              branchTitle,
                              style: AppTextStyles.labelMedium.copyWith(
                                fontWeight: FontWeight.w700,
                                color: hasBranch
                                    ? (isDark ? Colors.white : AppColors.neutral900)
                                    : AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'checkout.working_hours'.tr(),
                              style: AppTextStyles.bodySmall.copyWith(color: AppColors.neutral500),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded, color: AppColors.neutral400),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// ⏰ Checkout: Yetkazish vaqti (Time Slot) - Yashirilgan (Faqat order statusda ko'rsatiladi)
class SDUIDeliveryTimeSlotComponent extends StatelessWidget {
  final SDUISectionModel section;
  final SDUIActionHandler onAction;

  const SDUIDeliveryTimeSlotComponent({
    super.key,
    required this.section,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

/// 👤 Checkout: Qabul qiluvchi ma'lumotlari (Haqiqiy foydalanuvchi ma'lumotlari va pageni o'zida tahrirlash)
class SDUICustomerInfoComponent extends StatefulWidget {
  final SDUISectionModel section;
  final SDUIActionHandler onAction;
  final bool initiallyEditing;
  final VoidCallback? onEditingComplete;

  const SDUICustomerInfoComponent({
    super.key,
    required this.section,
    required this.onAction,
    this.initiallyEditing = false,
    this.onEditingComplete,
  });

  @override
  State<SDUICustomerInfoComponent> createState() => _SDUICustomerInfoComponentState();
}

class _SDUICustomerInfoComponentState extends State<SDUICustomerInfoComponent> {
  String _profileName = 'checkout.guest_customer'.tr();
  String _profilePhone = '+998 -- --- -- --';
  bool _isEditing = false;
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _isEditing = widget.initiallyEditing;
    _loadUser();
  }

  @override
  void didUpdateWidget(covariant SDUICustomerInfoComponent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initiallyEditing && !oldWidget.initiallyEditing) {
      _startEditing();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadUser() async {
    final name = await SecureStorage.getUserName();
    final phone = await SecureStorage.getUserPhone();
    if (mounted) {
      setState(() {
        if (name != null && name.trim().isNotEmpty) {
          _profileName = name.trim();
        }
        if (phone != null && phone.trim().isNotEmpty) {
          _profilePhone = NumberFormatter.formatPhone(phone.trim());
        }
      });
    }
  }

  void _startEditing() {
    final checkoutState = context.read<CheckoutCubit>().state;
    final currentCustomName = checkoutState.recipientName;
    final currentCustomPhone = checkoutState.recipientPhone;

    _nameController.text = (currentCustomName != null && currentCustomName.trim().isNotEmpty)
        ? currentCustomName.trim()
        : (_profileName == 'checkout.guest_customer'.tr() ? '' : _profileName);

    _phoneController.text = (currentCustomPhone != null && currentCustomPhone.trim().isNotEmpty)
        ? currentCustomPhone.trim()
        : (_profilePhone.contains('--') ? '+998 ' : _profilePhone);

    setState(() => _isEditing = true);
  }

  void _saveRecipient() {
    HapticFeedback.mediumImpact();
    final newName = _nameController.text.trim();
    final newPhone = _phoneController.text.trim();

    context.read<CheckoutCubit>().setRecipient(
      name: newName.isNotEmpty ? newName : null,
      phone: newPhone.isNotEmpty ? newPhone : null,
    );
    setState(() => _isEditing = false);
    widget.onEditingComplete?.call();
  }

  void _resetToProfile() {
    HapticFeedback.lightImpact();
    context.read<CheckoutCubit>().setRecipient(name: null, phone: null);
    setState(() => _isEditing = false);
    widget.onEditingComplete?.call();
  }

  void _cancelEditing() {
    HapticFeedback.lightImpact();
    setState(() => _isEditing = false);
    widget.onEditingComplete?.call();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final props = widget.section.properties;
    final title = props['title']?.toString() ?? 'checkout.recipient_title'.tr();

    return BlocBuilder<CheckoutCubit, CheckoutState>(
      builder: (context, checkoutState) {
        final customName = checkoutState.recipientName;
        final customPhone = checkoutState.recipientPhone;
        final isCustomized = (customName != null && customName.trim().isNotEmpty) ||
            (customPhone != null && customPhone.trim().isNotEmpty);

        final displayName = (customName != null && customName.trim().isNotEmpty)
            ? customName.trim()
            : _profileName;
        final displayPhone = (customPhone != null && customPhone.trim().isNotEmpty)
            ? customPhone.trim()
            : _profilePhone;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.fromLTRB(16, 6, 16, 6),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isCustomized
                  ? AppColors.primary.withValues(alpha: 0.35)
                  : (isDark ? AppColors.darkBorder : AppColors.neutral200),
            ),
            boxShadow: [
              BoxShadow(
                color: isCustomized
                    ? AppColors.primary.withValues(alpha: 0.05)
                    : Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        _isEditing ? 'checkout.edit_recipient'.tr() : title,
                        style: AppTextStyles.h4.copyWith(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: isDark ? Colors.white : AppColors.neutral900,
                        ),
                      ),
                      if (isCustomized && !_isEditing) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Boshqa shaxs',
                            style: AppTextStyles.bodyExtraSmall.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                              fontSize: 10.5,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (!_isEditing)
                    TextButton.icon(
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        _startEditing();
                      },
                      icon: const Icon(Icons.edit_outlined, size: 14, color: AppColors.primary),
                      label: Text(
                        'common.change'.tr(),
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    )
                  else
                    IconButton(
                      onPressed: _cancelEditing,
                      icon: const Icon(Icons.close_rounded, size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: 'common.cancel'.tr(),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              if (!_isEditing) ...[
                // Oddiy ko'rinish (Ko'rish rejimi)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.neutral800 : const Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : const Color(0xFFEDF2F7),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.person_outline_rounded, size: 20, color: AppColors.primary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayName,
                              style: AppTextStyles.labelMedium.copyWith(
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white : AppColors.neutral900,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              displayPhone,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: isDark ? AppColors.neutral400 : AppColors.neutral500,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                // Inline tahrirlash rejimi (Pagening o'zida!)
                Text(
                  'Buyurtmani qabul qilib oluvchi shaxs ma\'lumotlarini kiriting',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: isDark ? AppColors.neutral400 : AppColors.neutral500,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 12),

                // Ism inputi
                TextField(
                  controller: _nameController,
                  autocorrect: false,
                  enableSuggestions: false,
                  textCapitalization: TextCapitalization.words,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : AppColors.neutral900,
                  ),
                  decoration: InputDecoration(
                    labelText: 'checkout.recipient_name'.tr(),
                    labelStyle: AppTextStyles.bodySmall.copyWith(
                      color: isDark ? AppColors.neutral400 : AppColors.neutral500,
                    ),
                    prefixIcon: const Icon(Icons.person_outline_rounded, color: AppColors.primary, size: 20),
                    filled: true,
                    fillColor: isDark ? AppColors.darkSurface : AppColors.neutral100,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.neutral200, width: 1.2),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Telefon inputi
                TextField(
                  controller: _phoneController,
                  autocorrect: false,
                  enableSuggestions: false,
                  keyboardType: TextInputType.phone,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : AppColors.neutral900,
                  ),
                  decoration: InputDecoration(
                    labelText: 'checkout.recipient_phone'.tr(),
                    labelStyle: AppTextStyles.bodySmall.copyWith(
                      color: isDark ? AppColors.neutral400 : AppColors.neutral500,
                    ),
                    prefixIcon: const Icon(Icons.phone_outlined, color: AppColors.primary, size: 20),
                    filled: true,
                    fillColor: isDark ? AppColors.darkSurface : AppColors.neutral100,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.neutral200, width: 1.2),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Tugmalar
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 46,
                        child: ElevatedButton(
                          onPressed: _saveRecipient,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: Text(
                            'common.save'.tr(),
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      height: 46,
                      child: OutlinedButton(
                        onPressed: _cancelEditing,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: isDark ? AppColors.neutral300 : AppColors.neutral700,
                          side: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.neutral300),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: Text(
                          'common.cancel'.tr(),
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                      ),
                    ),
                  ],
                ),
                if (isCustomized) ...[
                  const SizedBox(height: 8),
                  Center(
                    child: TextButton(
                      onPressed: _resetToProfile,
                      child: Text(
                        'checkout.reset_to_my_info'.tr(),
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ],
          ),
        );
      },
    );
  }
}

/// 💳 Checkout: To'lov usullari (Backenddan kelgan ro'yxat bo'yicha: Payme, Naqd pul; Terminal yo'q)
class SDUIPaymentMethodComponent extends StatefulWidget {
  final SDUISectionModel section;
  final SDUIActionHandler onAction;

  const SDUIPaymentMethodComponent({
    super.key,
    required this.section,
    required this.onAction,
  });

  @override
  State<SDUIPaymentMethodComponent> createState() => _SDUIPaymentMethodComponentState();
}

class _SDUIPaymentMethodComponentState extends State<SDUIPaymentMethodComponent> {
  late String _selectedMethod;

  @override
  void initState() {
    super.initState();
    _selectedMethod = context.read<CheckoutCubit>().state.selectedPaymentMethodKey;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final props = widget.section.properties;
    final title = props['title']?.toString() ?? 'checkout.payment_method_title'.tr();

    // 1. Backend SDUI items tekshiruvi
    final List<Map<String, dynamic>> options = [];
    if (widget.section.items.isNotEmpty) {
      for (final item in widget.section.items) {
        final key = (item.properties['key']?.toString() ?? item.id).toLowerCase();
        // Terminal yo'q - qat'iy chetlatiladi
        if (key == 'terminal') continue;

        final isPayme = key == 'payme' || key == '1';
        options.add({
          'key': isPayme ? 'payme' : 'cash',
          'title': item.properties['title']?.toString() ?? (isPayme ? 'Payme' : 'checkout.cash'.tr()),
          'subtitle': item.properties['subtitle']?.toString() ?? (isPayme ? 'checkout.online_payment'.tr() : 'checkout.to_courier'.tr()),
          'icon': isPayme ? Icons.credit_card_rounded : Icons.payments_outlined,
        });
      }
    }

    // 2. Agar SDUI items bo'sh bo'lsa, HomeState settings tekshiriladi
    if (options.isEmpty) {
      final homeState = context.watch<HomeCubit>().state;
      if (homeState is HomeLoaded && homeState.settings?.paymentMethods != null) {
        for (final m in homeState.settings!.paymentMethods) {
          final k = m.key.toLowerCase();
          if (k == 'terminal') continue;
          final isPayme = k == '1' || k == 'payme';
          options.add({
            'key': isPayme ? 'payme' : 'cash',
            'title': m.value.isNotEmpty ? m.value : (isPayme ? 'Payme' : 'checkout.cash'.tr()),
            'subtitle': isPayme ? 'checkout.online_payment'.tr() : 'checkout.to_courier'.tr(),
            'icon': isPayme ? Icons.credit_card_rounded : Icons.payments_outlined,
          });
        }
      }
    }

    // 3. Standart fallback (terminal mutlaqo yo'q)
    if (options.isEmpty) {
      options.addAll([
        {'key': 'payme', 'title': 'Payme', 'subtitle': 'checkout.online_payment'.tr(), 'icon': Icons.credit_card_rounded},
        {'key': 'cash', 'title': 'checkout.cash'.tr(), 'subtitle': 'checkout.to_courier'.tr(), 'icon': Icons.payments_outlined},
      ]);
    }

    // Agar tanlangan to'lov usuli mavjud ro'yxatda bo'lmasa, birinchisini avtomatik tanlaymiz
    if (!options.any((o) => o['key'] == _selectedMethod)) {
      _selectedMethod = options.first['key'] as String;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.read<CheckoutCubit>().setPaymentMethod(_selectedMethod);
      });
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.neutral200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.h4.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: isDark ? Colors.white : AppColors.neutral900,
            ),
          ),
          const SizedBox(height: 12),

          // Horizontal Payment Cards
          Row(
            children: options.map((opt) {
              final isSelected = _selectedMethod == opt['key'];

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedMethod = opt['key'] as String);
                      context.read<CheckoutCubit>().setPaymentMethod(opt['key'] as String);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? (isDark ? AppColors.darkSurface : Colors.white)
                            : (isDark ? AppColors.neutral800 : const Color(0xFFF8F9FA)),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? AppColors.primary : (isDark ? AppColors.darkBorder : AppColors.neutral200),
                          width: isSelected ? 2 : 1,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.18),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Icon(
                                opt['icon'] as IconData,
                                color: isSelected ? AppColors.primary : AppColors.neutral500,
                                size: 24,
                              ),
                              if (isSelected)
                                const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 18),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            opt['title'] as String,
                            style: AppTextStyles.labelMedium.copyWith(
                              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                              color: isSelected
                                  ? (isDark ? Colors.white : AppColors.neutral900)
                                  : AppColors.neutral700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            opt['subtitle'] as String,
                            style: AppTextStyles.bodySmall.copyWith(
                              fontSize: 11,
                              color: AppColors.neutral500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          if (_selectedMethod == 'cash') ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark ? AppColors.neutral800 : const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, size: 16, color: AppColors.neutral500),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'checkout.cash_notice'.tr(),
                      style: AppTextStyles.bodyExtraSmall.copyWith(
                        color: AppColors.neutral600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// 📝 Checkout: Kuryer uchun izoh (Faqat bitta joyda)
class SDUICourierNotesComponent extends StatefulWidget {
  final SDUISectionModel section;
  final SDUIActionHandler onAction;

  const SDUICourierNotesComponent({
    super.key,
    required this.section,
    required this.onAction,
  });

  @override
  State<SDUICourierNotesComponent> createState() => _SDUICourierNotesComponentState();
}

class _SDUICourierNotesComponentState extends State<SDUICourierNotesComponent> {
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final cubitState = context.read<CheckoutCubit>().state;
    _notesController.text = cubitState.courierNote ?? '';
  }

  void _syncPreferences() {
    context.read<CheckoutCubit>().setCourierPreferences(
      note: _notesController.text.trim(),
      noUtensils: false,
    );
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final props = widget.section.properties;
    final title = props['title']?.toString() ?? 'checkout.courier_notes_title'.tr();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.neutral200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.neutral500,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _notesController,
            onChanged: (_) => _syncPreferences(),
            maxLines: 2,
            decoration: InputDecoration(
              hintText: 'checkout.courier_notes_hint'.tr(),
              hintStyle: AppTextStyles.bodySmall.copyWith(color: AppColors.neutral400),
              filled: true,
              fillColor: isDark ? AppColors.darkSurface : const Color(0xFFF8F9FA),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: isDark ? AppColors.darkBorder : AppColors.neutral200,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: isDark ? AppColors.darkBorder : AppColors.neutral200,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 1.5,
                ),
              ),
            ),
            style: AppTextStyles.bodySmall.copyWith(
              color: isDark ? Colors.white : AppColors.neutral900,
            ),
          ),
        ],
      ),
    );
  }
}

/// 🧾 Checkout: Yakuniy narx hisob-kitobi (Checkout Summary Card)
class SDUICheckoutSummaryComponent extends StatelessWidget {
  final SDUISectionModel section;
  final SDUIActionHandler onAction;

  const SDUICheckoutSummaryComponent({
    super.key,
    required this.section,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final props = section.properties;
    final title = props['title']?.toString() ?? 'checkout.order_summary'.tr();

    return BlocBuilder<CartCubit, CartState>(
      builder: (context, cartState) {
        return BlocBuilder<CheckoutCubit, CheckoutState>(
          builder: (context, checkoutState) {
            final discount = checkoutState.calculateDiscount(cartState.subtotal);

            final deliveryPrice = checkoutState.isDelivery ? checkoutState.deliveryPrice : 0.0;
            final subtotalAfterDiscount = (cartState.subtotal - discount).clamp(0.0, double.infinity);
            final total = subtotalAfterDiscount + deliveryPrice;

            return Container(
              margin: const EdgeInsets.fromLTRB(16, 6, 16, 6),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.neutral200,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${'cart.subtotal'.tr()}:', style: AppTextStyles.bodySmall.copyWith(color: AppColors.neutral500)),
                      Text(
                        '${NumberFormatter.formatSum(cartState.subtotal)} ${'common.currency'.tr()}',
                        style: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  if (discount > 0) ...[
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          checkoutState.isPercentagePromo
                              ? '${'checkout.promo_discount'.tr()} (${checkoutState.appliedPromoCode} • ${checkoutState.promoValue?.toInt()}%):'
                              : '${'checkout.promo_discount'.tr()} (${checkoutState.appliedPromoCode}):',
                          style: AppTextStyles.bodySmall.copyWith(color: AppColors.success),
                        ),
                        Text(
                          '-${NumberFormatter.formatSum(discount)} ${'common.currency'.tr()}',
                          style: AppTextStyles.labelMedium.copyWith(
                            color: AppColors.success,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${'cart.delivery'.tr()}:', style: AppTextStyles.bodySmall.copyWith(color: AppColors.neutral500)),
                      Text(
                        !checkoutState.isDelivery || deliveryPrice == 0
                            ? 'checkout.free'.tr()
                            : '${NumberFormatter.formatSum(deliveryPrice)} ${'common.currency'.tr()}',
                        style: AppTextStyles.labelMedium.copyWith(
                          color: (!checkoutState.isDelivery || deliveryPrice == 0) ? AppColors.success : null,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider(height: 1)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${'cart.total'.tr()}:', style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w800)),
                      Text(
                        '${NumberFormatter.formatSum(total)} ${'common.currency'.tr()}',
                        style: AppTextStyles.priceLarge.copyWith(color: AppColors.primary, fontSize: 18),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

/// 🚀 Checkout: Buyurtma berish tugmasi (Submit Order CTA)
class SDUISubmitOrderCtaComponent extends StatelessWidget {
  final SDUISectionModel section;
  final SDUIActionHandler onAction;

  const SDUISubmitOrderCtaComponent({
    super.key,
    required this.section,
    required this.onAction,
  });

  Future<void> _handleSubmit(BuildContext context, CheckoutState checkoutState, CartState cartState) async {
    HapticFeedback.heavyImpact();

    // 1. Savatcha tekshiruvi
    if (cartState.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('cart.empty_error'.tr()),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // 2. Yetkazib berish rejimi tekshiruvi
    if (checkoutState.isDelivery) {
      if (checkoutState.address == null ||
          checkoutState.address!.trim().isEmpty ||
          checkoutState.lat == null ||
          checkoutState.lng == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('checkout.select_address_error'.tr()),
            backgroundColor: AppColors.error,
          ),
        );
        final result = await context.push<Map<String, dynamic>>(
          '/map-picker',
          extra: {
            'lat': checkoutState.lat,
            'lng': checkoutState.lng,
            'useMyLocation': true,
          },
        );
        if (result != null && context.mounted) {
          final lat = (result['lat'] as num?)?.toDouble();
          final lng = (result['lng'] as num?)?.toDouble();
          final address = result['address'] as String?;
          if (lat != null && lng != null && address != null && address.trim().isNotEmpty) {
            context.read<CheckoutCubit>().setAddressAndCalculateDelivery(
                  lat,
                  lng,
                  address.trim(),
                );
          }
        }
        return;
      }
    } else {
      // 3. Olib ketish rejimi tekshiruvi
      if (checkoutState.branchId == null || checkoutState.branchId!.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('checkout.select_branch_error'.tr()),
            backgroundColor: AppColors.error,
          ),
        );
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => const OrderTypeBottomSheet(),
        );
        return;
      }
    }

    // 4. Mahsulotlar ro'yxatini shakllantirish
    final products = cartState.items.map((item) {
      return {
        'id': item.variant?.id ?? item.product.id,
        'product_id': item.product.id,
        if (item.variant != null) 'variant_id': item.variant!.id,
        'quantity': item.quantity,
      };
    }).toList();

    // 5. Buyurtmani yuborish
    context.read<CheckoutCubit>().submitOrder(products: products);
  }

  @override
  Widget build(BuildContext context) {
    final props = section.properties;
    final btnText = props['button_text']?.toString() ?? 'checkout.confirm_order_btn'.tr();

    return BlocConsumer<CheckoutCubit, CheckoutState>(
      listenWhen: (previous, current) =>
          previous.isSubmitting != current.isSubmitting ||
          previous.submitError != current.submitError ||
          previous.successData != current.successData,
      listener: (context, state) {
        if (state.submitError != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.submitError!),
              backgroundColor: AppColors.error,
            ),
          );
          context.read<CheckoutCubit>().clearSubmitError();
        }

        if (state.successData != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('checkout.order_placed'.tr()),
              backgroundColor: AppColors.success,
            ),
          );

          // Savatni tozalash va holatni tiklash
          context.read<CartCubit>().clear();
          final orderData = state.successData!;
          final orderId = orderData['id']?.toString();
          context.read<CheckoutCubit>().resetAfterOrder();

          if (orderId != null && orderId.isNotEmpty) {
            context.go('/order/$orderId', extra: orderData);
          } else {
            context.go('/orders');
          }
        }
      },
      builder: (context, checkoutState) {
        return BlocBuilder<CartCubit, CartState>(
          builder: (context, cartState) {
            final isSubmitting = checkoutState.isSubmitting;

            return Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () => _handleSubmit(context, checkoutState, cartState),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.6),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 4,
                  ),
                  child: isSubmitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Text(
                          btnText,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                        ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
