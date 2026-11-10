import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pizza_strada/core/sdui/models/section_model.dart';
import 'package:pizza_strada/core/sdui/widgets/components/checkout_components.dart';
import 'package:pizza_strada/core/storage/secure_storage.dart';
import 'package:pizza_strada/core/theme/app_colors.dart';
import 'package:pizza_strada/core/theme/app_text_styles.dart';
import 'package:pizza_strada/core/utils/number_formatter.dart';
import 'package:pizza_strada/features/cart/presentation/bloc/cart_cubit.dart';
import 'package:pizza_strada/features/cart/presentation/bloc/checkout/checkout_cubit.dart';
import 'package:pizza_strada/features/cart/presentation/bloc/checkout/checkout_state.dart';
import 'package:pizza_strada/features/cart/presentation/widgets/checkout_promo_code_widget.dart';

/// 💳 CheckoutPage: Bosqichli (Stepped) Native Checkout
/// Step 1: Yetkazib berish (Manzil / Filial tanlash & Qabul qiluvchi)
/// Step 2: To'lov va tasdiqlash (Mijoz, To'lov turi, Kuryer izohi, Hisob-kitob)
class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  int _currentStep = 0; // 0 = Yetkazib berish, 1 = To'lov va tasdiqlash
  bool _editRecipientInStep1 = false;
  String _cachedProfileName = 'checkout.guest_customer'.tr();
  String _cachedProfilePhone = '+998 -- --- -- --';

  @override
  void initState() {
    super.initState();
    _loadProfileInfo();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<CheckoutCubit>().loadCheckoutOptions();
      }
    });
  }

  Future<void> _loadProfileInfo() async {
    final token = await SecureStorage.getToken();
    if (token == null || token.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('checkout.login_required'.tr()),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        context.go('/auth/login');
        return;
      }
    }

    final name = await SecureStorage.getUserName();
    final phone = await SecureStorage.getUserPhone();
    if (mounted) {
      setState(() {
        if (name != null && name.trim().isNotEmpty) {
          _cachedProfileName = name.trim();
        }
        if (phone != null && phone.trim().isNotEmpty) {
          _cachedProfilePhone = NumberFormatter.formatPhone(phone.trim());
        }
      });
    }
  }

  Future<void> _proceedToStep2(CheckoutState checkoutState, CartState cartState) async {
    HapticFeedback.mediumImpact();

    if (!checkoutState.canOrder) {
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(checkoutState.canOrderMessage ?? 'checkout.ordering_suspended'.tr()),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (cartState.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('cart.empty_error'.tr()),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (checkoutState.isDelivery) {
      if (checkoutState.address == null ||
          checkoutState.address!.trim().isEmpty ||
          checkoutState.lat == null ||
          checkoutState.lng == null) {
        HapticFeedback.heavyImpact();
        context.read<CheckoutCubit>().setLocationError(true);
        return;
      }
    } else {
      if (checkoutState.branchId == null || checkoutState.branchId!.trim().isEmpty) {
        HapticFeedback.heavyImpact();
        context.read<CheckoutCubit>().setLocationError(true);
        return;
      }
    }

    setState(() => _currentStep = 1);
  }

  PreferredSizeWidget _buildStepIndicator(bool isDark) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(54),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
        decoration: BoxDecoration(
          color: Theme.of(context).appBarTheme.backgroundColor,
          border: Border(
            bottom: BorderSide(
              color: isDark ? AppColors.neutral800 : AppColors.neutral200,
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: () {
                if (_currentStep == 1) {
                  HapticFeedback.selectionClick();
                  setState(() => _currentStep = 0);
                }
              },
              child: _StepDot(
                number: 1,
                label: 'checkout.delivery'.tr(),
                isActive: _currentStep == 0,
                isDone: _currentStep > 0,
              ),
            ),
            Expanded(
              child: Container(
                height: 2,
                margin: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: _currentStep > 0
                      ? AppColors.primary
                      : (isDark ? AppColors.neutral700 : AppColors.neutral200),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ),
            _StepDot(
              number: 2,
              label: 'checkout.step2_label'.tr(),
              isActive: _currentStep == 1,
              isDone: false,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep2OrderInfoCard(BuildContext context, CheckoutState state, bool isDark) {
    final isDelivery = state.isDelivery;
    final locationText = isDelivery
        ? (state.address ?? 'checkout.delivery_location'.tr())
        : (state.branchTitle ?? 'checkout.selected_branch'.tr());

    final customName = state.recipientName;
    final customPhone = state.recipientPhone;
    final hasCustom = (customName != null && customName.trim().isNotEmpty) ||
        (customPhone != null && customPhone.trim().isNotEmpty);

    final name = (customName != null && customName.trim().isNotEmpty)
        ? customName.trim()
        : _cachedProfileName;
    final phone = (customPhone != null && customPhone.trim().isNotEmpty)
        ? customPhone.trim()
        : _cachedProfilePhone;

    // Manzil qo'shimcha ma'lumotlari (podyezd, qavat, xonadon, domofon)
    final addressDetails = <String>[];
    if (isDelivery) {
      if (state.entrance != null && state.entrance!.trim().isNotEmpty) {
        addressDetails.add('Podyezd: ${state.entrance!.trim()}');
      }
      if (state.floor != null && state.floor!.trim().isNotEmpty) {
        addressDetails.add('Qavat: ${state.floor!.trim()}');
      }
      if (state.apartment != null && state.apartment!.trim().isNotEmpty) {
        addressDetails.add('Xonadon: ${state.apartment!.trim()}');
      }
      if (state.doorPhone != null && state.doorPhone!.trim().isNotEmpty) {
        addressDetails.add('Domofon: ${state.doorPhone!.trim()}');
      }
    }
    final addressExtra = addressDetails.isNotEmpty ? addressDetails.join(', ') : null;

    final cartState = context.watch<CartCubit>().state;
    final discount = state.calculateDiscount(cartState.subtotal);
    final deliveryPrice = isDelivery ? state.deliveryPrice : 0.0;
    final subtotalAfterDiscount = (cartState.subtotal - discount).clamp(0.0, double.infinity);
    final total = subtotalAfterDiscount + deliveryPrice;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      padding: const EdgeInsets.all(18),
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
          // Sarlavha va "O'zgartirish" tugmasi
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'orders.order_info'.tr(),
                style: AppTextStyles.labelLarge.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: isDark ? Colors.white : AppColors.neutral900,
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  HapticFeedback.selectionClick();
                  setState(() => _currentStep = 0);
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
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 1. Manzil / Filial qatori
          _buildInfoRow(
            label: isDelivery ? 'checkout.address'.tr() : 'orders.branch'.tr(),
            valueWidget: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  locationText,
                  textAlign: TextAlign.end,
                  style: AppTextStyles.labelSmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppColors.neutral900,
                  ),
                ),
                if (addressExtra != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    addressExtra,
                    textAlign: TextAlign.end,
                    style: AppTextStyles.bodyExtraSmall.copyWith(
                      color: AppColors.neutral500,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Divider(height: 20),

          // 2. Qabul qiluvchi qatori
          _buildInfoRow(
            label: 'checkout.recipient'.tr(),
            valueWidget: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (hasCustom) ...[
                  Container(
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Boshqa shaxs',
                      style: AppTextStyles.bodyExtraSmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 9.5,
                      ),
                    ),
                  ),
                ],
                Text(
                  name,
                  textAlign: TextAlign.end,
                  style: AppTextStyles.labelSmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppColors.neutral900,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 20),

          // 3. Telefon raqami qatori
          _buildInfoRow(
            label: 'checkout.recipient_phone'.tr(),
            valueWidget: Text(
              phone,
              textAlign: TextAlign.end,
              style: AppTextStyles.labelSmall.copyWith(
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : AppColors.neutral900,
              ),
            ),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1),
          ),

          // 4. Mahsulotlar summasi
          _buildInfoRow(
            label: '${'cart.subtotal'.tr()}:',
            valueWidget: Text(
              '${NumberFormatter.formatSum(cartState.subtotal)} ${'common.currency'.tr()}',
              textAlign: TextAlign.end,
              style: AppTextStyles.labelSmall.copyWith(
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : AppColors.neutral900,
              ),
            ),
          ),

          // 5. Promokod chegirmasi (agar bo'lsa)
          if (discount > 0) ...[
            const SizedBox(height: 8),
            _buildInfoRow(
              label: state.isPercentagePromo
                  ? '${'checkout.promo_discount'.tr()} (${state.appliedPromoCode} • ${state.promoValue?.toInt()}%):'
                  : '${'checkout.promo_discount'.tr()} (${state.appliedPromoCode}):',
              valueWidget: Text(
                '-${NumberFormatter.formatSum(discount)} ${'common.currency'.tr()}',
                textAlign: TextAlign.end,
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.success,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],

          const SizedBox(height: 8),
          // 6. Yetkazib berish narxi
          _buildInfoRow(
            label: '${'cart.delivery'.tr()}:',
            valueWidget: Text(
              !isDelivery || deliveryPrice == 0
                  ? 'checkout.free'.tr()
                  : '${NumberFormatter.formatSum(deliveryPrice)} ${'common.currency'.tr()}',
              textAlign: TextAlign.end,
              style: AppTextStyles.labelSmall.copyWith(
                color: (!isDelivery || deliveryPrice == 0)
                    ? AppColors.success
                    : (isDark ? Colors.white : AppColors.neutral900),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1),
          ),

          // 7. Jami to'lov
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${'cart.total'.tr()}:',
                style: AppTextStyles.labelLarge.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  color: isDark ? Colors.white : AppColors.neutral900,
                ),
              ),
              Text(
                '${NumberFormatter.formatSum(total)} ${'common.currency'.tr()}',
                style: AppTextStyles.priceLarge.copyWith(
                  color: AppColors.primary,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required String label,
    required Widget valueWidget,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.neutral500,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Align(
            alignment: Alignment.centerRight,
            child: valueWidget,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocBuilder<CheckoutCubit, CheckoutState>(
      builder: (context, checkoutState) {
        return BlocBuilder<CartCubit, CartState>(
          builder: (context, cartState) {
            return Scaffold(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              appBar: AppBar(
                title: Text(
                  'checkout.title'.tr(),
                  style: AppTextStyles.h2.copyWith(
                    color: Theme.of(context).textTheme.headlineMedium?.color,
                  ),
                ),
                backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
                elevation: 0,
                centerTitle: true,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                  onPressed: () {
                    if (_currentStep == 1) {
                      HapticFeedback.selectionClick();
                      setState(() => _currentStep = 0);
                    } else {
                      context.pop();
                    }
                  },
                ),
                bottom: _buildStepIndicator(isDark),
              ),
              body: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: _currentStep == 0
                    ? _buildStep1(context, checkoutState, isDark)
                    : _buildStep2(context, checkoutState, isDark),
              ),
              bottomNavigationBar: _currentStep == 0
                  ? Container(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        border: Border(
                          top: BorderSide(
                            color: isDark ? AppColors.neutral800 : AppColors.neutral200,
                            width: 1,
                          ),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, -4),
                          ),
                        ],
                      ),
                      child: SafeArea(
                        top: false,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (!checkoutState.canOrder) ...[
                              Container(
                                width: double.infinity,
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF3E2D12) : const Color(0xFFFEF3C7),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isDark ? const Color(0xFF78350F) : const Color(0xFFFDE68A),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.info_outline_rounded,
                                      color: isDark ? const Color(0xFFFBBF24) : const Color(0xFFB45309),
                                      size: 20,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        checkoutState.canOrderMessage ?? 'checkout.ordering_suspended'.tr(),
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w600,
                                          color: isDark ? const Color(0xFFFDE68A) : const Color(0xFF92400E),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            SizedBox(
                              width: double.infinity,
                              height: 54,
                              child: ElevatedButton(
                                onPressed: !checkoutState.canOrder
                                    ? null
                                    : () => _proceedToStep2(checkoutState, cartState),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: checkoutState.canOrder
                                      ? AppColors.primary
                                      : (isDark ? AppColors.neutral800 : AppColors.neutral300),
                                  disabledBackgroundColor: isDark ? AppColors.neutral800 : AppColors.neutral300,
                                  foregroundColor: Colors.white,
                                  disabledForegroundColor: isDark ? AppColors.neutral500 : AppColors.neutral500,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  elevation: 0,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      checkoutState.canOrder
                                          ? 'checkout.next'.tr()
                                          : '${'checkout.next'.tr()} (${'checkout.inactive'.tr()})',
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                                    ),
                                    const SizedBox(width: 8),
                                    const Icon(Icons.arrow_forward_rounded, size: 20),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : null,
            );
          },
        );
      },
    );
  }

  Widget _buildStep1(BuildContext context, CheckoutState checkoutState, bool isDark) {
    const dummySection = SDUISectionModel(id: 'step1', type: 'step1');

    return ListView(
      key: const ValueKey('checkout_step_0'),
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 100),
      children: [
        SDUIOrderTypeComponent(section: dummySection, onAction: (_) {}),
        if (checkoutState.isDelivery)
          SDUIAddressSelectorComponent(section: dummySection, onAction: (_) {})
        else
          SDUIPickupBranchComponent(section: dummySection, onAction: (_) {}),
        SDUICustomerInfoComponent(
          section: dummySection,
          onAction: (_) {},
          initiallyEditing: _editRecipientInStep1,
          onEditingComplete: () {
            if (_editRecipientInStep1) {
              setState(() => _editRecipientInStep1 = false);
            }
          },
        ),
      ],
    );
  }

  Widget _buildStep2(BuildContext context, CheckoutState checkoutState, bool isDark) {
    const dummySection = SDUISectionModel(id: 'step2', type: 'step2');

    return ListView(
      key: const ValueKey('checkout_step_1'),
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 30),
      children: [
        _buildStep2OrderInfoCard(context, checkoutState, isDark),
        const CheckoutPromoCodeWidget(),
        SDUIPaymentMethodComponent(section: dummySection, onAction: (_) {}),
        SDUICourierNotesComponent(section: dummySection, onAction: (_) {}),
        SDUISubmitOrderCtaComponent(section: dummySection, onAction: (_) {}),
      ],
    );
  }
}

class _StepDot extends StatelessWidget {
  final int number;
  final String label;
  final bool isActive;
  final bool isDone;

  const _StepDot({
    required this.number,
    required this.label,
    required this.isActive,
    required this.isDone,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = (isActive || isDone) ? AppColors.primary : AppColors.neutral400;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: isDone
                ? AppColors.primary
                : (isActive
                    ? AppColors.primary.withValues(alpha: isDark ? 0.25 : 0.12)
                    : Colors.transparent),
            shape: BoxShape.circle,
            border: Border.all(
              color: color,
              width: 1.8,
            ),
          ),
          alignment: Alignment.center,
          child: isDone
              ? const Icon(Icons.check_rounded, color: Colors.white, size: 14)
              : Text(
                  '$number',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
            color: isActive
                ? (isDark ? Colors.white : AppColors.neutral900)
                : AppColors.neutral500,
          ),
        ),
      ],
    );
  }
}
