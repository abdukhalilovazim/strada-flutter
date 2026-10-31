import 'dart:async';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pizza_strada/core/di/injection.dart';
import 'package:pizza_strada/core/network/api_client.dart';
import 'package:pizza_strada/core/services/analytics_service.dart';
import 'package:pizza_strada/core/storage/secure_storage.dart';
import 'package:pizza_strada/core/theme/app_colors.dart';
import 'package:pizza_strada/core/theme/app_text_styles.dart';
import 'package:pizza_strada/core/utils/number_formatter.dart';
import 'package:pizza_strada/core/utils/phone_number_formatter.dart';
import 'package:pizza_strada/core/widgets/app_text_field.dart';
import 'package:pizza_strada/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:pizza_strada/features/cart/presentation/bloc/cart_cubit.dart';
import 'package:pizza_strada/features/cart/presentation/bloc/checkout/checkout_cubit.dart';
import 'package:pizza_strada/features/cart/presentation/bloc/checkout/checkout_state.dart';
import 'package:pizza_strada/features/cart/presentation/widgets/checkout_otp_sheet.dart';
import 'package:pizza_strada/features/cart/presentation/widgets/order_confirmation_sheet.dart';
import 'package:pizza_strada/features/cart/presentation/widgets/order_type_bottom_sheet.dart';
import 'package:pizza_strada/features/home/domain/entities/home_entities.dart';
import 'package:pizza_strada/features/home/presentation/bloc/home_cubit.dart';
import 'package:pizza_strada/features/orders/data/models/order_model.dart';
import 'package:pizza_strada/features/orders/domain/entities/order_entity.dart';
import 'package:url_launcher/url_launcher.dart';

