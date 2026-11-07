import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../features/cart/presentation/bloc/cart_cubit.dart';
import '../../../../features/cart/presentation/bloc/checkout/checkout_cubit.dart';
import '../../../../features/cart/presentation/bloc/checkout/checkout_state.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../utils/number_formatter.dart';
import '../../models/sdui_section_model.dart';
import '../../registry/sdui_action_dispatcher.dart';

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
    final deliveryText = props['delivery_title']?.toString() ?? 'Yetkazib berish';
    final pickupText = props['pickup_title']?.toString() ?? 'Olib ketish';

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

/// 📍 Checkout: Manzil kiritish & Xarita (Yandex Eats / EVOS "Where to" uslubi)
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
  final _courierNotesController = TextEditingController();
  bool _leaveAtDoor = false;

  void _syncDetailsToCubit() {
    final parts = <String>[];
    if (_entranceController.text.trim().isNotEmpty) {
      parts.add('Podyezd: ${_entranceController.text.trim()}');
    }
    if (_floorController.text.trim().isNotEmpty) {
      parts.add('Qavat: ${_floorController.text.trim()}');
    }
    if (_apartmentController.text.trim().isNotEmpty) {
      parts.add('Xonadon: ${_apartmentController.text.trim()}');
    }
    if (_doorPhoneController.text.trim().isNotEmpty) {
      parts.add('Domofon: ${_doorPhoneController.text.trim()}');
    }
    if (_leaveAtDoor) {
      parts.add('Eshik oldida qoldiring');
    }
    if (_courierNotesController.text.trim().isNotEmpty) {
      parts.add('Izoh: ${_courierNotesController.text.trim()}');
    }

    context.read<CheckoutCubit>().setComment(parts.join(', '));
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _floorController.dispose();
    _apartmentController.dispose();
    _doorPhoneController.dispose();
    _courierNotesController.dispose();
    super.dispose();
  }

  Widget _buildMiniInput({
    required BuildContext context,
    required String label,
    required TextEditingController controller,
    required bool isDark,
  }) {
    return Expanded(
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.neutral800 : const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.neutral200,
          ),
        ),
        alignment: Alignment.centerLeft,
        child: TextField(
          controller: controller,
          onChanged: (_) => _syncDetailsToCubit(),
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: isDark ? Colors.white : AppColors.neutral900,
          ),
          decoration: InputDecoration(
            hintText: label,
            hintStyle: AppTextStyles.bodySmall.copyWith(
              color: AppColors.neutral400,
              fontSize: 12,
            ),
            border: InputBorder.none,
            isDense: true,
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final props = widget.section.properties;
    final title = props['title']?.toString() ?? 'Where to';
    final mapBtn = props['map_button_text']?.toString() ?? 'Xaritadan tanlash';

    return BlocBuilder<CheckoutCubit, CheckoutState>(
      builder: (context, state) {
        if (!state.isDelivery) return const SizedBox.shrink();

        final address = state.address ?? 'Manzil tanlanmagan';

        return Container(
          margin: const EdgeInsets.fromLTRB(16, 6, 16, 6),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(18),
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
              // Title Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.h4.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: isDark ? Colors.white : AppColors.neutral900,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => context.push('/map-picker'),
                    child: Text(
                      mapBtn,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Address Bar with Home Icon
              GestureDetector(
                onTap: () => context.push('/map-picker'),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.neutral800 : const Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : const Color(0xFFEDF2F7),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.home_rounded, color: AppColors.primary, size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          address,
                          style: AppTextStyles.labelMedium.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded, color: AppColors.neutral400),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // ── 2x2 Grid (Podyezd, Qavat, Xonadon, Domofon - Optional) ──
              Row(
                children: [
                  _buildMiniInput(
                    context: context,
                    label: 'Podyezd (Entrance)',
                    controller: _entranceController,
                    isDark: isDark,
                  ),
                  const SizedBox(width: 8),
                  _buildMiniInput(
                    context: context,
                    label: 'Qavat (Floor)',
                    controller: _floorController,
                    isDark: isDark,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildMiniInput(
                    context: context,
                    label: 'Xonadon (Apartment)',
                    controller: _apartmentController,
                    isDark: isDark,
                  ),
                  const SizedBox(width: 8),
                  _buildMiniInput(
                    context: context,
                    label: 'Domofon (Door phone)',
                    controller: _doorPhoneController,
                    isDark: isDark,
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Courier Notes Input
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.neutral800 : const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.neutral200,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.chat_bubble_outline_rounded, size: 18, color: AppColors.neutral400),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _courierNotesController,
                        onChanged: (_) => _syncDetailsToCubit(),
                        style: AppTextStyles.bodySmall.copyWith(
                          color: isDark ? Colors.white : AppColors.neutral900,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Kuryer uchun ko\'rsatma (ixtiyoriy)...',
                          hintStyle: AppTextStyles.bodySmall.copyWith(color: AppColors.neutral400),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // "Leave at the door" (Eshik oldida qoldiring) Switch
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.door_front_door_outlined, size: 20, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Eshik oldida qoldiring',
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : AppColors.neutral900,
                        ),
                      ),
                    ],
                  ),
                  Switch(
                    value: _leaveAtDoor,
                    activeThumbColor: AppColors.primary,
                    onChanged: (val) {
                      setState(() => _leaveAtDoor = val);
                      _syncDetailsToCubit();
                    },
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final props = section.properties;
    final title = props['title']?.toString() ?? 'Filialni tanlang';

    return BlocBuilder<CheckoutCubit, CheckoutState>(
      builder: (context, state) {
        if (state.isDelivery) return const SizedBox.shrink();

        final branchTitle = state.branchTitle ?? 'Pizza Strada Yunusobod';

        return Container(
          margin: const EdgeInsets.fromLTRB(16, 6, 16, 6),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.neutral200,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTextStyles.labelSmall.copyWith(color: AppColors.neutral500, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.neutral800 : const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.storefront_rounded, color: AppColors.primary, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(branchTitle, style: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 2),
                          Text('Ish vaqti: 10:00 - 03:00', style: AppTextStyles.bodySmall.copyWith(color: AppColors.neutral500)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// ⏰ Checkout: Yetkazish vaqti (Time Slot)
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final props = section.properties;
    final title = props['title']?.toString() ?? 'Yetkazish vaqti';
    final asapText = props['asap_text']?.toString() ?? 'Iloji boricha tezroq (~35 daqiqa)';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.neutral200,
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.access_time_filled_rounded, color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.labelSmall.copyWith(color: AppColors.neutral500, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(asapText, style: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 20),
        ],
      ),
    );
  }
}

/// 👤 Checkout: Qabul qiluvchi ma'lumotlari
class SDUICustomerInfoComponent extends StatelessWidget {
  final SDUISectionModel section;
  final SDUIActionHandler onAction;

  const SDUICustomerInfoComponent({
    super.key,
    required this.section,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final props = section.properties;
    final title = props['title']?.toString() ?? 'Qabul qiluvchi ma\'lumotlari';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.neutral200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.labelSmall.copyWith(color: AppColors.neutral500, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? AppColors.neutral800 : const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(Icons.person_outline_rounded, size: 18, color: AppColors.neutral500),
                SizedBox(width: 10),
                Expanded(child: Text('Azizbek Rahimov', style: TextStyle(fontWeight: FontWeight.w600))),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? AppColors.neutral800 : const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(Icons.phone_outlined, size: 18, color: AppColors.neutral500),
                SizedBox(width: 10),
                Expanded(child: Text('+998 90 123 45 67', style: TextStyle(fontWeight: FontWeight.w600))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 💳 Checkout: To'lov usullari (Yandex Eats horizontal card selector uslubi)
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
  String _selectedMethod = 'payme';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final props = widget.section.properties;
    final title = props['title']?.toString() ?? 'Payment';

    final options = [
      {'key': 'payme', 'title': 'Payme', 'subtitle': 'Onlayn to\'lov', 'icon': Icons.credit_card_rounded},
      {'key': 'cash', 'title': 'Naqd pul', 'subtitle': 'Kuryerga', 'icon': Icons.payments_outlined},
      {'key': 'terminal', 'title': 'Terminal', 'subtitle': 'Karta bilan', 'icon': Icons.point_of_sale_rounded},
    ];

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(18),
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
          const SizedBox(height: 10),

          // Helpful info box (Image 1 style)
          if (_selectedMethod == 'cash')
            Container(
              margin: const EdgeInsets.only(bottom: 12),
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
                      'Naqd pul orqali to\'lov: Iltimos, qaytim uchun yirik pul bo\'lsa kuryerga xabar bering.',
                      style: AppTextStyles.bodyExtraSmall.copyWith(
                        color: AppColors.neutral600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Horizontal Payment Cards (Image 1 style)
          SizedBox(
            height: 74,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: options.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final opt = options[i];
                final isSelected = _selectedMethod == opt['key'];

                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _selectedMethod = opt['key'] as String);
                    context.read<CheckoutCubit>().setPaymentMethod(opt['key'] as String);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 110,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? (isDark ? AppColors.darkSurface : Colors.white)
                          : (isDark ? AppColors.neutral800 : const Color(0xFFF8F9FA)),
                      borderRadius: BorderRadius.circular(14),
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Icon(
                              opt['icon'] as IconData,
                              color: isSelected ? AppColors.primary : AppColors.neutral500,
                              size: 20,
                            ),
                            if (isSelected)
                              const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 16),
                          ],
                        ),
                        Text(
                          opt['title'] as String,
                          style: AppTextStyles.labelSmall.copyWith(
                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                            color: isSelected
                                ? (isDark ? Colors.white : AppColors.neutral900)
                                : AppColors.neutral600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// 📝 Checkout: Kuryer uchun izoh va salfetka sozlamasi
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
  bool _noUtensils = true;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final props = widget.section.properties;
    final title = props['title']?.toString() ?? 'Kuryer uchun izoh';
    final utensilsLabel = props['utensils_label']?.toString() ?? 'Qoshiq va salfetka kerak emas';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.neutral200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.labelSmall.copyWith(color: AppColors.neutral500, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextField(
            decoration: InputDecoration(
              hintText: 'Podyezd, domofon kodi, xonadon...',
              hintStyle: AppTextStyles.bodySmall.copyWith(color: AppColors.neutral400),
              filled: true,
              fillColor: isDark ? AppColors.neutral800 : const Color(0xFFF8F9FA),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(utensilsLabel, style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600)),
              Switch(
                value: _noUtensils,
                activeThumbColor: AppColors.primary,
                onChanged: (v) => setState(() => _noUtensils = v),
              ),
            ],
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
    final title = props['title']?.toString() ?? 'Yakuniy to\'lov';

    return BlocBuilder<CartCubit, CartState>(
      builder: (context, cartState) {
        return BlocBuilder<CheckoutCubit, CheckoutState>(
          builder: (context, checkoutState) {
            final deliveryPrice = checkoutState.isDelivery ? checkoutState.deliveryPrice : 0;
            final total = cartState.subtotal + deliveryPrice;

            return Container(
              margin: const EdgeInsets.fromLTRB(16, 6, 16, 6),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : Colors.white,
                borderRadius: BorderRadius.circular(18),
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
                      Text('Mahsulotlar:', style: AppTextStyles.bodySmall.copyWith(color: AppColors.neutral500)),
                      Text('${NumberFormatter.formatSum(cartState.subtotal)} so\'m', style: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Yetkazib berish:', style: AppTextStyles.bodySmall.copyWith(color: AppColors.neutral500)),
                      Text(
                        deliveryPrice == 0 ? 'Bepul' : '${NumberFormatter.formatSum(deliveryPrice)} so\'m',
                        style: AppTextStyles.labelMedium.copyWith(
                          color: deliveryPrice == 0 ? AppColors.success : null,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider(height: 1)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('To\'lanadigan summa:', style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w800)),
                      Text('${NumberFormatter.formatSum(total)} so\'m', style: AppTextStyles.priceLarge.copyWith(color: AppColors.primary, fontSize: 18)),
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

  @override
  Widget build(BuildContext context) {
    final props = section.properties;
    final btnText = props['button_text']?.toString() ?? 'Buyurtmani tasdiqlash';

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: ElevatedButton(
          onPressed: () {
            HapticFeedback.heavyImpact();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Buyurtmangiz muvaffaqiyatli qabul qilindi!')),
            );
            context.go('/orders');
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 4,
          ),
          child: Text(btnText, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        ),
      ),
    );
  }
}

