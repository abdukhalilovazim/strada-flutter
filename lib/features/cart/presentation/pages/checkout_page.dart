import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pizza_strada/core/network/api_client.dart';
import 'package:pizza_strada/core/services/analytics_service.dart';
import 'package:pizza_strada/core/storage/secure_storage.dart';
import 'package:pizza_strada/core/theme/app_colors.dart';
import 'package:pizza_strada/core/theme/app_text_styles.dart';
import 'package:pizza_strada/core/utils/number_formatter.dart';
import 'package:pizza_strada/core/utils/phone_number_formatter.dart';
import 'package:pizza_strada/features/cart/presentation/bloc/cart_cubit.dart';
import 'package:pizza_strada/features/cart/presentation/bloc/checkout/checkout_cubit.dart';
import 'package:pizza_strada/features/cart/presentation/bloc/checkout/checkout_state.dart';
import 'package:pizza_strada/features/home/domain/entities/home_entities.dart';
import 'package:pizza_strada/features/home/presentation/bloc/home_cubit.dart';
import 'package:url_launcher/url_launcher.dart';

/// Yagona va tezkor Buyurtma Rasmiylashtirish (Single-Step Checkout) sahifasi.
///
/// Home pageda tanlangan Yetkazib berish / Olib ketish va Manzil/Filial
/// to'g'ridan-to'g'ri integratsiya qilingan. Barcha bo'limlar (manzil,
/// qabul qiluvchi, to'lov turi, promokod va narx hisobi) yagona oynada mujassamlashgan.
class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  List<CheckoutBranch> _branches = [];
  bool _isLoadingBranches = false;

  final _commentController = TextEditingController();
  final _promoController = TextEditingController();
  final _changeController = TextEditingController();

  bool _showPromoInput = false;
  bool _showChangeInput = false;
  bool _showCommentInput = false;
  String? _userName;
  String? _userPhone;

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
    super.dispose();
  }

  Future<void> _loadBranches() async {
    setState(() => _isLoadingBranches = true);
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
    } finally {
      if (mounted) setState(() => _isLoadingBranches = false);
    }
  }

  Future<void> _loadUserData() async {
    final name = await SecureStorage.getUserName();
    final phone = await SecureStorage.getUserPhone();
    if (mounted) {
      setState(() {
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

        // Olib ketishda yetkazib berish har doim 0
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
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Theme.of(context).iconTheme.color,
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
                ),
                const SizedBox(height: 10),
                _buildDeliveryTypeSegment(context, checkoutState, isDark),
                const SizedBox(height: 12),
                if (checkoutState.isDelivery)
                  _buildAddressCard(context, checkoutState, isDark)
                else
                  _buildBranchSelector(context, checkoutState, isDark),

                const SizedBox(height: 20),

                // ── 2. Qabul qiluvchi ma'lumotlari ──
                _buildSectionHeader(
                  context,
                  icon: Icons.person_rounded,
                  title: 'checkout.recipient'.tr(),
                ),
                const SizedBox(height: 10),
                _buildRecipientCard(context, isDark),

                const SizedBox(height: 20),

                // ── 3. To'lov usuli ──
                _buildSectionHeader(
                  context,
                  icon: Icons.payment_rounded,
                  title: 'checkout.payment'.tr(),
                ),
                const SizedBox(height: 10),
                _buildPaymentMethodSection(context, checkoutState, paymentMethods, isDark),

                const SizedBox(height: 20),

                // ── 4. Qo'shimcha (Promo kod, Qaytim, Izoh) ──
                _buildSectionHeader(
                  context,
                  icon: Icons.tune_rounded,
                  title: 'checkout.additional'.tr(),
                ),
                const SizedBox(height: 10),
                _buildAdditionalSection(context, checkoutState, subtotal, isDark),

                const SizedBox(height: 20),

                // ── 5. Buyurtma hisobi (Narxlar breakdown) ──
                _buildSectionHeader(
                  context,
                  icon: Icons.receipt_long_rounded,
                  title: 'checkout.order_summary'.tr(),
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
  }) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(width: 8),
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

  /// Yetkazish / Olib ketish segmentli tugmalari (HomePage bilan 100% sinxron)
  Widget _buildDeliveryTypeSegment(
    BuildContext context,
    CheckoutState checkoutState,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.neutral100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.neutral800 : AppColors.neutral200,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _DeliveryTypeTab(
              label: 'checkout.delivery'.tr(),
              icon: Icons.delivery_dining_rounded,
              isSelected: checkoutState.isDelivery,
              onTap: () => context.read<CheckoutCubit>().setDeliveryType(true),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _DeliveryTypeTab(
              label: 'checkout.pickup'.tr(),
              icon: Icons.storefront_rounded,
              isSelected: !checkoutState.isDelivery,
              onTap: () => context.read<CheckoutCubit>().setDeliveryType(false),
            ),
          ),
        ],
      ),
    );
  }

  /// Yetkazib berish manzili kartasi
  Widget _buildAddressCard(
    BuildContext context,
    CheckoutState checkoutState,
    bool isDark,
  ) {
    final hasAddress = checkoutState.address != null && checkoutState.address!.isNotEmpty;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openMapPicker(context),
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: hasAddress
                  ? (isDark ? AppColors.neutral700 : AppColors.neutral300)
                  : AppColors.primary,
              width: hasAddress ? 1 : 1.5,
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
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.location_on_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'checkout.delivery_location'.tr(),
                      style: AppTextStyles.bodyExtraSmall.copyWith(
                        color: isDark ? AppColors.neutral400 : AppColors.neutral600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      hasAddress ? checkoutState.address! : 'checkout.select_address'.tr(),
                      style: AppTextStyles.labelMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        color: hasAddress
                            ? Theme.of(context).textTheme.bodyLarge?.color
                            : AppColors.primary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (hasAddress) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (checkoutState.loadingDelivery) ...[
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
                              style: AppTextStyles.bodyExtraSmall.copyWith(
                                color: AppColors.neutral500,
                              ),
                            ),
                          ] else if (checkoutState.deliveryPrice > 0) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${'cart.delivery'.tr()}: ${NumberFormatter.formatSum(checkoutState.deliveryPrice.toInt())} ${'common.currency'.tr()}',
                                style: AppTextStyles.bodyExtraSmall.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
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
                child: Text(
                  hasAddress ? 'common.change'.tr() : 'cart.add'.tr(),
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Olib ketish uchun filiallar tanlovi
  Widget _buildBranchSelector(
    BuildContext context,
    CheckoutState checkoutState,
    bool isDark,
  ) {
    if (_isLoadingBranches) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.primary),
          ),
        ),
      );
    }

    if (_branches.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.neutral100,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          'checkout.select_branch'.tr(),
          style: AppTextStyles.bodyMedium.copyWith(
            color: isDark ? AppColors.neutral400 : AppColors.neutral600,
          ),
        ),
      );
    }

    return Column(
      children: _branches.map((branch) {
        final isSelected = checkoutState.branchId == branch.id;

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => context.read<CheckoutCubit>().setBranch(
                    branch.id,
                    branchTitle: branch.title,
                  ),
              borderRadius: BorderRadius.circular(14),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                      blurRadius: isSelected ? 8 : 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary.withValues(alpha: 0.15)
                            : (isDark ? AppColors.neutral800 : AppColors.neutral100),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.storefront_rounded,
                        color: isSelected ? AppColors.primary : AppColors.neutral500,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        branch.title,
                        style: AppTextStyles.labelMedium.copyWith(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                          color: isSelected
                              ? AppColors.primary
                              : Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : (isDark ? AppColors.neutral700 : AppColors.neutral300),
                          width: 2,
                        ),
                      ),
                      child: isSelected
                          ? Center(
                              child: Container(
                                width: 10,
                                height: 10,
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            )
                          : null,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  /// Qabul qiluvchi shaxs ma'lumotlari (Ism + Raqam)
  Widget _buildRecipientCard(BuildContext context, bool isDark) {
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

  /// Narxlar hisob-kitobi (Subtotal, Delivery, Discount, Total)
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
          _PriceLine(
            label: 'cart.subtotal'.tr(),
            valueText: '${NumberFormatter.formatSum(subtotal.toInt())} ${'common.currency'.tr()}',
          ),
          const Divider(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'cart.delivery'.tr(),
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.neutral500),
              ),
              if (!checkoutState.isDelivery)
                Text(
                  'checkout.free'.tr(),
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.bold,
                  ),
                )
              else if (checkoutState.loadingDelivery)
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
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.neutral500),
                    ),
                  ],
                )
              else if (checkoutState.address == null || checkoutState.address!.isEmpty)
                Text(
                  'checkout.on_address_select'.tr(),
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.neutral500,
                    fontStyle: FontStyle.italic,
                  ),
                )
              else
                Text(
                  '${NumberFormatter.formatSum(deliveryFee.toInt())} ${'common.currency'.tr()}',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
          if (discount > 0) ...[
            const Divider(height: 18),
            _PriceLine(
              label: 'cart.discount'.tr(),
              valueText: '- ${NumberFormatter.formatSum(discount.toInt())} ${'common.currency'.tr()}',
              isNegative: true,
            ),
          ],
          const Divider(height: 18),
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
    required double finalTotal,
    required bool isDark,
  }) {
    final bool needsAddress = checkoutState.isDelivery &&
        (checkoutState.address == null || checkoutState.address!.isEmpty);

    final bool canSubmit = !needsAddress &&
        !checkoutState.isSubmitting &&
        !checkoutState.loadingDelivery &&
        cartState.items.isNotEmpty &&
        (!checkoutState.isDelivery ? checkoutState.branchId != null : true);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.neutral800 : AppColors.neutral200,
            width: 1,
          ),
        ),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -4)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: needsAddress
                ? () => _openMapPicker(context)
                : (canSubmit ? () => _submitOrder(context, cartState) : null),
            style: ElevatedButton.styleFrom(
              backgroundColor: needsAddress ? AppColors.secondary : AppColors.primary,
              foregroundColor: Colors.white,
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
                        needsAddress ? Icons.location_on_rounded : Icons.check_circle_outline_rounded,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        needsAddress
                            ? 'checkout.select_address'.tr()
                            : '${'checkout.submit_order'.tr()} • ${NumberFormatter.formatSum(finalTotal.toInt())} ${'common.currency'.tr()}',
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
      ),
    );
  }

  Future<void> _openMapPicker(BuildContext context) async {
    final result = await context.push<Map<String, dynamic>>('/map-picker');
    if (result != null && context.mounted) {
      final lat = result['lat'] as double?;
      final lng = result['lng'] as double?;
      final addr = result['address'] as String;
      if (lat != null && lng != null) {
        context.read<CheckoutCubit>().setAddressAndCalculateDelivery(lat, lng, addr);
      }
    }
  }

  void _submitOrder(BuildContext context, CartState cartState) {
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
        context.go('/order/$orderId');
      } else {
        context.go('/orders');
      }
    }
  }
}

// ── Sub-widgets ──

class _DeliveryTypeTab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _DeliveryTypeTab({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : (isDark ? AppColors.darkSurface : Colors.transparent),
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? Colors.white
                  : (isDark ? AppColors.neutral400 : AppColors.neutral600),
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppTextStyles.labelMedium.copyWith(
                fontWeight: FontWeight.bold,
                color: isSelected
                    ? Colors.white
                    : (isDark ? AppColors.neutral300 : AppColors.neutral700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
          activeColor: AppColors.primary,
        ),
      ],
    );
  }
}

class _PriceLine extends StatelessWidget {
  final String label;
  final String valueText;
  final bool isNegative;

  const _PriceLine({
    required this.label,
    required this.valueText,
    this.isNegative = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.neutral500),
        ),
        Text(
          valueText,
          style: AppTextStyles.labelSmall.copyWith(
            color: isNegative
                ? AppColors.error
                : Theme.of(context).textTheme.bodyMedium?.color,
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