/// Yagona va tezkor Buyurtma Rasmiylashtirish (Single-Step Checkout) sahifasi.
///
/// Home pageda tanlangan Yetkazib berish / Olib ketish va Manzil/Filial
/// to'g'ridan-to'g'ri integratsiya qilingan. Delivery bo'lsa delivery narxi
/// hisoblanadi va ko'rsatiladi; pickup bo'lsa delivery satr umuman ko'rinmaydi.
class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  List<CheckoutBranch> _branches = [];

  final _commentController = TextEditingController();
  final _promoController = TextEditingController();
  final _changeController = TextEditingController();
  final _guestNameController = TextEditingController();
  final _guestPhoneController = TextEditingController();

  bool _showPromoInput = false;
  bool _showChangeInput = false;
  bool _showCommentInput = false;
  bool _isLoggedIn = false;
  String? _userName;
  String? _userPhone;
  bool _isTelegramChecking = false;
  Timer? _telegramPollTimer;

  @override
  void initState() {
    super.initState();
    _loadBranches();
    _loadUserData();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final state = context.read<CheckoutCubit>().state;

      // Agar Home pageda manzil tanlangan bo'lsa-yu, narx hisoblanmagan bo'lsa qayta hisoblash
      if (state.isDelivery &&
          state.lat != null &&
          state.lng != null &&
          state.deliveryPrice == 0) {
        context.read<CheckoutCubit>().setAddressAndCalculateDelivery(
              state.lat!,
              state.lng!,
              state.address ?? '',
            );
      }

      if (state.comment.isNotEmpty) {
        setState(() {
          _showCommentInput = true;
          _commentController.text = state.comment;
        });
      }
      if (state.appliedPromoCode != null) {
        setState(() {
          _showPromoInput = true;
          _promoController.text = state.appliedPromoCode!;
        });
      }
      if (state.changeAmount != null && state.changeAmount! > 0) {
        setState(() {
          _showChangeInput = true;
          _changeController.text = state.changeAmount!.toInt().toString();
        });
      }
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    _promoController.dispose();
    _changeController.dispose();
    _guestNameController.dispose();
    _guestPhoneController.dispose();
    _telegramPollTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadBranches() async {
    try {
      final response = await ApiClient().get('branches');
      if (response is List && mounted) {
        final list = response
            .map((e) => CheckoutBranch.fromJson(e as Map<String, dynamic>))
            .toList();

        setState(() {
          _branches = list;
          final cubit = context.read<CheckoutCubit>();
          final currentBranchId = cubit.state.branchId;

          if (_branches.isNotEmpty) {
            if (currentBranchId == null) {
              cubit.setBranch(_branches.first.id, branchTitle: _branches.first.title);
            } else if (cubit.state.branchTitle == null) {
              final match = _branches.where((b) => b.id == currentBranchId).firstOrNull;
              if (match != null) {
                cubit.setBranch(match.id, branchTitle: match.title);
              }
            }
          }
        });
      }
    } catch (_) {
    }
  }

  Future<void> _loadUserData() async {
    final token = await SecureStorage.getToken();
    final name = await SecureStorage.getUserName();
    final phone = await SecureStorage.getUserPhone();
    if (mounted) {
      setState(() {
        _isLoggedIn = token != null && token.isNotEmpty && phone != null && phone.isNotEmpty;
        _userName = name;
        _userPhone = phone;
      });
    }
  }

  int _getPaymentMethodId(String key) {
    final k = key.toLowerCase().trim();
    if (k == 'payme' || k == '1') return 1;
    if (k == 'click' || k == '2') return 2;
    return 0;
  }

  String _getPaymentMethodTitle(CheckoutState state, List<PaymentMethodEntity> methods) {
    final match = methods.where((m) => m.key == state.selectedPaymentMethodKey).firstOrNull;
    if (match != null) return match.value;
    final id = _getPaymentMethodId(state.selectedPaymentMethodKey);
    if (id == 1) return 'Payme';
    if (id == 2) return 'Click';
    return 'checkout.cash_payment'.tr();
  }

  double _computeDiscount(CheckoutState state, double subtotal) {
    if (state.appliedPromoCode == null) return 0;
    double discount = 0;
    if (state.promoValue != null) {
      if (state.promoType == 1) {
        discount += subtotal * state.promoValue! / 100;
      } else {
        discount += state.promoValue!;
      }
    }
    return discount;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final homeState = context.watch<HomeCubit>().state;
    List<PaymentMethodEntity> paymentMethods = [];
    if (homeState is HomeLoaded) {
      paymentMethods = homeState.settings?.paymentMethods ?? [];
    }

    return BlocConsumer<CheckoutCubit, CheckoutState>(
      listener: (context, state) {
        if (state.submitError != null) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(state.submitError!),
            backgroundColor: AppColors.error,
          ));
          context.read<CheckoutCubit>().clearSubmitError();
        } else if (state.successData != null) {
          _handleSuccess(state.successData!);
        }
      },
      builder: (context, checkoutState) {
        final cartState = context.watch<CartCubit>().state;
        final subtotal = cartState.subtotal;
        final discount = _computeDiscount(checkoutState, subtotal);

        // Pickup bo'lsa delivery narxi 0, total faqat subtotal - discount
        final deliveryFee = checkoutState.isDelivery ? checkoutState.deliveryPrice : 0.0;
        final finalTotal = (subtotal + deliveryFee - discount).clamp(0.0, double.infinity);

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            title: Text(
              'checkout.title'.tr(),
              style: AppTextStyles.h2.copyWith(
                color: Theme.of(context).textTheme.headlineMedium?.color,
              ),
            ),
            centerTitle: true,
            backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(
                height: 1,
                color: isDark ? AppColors.neutral800 : AppColors.neutral200,
              ),
            ),
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: isDark ? Colors.white : AppColors.neutral900,
              ),
              onPressed: () => context.pop(),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── 1. Yetkazib berish usuli va Manzil / Filial ──
                _buildSectionHeader(
                  context,
                  icon: Icons.delivery_dining_rounded,
                  title: 'checkout.delivery_type'.tr(),
                  isDark: isDark,
                ),
                const SizedBox(height: 10),
                _buildDeliverySelectionCard(context, checkoutState, isDark),

                const SizedBox(height: 20),

                // ── 2. Qabul qiluvchi ma'lumotlari (faqat login qilmagan mehmonlar uchun) ──
                if (!_isLoggedIn) ...[
                  _buildSectionHeader(
                    context,
                    icon: Icons.person_rounded,
                    title: 'checkout.recipient'.tr(),
                    isDark: isDark,
                  ),
                  const SizedBox(height: 10),
                  _buildRecipientCard(context, isDark),
                  const SizedBox(height: 20),
                ],

                const SizedBox(height: 20),

                // ── 3. To'lov usuli ──
                _buildSectionHeader(
                  context,
                  icon: Icons.payment_rounded,
                  title: 'checkout.payment'.tr(),
                  isDark: isDark,
                ),
                const SizedBox(height: 10),
                _buildPaymentMethodSection(context, checkoutState, paymentMethods, isDark),

                const SizedBox(height: 20),

                // ── 4. Qo'shimcha (Promo kod, Qaytim, Izoh) ──
                _buildSectionHeader(
                  context,
                  icon: Icons.tune_rounded,
                  title: 'checkout.additional'.tr(),
                  isDark: isDark,
                ),
                const SizedBox(height: 10),
                _buildAdditionalSection(context, checkoutState, subtotal, isDark),

                const SizedBox(height: 20),

                // ── 5. Buyurtma hisobi (Narxlar breakdown) ──
                _buildSectionHeader(
                  context,
                  icon: Icons.receipt_long_rounded,
                  title: 'checkout.order_summary'.tr(),
                  isDark: isDark,
                ),
                const SizedBox(height: 10),
                _buildPriceSummaryCard(
                  context,
                  checkoutState: checkoutState,
                  subtotal: subtotal,
                  deliveryFee: deliveryFee,
                  discount: discount,
                  finalTotal: finalTotal,
                  isDark: isDark,
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
          bottomNavigationBar: _buildBottomBar(
            context,
            checkoutState: checkoutState,
            cartState: cartState,
            paymentMethods: paymentMethods,
            subtotal: subtotal,
            deliveryFee: deliveryFee,
            discount: discount,
            finalTotal: finalTotal,
            isDark: isDark,
          ),
        );
      },
    );
  }

  /// Bo'lim sarlavhasi
  Widget _buildSectionHeader(
    BuildContext context, {
    required IconData icon,
    required String title,
    required bool isDark,
  }) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.primary, size: 18),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: AppTextStyles.h3.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.headlineMedium?.color,
          ),
        ),
      ],
    );
  }

  void _openOrderTypeBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const OrderTypeBottomSheet(),
    );
  }

  /// Yetkazib berish usuli va Manzil / Filial tanlangan ixcham kartochkasi.
  /// Bosilganda OrderTypeBottomSheet ochiladi.
  Widget _buildDeliverySelectionCard(
    BuildContext context,
    CheckoutState checkoutState,
    bool isDark,
  ) {
    final isDelivery = checkoutState.isDelivery;
    final hasAddress = checkoutState.address != null && checkoutState.address!.isNotEmpty;
    final hasBranch = checkoutState.branchTitle != null && checkoutState.branchTitle!.isNotEmpty;

    final String title = isDelivery
        ? 'checkout.delivery'.tr()
        : 'checkout.pickup'.tr();

    final String subtitle = isDelivery
        ? (hasAddress ? checkoutState.address! : 'checkout.select_address'.tr())
        : (hasBranch ? checkoutState.branchTitle! : 'checkout.select_branch'.tr());

    final IconData icon = isDelivery
        ? Icons.delivery_dining_rounded
        : Icons.storefront_rounded;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openOrderTypeBottomSheet(context),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: (isDelivery ? hasAddress : hasBranch)
                  ? (isDark ? AppColors.neutral800 : AppColors.neutral200)
                  : AppColors.primary,
              width: (isDelivery ? hasAddress : hasBranch) ? 1 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.primary, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            title,
                            style: AppTextStyles.bodyExtraSmall.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (isDelivery && checkoutState.deliveryPrice > 0) ...[
                          const SizedBox(width: 8),
                          Text(
                            '${NumberFormatter.formatSum(checkoutState.deliveryPrice.toInt())} ${'common.currency'.tr()}',
                            style: AppTextStyles.bodyExtraSmall.copyWith(
                              color: isDark ? AppColors.neutral300 : AppColors.neutral700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: AppTextStyles.labelMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        color: (isDelivery ? hasAddress : hasBranch)
                            ? Theme.of(context).textTheme.bodyLarge?.color
                            : AppColors.primary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.neutral800 : AppColors.neutral100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'common.change'.tr(),
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 2),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 11,
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Qabul qiluvchi shaxs ma'lumotlari (Ism + Raqam yoki Mehmon formasi)
  Widget _buildRecipientCard(BuildContext context, bool isDark) {
    final bool isGuest = _userPhone == null || _userPhone!.isEmpty;

    if (!isGuest) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? AppColors.neutral800 : AppColors.neutral200,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.person_rounded,
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
                    _userName != null && _userName!.isNotEmpty ? _userName! : 'profile.guest'.tr(),
                    style: AppTextStyles.labelMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  if (_userPhone != null && _userPhone!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      PhoneNumberFormatter.format(_userPhone!),
                      style: AppTextStyles.bodySmall.copyWith(
                        color: isDark ? AppColors.neutral400 : AppColors.neutral600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Mehmon foydalanuvchi uchun forma
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.neutral800 : AppColors.neutral200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.person_outline_rounded,
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
                      'checkout.guest_contact_title'.tr(),
                      style: AppTextStyles.labelMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                    Text(
                      'checkout.guest_contact_desc'.tr(),
                      style: AppTextStyles.bodySmall.copyWith(
                        color: isDark ? AppColors.neutral400 : AppColors.neutral600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          AppTextField(
            controller: _guestNameController,
            hintText: 'auth.name_hint'.tr(),
            prefixIcon: Icons.person_outline_rounded,
          ),
          const SizedBox(height: 10),
          AppTextField(
            controller: _guestPhoneController,
            hintText: '90 123 45 67',
            prefixText: '+998 ',
            keyboardType: TextInputType.phone,
            prefixIcon: Icons.phone_outlined,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(9),
            ],
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: _isTelegramChecking ? null : _startTelegramAuth,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF0088CC).withValues(alpha: isDark ? 0.15 : 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF0088CC).withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_isTelegramChecking)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF0088CC),
                      ),
                    )
                  else
                    const Icon(
                      Icons.telegram_rounded,
                      color: Color(0xFF0088CC),
                      size: 20,
                    ),
                  const SizedBox(width: 8),
                  Text(
                    _isTelegramChecking
                        ? 'checkout.waiting_telegram_auth'.tr()
                        : 'checkout.login_with_telegram'.tr(),
                    style: AppTextStyles.labelMedium.copyWith(
                      color: const Color(0xFF0088CC),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// To'lov usullari (Payme, Click, Naqd pul)
  Widget _buildPaymentMethodSection(
    BuildContext context,
    CheckoutState checkoutState,
    List<PaymentMethodEntity> paymentMethods,
    bool isDark,
  ) {
    // Agar serverdan kelmagan bo'lsa default 3 ta usul
    final methods = paymentMethods.isNotEmpty
        ? paymentMethods
        : [
            const PaymentMethodEntity(key: '1', value: 'Payme'),
            const PaymentMethodEntity(key: '2', value: 'Click'),
            PaymentMethodEntity(key: '0', value: 'checkout.cash_payment'.tr()),
          ];

    return Column(
      children: [
        Row(
          children: methods.take(3).map((method) {
            final isSelected = checkoutState.selectedPaymentMethodKey == method.key;
            final methodId = _getPaymentMethodId(method.key);

            IconData methodIcon = Icons.payments_outlined;
            if (methodId == 1) {
              methodIcon = Icons.account_balance_wallet_outlined;
            } else if (methodId == 2) {
              methodIcon = Icons.credit_card_outlined;
            }

            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: InkWell(
                  onTap: () {
                    context.read<CheckoutCubit>().setPaymentMethod(method.key);
                    if (method.key != '0' && method.key != 'cash') {
                      setState(() {
                        _showChangeInput = false;
                        _changeController.clear();
                      });
                      context.read<CheckoutCubit>().setChangeAmount(null);
                    }
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? (isDark
                              ? AppColors.primary.withValues(alpha: 0.15)
                              : AppColors.primary.withValues(alpha: 0.08))
                          : (isDark ? AppColors.darkSurface : Colors.white),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : (isDark ? AppColors.neutral800 : AppColors.neutral200),
                        width: isSelected ? 1.5 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isSelected
                              ? AppColors.primary.withValues(alpha: 0.15)
                              : Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                          blurRadius: isSelected ? 6 : 3,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          methodIcon,
                          color: isSelected ? AppColors.primary : AppColors.neutral500,
                          size: 22,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          method.value,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.labelSmall.copyWith(
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected
                                ? AppColors.primary
                                : Theme.of(context).textTheme.bodyMedium?.color,
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

        // Naqd pul tanlansa — qaytim summasi kiritish
        if (checkoutState.selectedPaymentMethodKey == '0' ||
            checkoutState.selectedPaymentMethodKey == 'cash') ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark ? AppColors.neutral800 : AppColors.neutral200,
              ),
            ),
            child: Column(
              children: [
                _SwitchRow(
                  icon: Icons.payments_outlined,
                  label: 'checkout.change_from'.tr(),
                  value: _showChangeInput,
                  onChanged: (val) {
                    setState(() => _showChangeInput = val);
                    if (!val) {
                      _changeController.clear();
                      context.read<CheckoutCubit>().setChangeAmount(null);
                    }
                  },
                ),
                if (_showChangeInput) ...[
                  const SizedBox(height: 8),
                  TextField(
                    controller: _changeController,
                    keyboardType: TextInputType.number,
                    onChanged: (val) =>
                        context.read<CheckoutCubit>().setChangeAmount(double.tryParse(val)),
                    decoration: InputDecoration(
                      hintText: 'checkout.enter_amount'.tr(),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: isDark ? AppColors.neutral800 : AppColors.neutral300,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: isDark ? AppColors.neutral800 : AppColors.neutral300,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }

  /// Qo'shimcha ma'lumotlar (Promokod va Izoh)
  Widget _buildAdditionalSection(
    BuildContext context,
    CheckoutState checkoutState,
    double subtotal,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.neutral800 : AppColors.neutral200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Promo kod
          _SwitchRow(
            icon: Icons.local_offer_outlined,
            label: 'cart.promo'.tr(),
            value: _showPromoInput,
            onChanged: (val) {
              setState(() => _showPromoInput = val);
              if (!val) {
                _promoController.clear();
                context.read<CheckoutCubit>().clearPromo();
              }
            },
          ),
          if (_showPromoInput) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _promoController,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      hintText: 'cart.enter_promo'.tr(),
                      errorText: checkoutState.promoError,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: isDark ? AppColors.neutral800 : AppColors.neutral300,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: isDark ? AppColors.neutral800 : AppColors.neutral300,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (checkoutState.loadingPromo)
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                  )
                else
                  ElevatedButton(
                    onPressed: () {
                      context
                          .read<CheckoutCubit>()
                          .applyPromo(_promoController.text.trim().toUpperCase(), subtotal);
                      FocusScope.of(context).unfocus();
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('cart.apply'.tr()),
                  ),
              ],
            ),
            const SizedBox(height: 8),
          ],

          const Divider(height: 16),

          // Izoh
          _SwitchRow(
            icon: Icons.chat_bubble_outline_rounded,
            label: 'checkout.comment'.tr(),
            value: _showCommentInput,
            onChanged: (val) {
              setState(() => _showCommentInput = val);
              if (!val) {
                _commentController.clear();
                context.read<CheckoutCubit>().setComment('');
              }
            },
          ),
          if (_showCommentInput) ...[
            const SizedBox(height: 8),
            TextField(
              controller: _commentController,
              maxLines: 2,
              onChanged: (val) => context.read<CheckoutCubit>().setComment(val),
              decoration: InputDecoration(
                hintText: 'checkout.comment_hint'.tr(),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: isDark ? AppColors.neutral800 : AppColors.neutral300,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: isDark ? AppColors.neutral800 : AppColors.neutral300,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 6),
          ],
        ],
      ),
    );
  }

  /// Narxlar hisob-kitobi (Subtotal, Delivery [faqat delivery bo'lsa], Discount, Total)
  Widget _buildPriceSummaryCard(
    BuildContext context, {
    required CheckoutState checkoutState,
    required double subtotal,
    required double deliveryFee,
    required double discount,
    required double finalTotal,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.neutral800 : AppColors.neutral200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Mahsulotlar narxi
          _PriceLine(
            label: 'cart.subtotal'.tr(),
            valueText: '${NumberFormatter.formatSum(subtotal.toInt())} ${'common.currency'.tr()}',
            isDark: isDark,
          ),

          // ── Delivery narxi faqat DELIVERY rejimida ko'rsatiladi ──
          if (checkoutState.isDelivery) ...[
            const Divider(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'cart.delivery'.tr(),
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: isDark ? AppColors.neutral400 : AppColors.neutral500,
                  ),
                ),
                if (checkoutState.loadingDelivery)
                  Row(
                    children: [
                      const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.8,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'checkout.calculating'.tr(),
                        style: AppTextStyles.bodySmall.copyWith(
                          color: isDark ? AppColors.neutral400 : AppColors.neutral500,
                        ),
                      ),
                    ],
                  )
                else if (checkoutState.address == null || checkoutState.address!.isEmpty)
                  Text(
                    'checkout.on_address_select'.tr(),
                    style: AppTextStyles.bodySmall.copyWith(
                      color: isDark ? AppColors.neutral400 : AppColors.neutral500,
                      fontStyle: FontStyle.italic,
                    ),
                  )
                else
                  Text(
                    '${NumberFormatter.formatSum(deliveryFee.toInt())} ${'common.currency'.tr()}',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: isDark
                          ? Colors.white
                          : Theme.of(context).textTheme.bodyMedium?.color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ],

          // Chegirma (promo kod bo'lsa)
          if (discount > 0) ...[
            const Divider(height: 18),
            _PriceLine(
              label: 'cart.discount'.tr(),
              valueText: '- ${NumberFormatter.formatSum(discount.toInt())} ${'common.currency'.tr()}',
              isNegative: true,
              isDark: isDark,
            ),
          ],

          const Divider(height: 18),

          // JAMI
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'cart.total'.tr(),
                style: AppTextStyles.labelLarge.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              Text(
                '${NumberFormatter.formatSum(finalTotal.toInt())} ${'common.currency'.tr()}',
                style: AppTextStyles.h3.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Pastki rasmiylashtirish paneli
  Widget _buildBottomBar(
    BuildContext context, {
    required CheckoutState checkoutState,
    required CartState cartState,
    required List<PaymentMethodEntity> paymentMethods,
    required double subtotal,
    required double deliveryFee,
    required double discount,
    required double finalTotal,
    required bool isDark,
  }) {
    final bool needsAddress = checkoutState.isDelivery &&
        (checkoutState.address == null || checkoutState.address!.isEmpty);

    final bool needsBranch = !checkoutState.isDelivery && checkoutState.branchId == null;

    final bool canSubmit = !needsAddress &&
        !needsBranch &&
        !checkoutState.isSubmitting &&
        !checkoutState.loadingDelivery &&
        cartState.items.isNotEmpty;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.neutral800 : AppColors.neutral200,
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Narx ko'rsatkichi (total breakdown mini)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'cart.total'.tr(),
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: isDark ? AppColors.neutral400 : AppColors.neutral600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (checkoutState.isDelivery && checkoutState.loadingDelivery)
                    Row(
                      children: [
                        const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.5,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'checkout.calculating'.tr(),
                          style: AppTextStyles.bodySmall.copyWith(
                            color: isDark ? AppColors.neutral400 : AppColors.neutral500,
                          ),
                        ),
                      ],
                    )
                  else
                    Text(
                      '${NumberFormatter.formatSum(finalTotal.toInt())} ${'common.currency'.tr()}',
                      style: AppTextStyles.labelLarge.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                ],
              ),
            ),

            // Buyurtma berish tugmasi
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: (needsAddress || needsBranch)
                    ? () => _openOrderTypeBottomSheet(context)
                    : (canSubmit
                        ? () => _submitOrder(
                              checkoutState: checkoutState,
                              cartState: cartState,
                              paymentMethods: paymentMethods,
                              subtotal: subtotal,
                              deliveryFee: deliveryFee,
                              discount: discount,
                              finalTotal: finalTotal,
                            )
                        : null),
                style: ElevatedButton.styleFrom(
                  backgroundColor: (needsAddress || needsBranch)
                      ? AppColors.secondary
                      : AppColors.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor:
                      isDark ? AppColors.neutral700 : AppColors.neutral300,
                  disabledForegroundColor:
                      isDark ? AppColors.neutral500 : AppColors.neutral400,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: checkoutState.isSubmitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            (needsAddress || needsBranch)
                                ? Icons.location_on_rounded
                                : Icons.check_circle_outline_rounded,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            needsAddress
                                ? 'checkout.select_address'.tr()
                                : (needsBranch
                                    ? 'checkout.select_branch'.tr()
                                    : '${'checkout.submit_order'.tr()} • ${NumberFormatter.formatSum(finalTotal.toInt())} ${'common.currency'.tr()}'),
                            style: AppTextStyles.labelLarge.copyWith(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _startTelegramAuth() async {
    setState(() => _isTelegramChecking = true);
    try {
      final authDs = getIt<AuthRemoteDataSource>();
      final startRes = await authDs.telegramStart();
      final ticket = startRes['ticket']?.toString();
      final botUrl = startRes['bot_url']?.toString();

      if (ticket == null || botUrl == null) {
        throw Exception('Failed to start Telegram login');
      }

      final uri = Uri.parse(botUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }

      // Poll for 90 seconds
      int attempts = 0;
      _telegramPollTimer?.cancel();
      _telegramPollTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
        attempts++;
        if (attempts > 45 || !mounted) {
          timer.cancel();
          if (mounted) setState(() => _isTelegramChecking = false);
          return;
        }

        try {
          final checkRes = await authDs.telegramCheck(ticket: ticket);
          if (checkRes['status'] == 'confirmed' && checkRes['token'] != null) {
            timer.cancel();
            final token = checkRes['token'].toString();
            final userMap = checkRes['user'] as Map<String, dynamic>?;
            final fullName = userMap?['full_name']?.toString() ?? '';
            final phone = userMap?['phone']?.toString() ?? '';

            await SecureStorage.saveToken(token);
            await SecureStorage.saveUserInfo(name: fullName, phone: phone);

            if (mounted) {
              await _loadUserData();
              if (!mounted) return;
              setState(() {
                _isTelegramChecking = false;
              });
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('checkout.auth_success'.tr()),
                backgroundColor: AppColors.success,
              ));
            }
          }
        } catch (_) {}
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isTelegramChecking = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('auth.login_error'.tr()),
          backgroundColor: AppColors.error,
        ));
      }
    }
  }

  Future<void> _submitOrder({
    required CheckoutState checkoutState,
    required CartState cartState,
    required List<PaymentMethodEntity> paymentMethods,
    required double subtotal,
    required double deliveryFee,
    required double discount,
    required double finalTotal,
  }) async {
    // 1. Manzil / Filial tekshiruvi
    if (checkoutState.isDelivery && (checkoutState.address == null || checkoutState.address!.isEmpty)) {
      _openOrderTypeBottomSheet(context);
      return;
    }
    if (!checkoutState.isDelivery && checkoutState.branchId == null) {
      _openOrderTypeBottomSheet(context);
      return;
    }

    // 2. Agar hali login qilinmagan bo'lsa (mehmon)
    if (!_isLoggedIn) {
      final name = _guestNameController.text.trim();
      final phoneDigits = _guestPhoneController.text.trim();

      if (name.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('checkout.enter_name_error'.tr()),
          backgroundColor: AppColors.error,
        ));
        return;
      }
      if (phoneDigits.length != 9) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('checkout.enter_phone_error'.tr()),
          backgroundColor: AppColors.error,
        ));
        return;
      }

      final fullPhone = '+998$phoneDigits';

      try {
        final authDs = getIt<AuthRemoteDataSource>();
        final res = await authDs.loginWithChannel(
          fullName: name,
          phone: fullPhone,
        );

        final channel = res['channel']?.toString() ?? 'sms';

        if (!mounted) return;
        final verified = await CheckoutOtpSheet.show(
          context,
          phone: fullPhone,
          fullName: name,
          initialChannel: channel,
        );

        if (verified != true) return;

        // OTP tasdiqlangach login saqlanib qoladi
        await _loadUserData();
        if (!mounted) return;
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e is ApiException ? e.message : 'auth.login_error'.tr()),
          backgroundColor: AppColors.error,
        ));
        return;
      }
    }

    if (!mounted) return;

    // 3. Hammasini bitta ko'rsatib buyurtmani tasdiqlash
    final paymentMethodName = _getPaymentMethodTitle(checkoutState, paymentMethods);

    OrderConfirmationSheet.show(
      context,
      checkoutState: checkoutState,
      cartState: cartState,
      userName: _userName ?? '',
      userPhone: _userPhone ?? '',
      paymentMethodName: paymentMethodName,
      subtotal: subtotal,
      deliveryFee: deliveryFee,
      discount: discount,
      finalTotal: finalTotal,
      onConfirm: () => _executeSubmitOrder(context, cartState),
    );
  }

  void _executeSubmitOrder(BuildContext context, CartState cartState) {
    final products = cartState.items.map((item) {
      final variantId = item.variant?.id ?? item.product.variants.firstOrNull?.id ?? 0;
      return {
        'id': variantId,
        'variant_id': variantId,
        'quantity': item.quantity,
      };
    }).toList();

    context.read<CheckoutCubit>().submitOrder(products: products);
  }

  void _handleSuccess(Map<String, dynamic> data) async {
    final orderId = data['order_id']?.toString() ?? data['id']?.toString() ?? '';
    final totalAmount = double.tryParse(data['total_price']?.toString() ?? '') ?? 0;
    final paymentMethod = data['payment_method_text']?.toString() ?? 'unknown';

    AnalyticsService.instance.logOrderPlaced(
      orderId: orderId,
      totalAmount: totalAmount,
      paymentMethod: paymentMethod,
      isDelivery: context.read<CheckoutCubit>().state.isDelivery,
    );

    OrderEntity? orderEntity;
    try {
      orderEntity = OrderModel.fromJson(data);
    } catch (_) {}

    final paymentUrl = data['payment_url'] as String?;
    if (paymentUrl != null && paymentUrl.isNotEmpty) {
      final uri = Uri.tryParse(paymentUrl);
      if (uri != null) {
        try {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } catch (e) {
          debugPrint('Could not launch payment URL: $e');
        }
      }
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('checkout.order_placed'.tr()),
        backgroundColor: AppColors.success,
      ));
      context.read<CartCubit>().clear();
      context.read<CheckoutCubit>().resetAfterOrder();
      if (orderId.isNotEmpty) {
        context.go('/order/$orderId', extra: orderEntity);
      } else {
        context.go('/orders');
      }
    }
  }
}

// ── Sub-widgets ──

class _SwitchRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(
              color: Theme.of(context).textTheme.bodyMedium?.color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Switch.adaptive(
          value: value,
          onChanged: onChanged,
          activeTrackColor: AppColors.primary,
        ),
      ],
    );
  }
}

class _PriceLine extends StatelessWidget {
  final String label;
  final String valueText;
  final bool isNegative;
  final bool isDark;

  const _PriceLine({
    required this.label,
    required this.valueText,
    this.isNegative = false,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTextStyles.bodyMedium.copyWith(
            color: isDark ? AppColors.neutral400 : AppColors.neutral500,
          ),
        ),
        Text(
          valueText,
          style: AppTextStyles.labelSmall.copyWith(
            color: isNegative
                ? AppColors.error
                : (isDark ? Colors.white : Theme.of(context).textTheme.bodyMedium?.color),
            fontWeight: isNegative ? FontWeight.bold : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class CheckoutBranch {
  final String id;
  final String title;
  final double latitude;
  final double longitude;

  CheckoutBranch({
    required this.id,
    required this.title,
    required this.latitude,
    required this.longitude,
  });

  factory CheckoutBranch.fromJson(Map<String, dynamic> json) {
    return CheckoutBranch(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      latitude: double.tryParse(json['latitude']?.toString() ?? '0') ?? 0,
      longitude: double.tryParse(json['longitude']?.toString() ?? '0') ?? 0,
    );
  }
}
