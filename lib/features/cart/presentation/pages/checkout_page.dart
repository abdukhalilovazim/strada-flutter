import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pizza_strada/core/theme/app_colors.dart';
import 'package:pizza_strada/core/theme/app_text_styles.dart';
import 'package:pizza_strada/core/utils/number_formatter.dart';
import 'package:pizza_strada/features/cart/presentation/bloc/cart_cubit.dart';
import 'package:pizza_strada/features/cart/presentation/bloc/checkout/checkout_cubit.dart';
import 'package:pizza_strada/features/cart/presentation/bloc/checkout/checkout_state.dart';
import 'package:pizza_strada/features/home/domain/entities/home_entities.dart';
import 'package:pizza_strada/features/home/presentation/bloc/home_cubit.dart';
import 'package:go_router/go_router.dart';
import 'package:pizza_strada/core/network/api_client.dart';
import 'package:pizza_strada/core/services/analytics_service.dart';
import 'package:pizza_strada/core/storage/secure_storage.dart';
import 'package:pizza_strada/core/utils/phone_number_formatter.dart';
import 'package:url_launcher/url_launcher.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  List<CheckoutBranch> _branches = [];
  bool _isLoadingBranches = false;

  /// 2-bosqichli checkout: 0 = Step1 (buyurtma+manzil), 1 = Step2 (to'lov+chegirma)
  int _currentStep = 0;

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
      if (response is List) {
        setState(() {
          _branches = response
              .map((e) => CheckoutBranch.fromJson(e as Map<String, dynamic>))
              .toList();
          if (_branches.isNotEmpty &&
              context.read<CheckoutCubit>().state.branchId == null) {
            context.read<CheckoutCubit>().setBranch(
                  _branches.first.id,
                  branchTitle: _branches.first.title,
                );
          }
        });
      }
    } catch (_) {} finally {
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
    if (state.appliedPromoCode != null && state.promoValue != null) {
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

        final finalTotal = (subtotal +
                checkoutState.deliveryPrice -
                discount)
            .clamp(0, double.infinity);

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            title: Text(
              'checkout.title'.tr(),
              style: AppTextStyles.h2.copyWith(
                  color: Theme.of(context).textTheme.headlineMedium?.color),
            ),
            centerTitle: true,
            backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
            elevation: 0,
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Theme.of(context).iconTheme.color,
              ),
              onPressed: () {
                if (_currentStep == 1) {
                  setState(() => _currentStep = 0);
                } else {
                  context.pop();
                }
              },
            ),
            bottom: _buildStepIndicator(isDark),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: _currentStep == 0
                ? _buildStep1(context, checkoutState, isDark)
                : _buildStep2(context, checkoutState, paymentMethods, subtotal,
                    discount, finalTotal.toDouble(), isDark),
          ),
          bottomNavigationBar: _buildBottomBar(
              context, checkoutState, cartState, subtotal, discount,
              finalTotal.toDouble()),
        );
      },
    );
  }

  /// Progress step indicator (1/2, 2/2)
  PreferredSizeWidget _buildStepIndicator(bool isDark) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(56),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
        child: Row(
          children: [
            _StepDot(
              number: 1,
              label: 'checkout.step1_label'.tr(),
              isActive: _currentStep == 0,
              isDone: _currentStep > 0,
            ),
            Expanded(
              child: Container(
                height: 2,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                color: _currentStep > 0
                    ? AppColors.primary
                    : (isDark ? AppColors.neutral700 : AppColors.neutral200),
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

  /// Step 1: Buyurtma turi + Manzil/Filial
  Widget _buildStep1(
      BuildContext context, CheckoutState checkoutState, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Yetkazish turi
        Text('checkout.delivery_type'.tr(),
            style: AppTextStyles.h3.copyWith(
                color:
                    Theme.of(context).textTheme.headlineMedium?.color)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? AppColors.neutral800 : AppColors.neutral200,
            ),
          ),
          child: Row(
            children: [
              _DeliveryTypeButton(
                label: 'checkout.delivery'.tr(),
                icon: Icons.moped_rounded,
                isSelected: checkoutState.isDelivery,
                onTap: () =>
                    context.read<CheckoutCubit>().setDeliveryType(true),
              ),
              _DeliveryTypeButton(
                label: 'checkout.pickup'.tr(),
                icon: Icons.storefront_rounded,
                isSelected: !checkoutState.isDelivery,
                onTap: () =>
                    context.read<CheckoutCubit>().setDeliveryType(false),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Manzil yoki filial
        Text(
          checkoutState.isDelivery
              ? 'checkout.address'.tr()
              : 'checkout.branch'.tr(),
          style: AppTextStyles.h3.copyWith(
              color:
                  Theme.of(context).textTheme.headlineMedium?.color),
        ),
        const SizedBox(height: 12),
        if (checkoutState.isDelivery)
          _SelectorCard(
            icon: Icons.location_on_rounded,
            text: checkoutState.address ?? 'checkout.select_address'.tr(),
            isPlaceholder: checkoutState.address == null,
            isLoading: checkoutState.loadingDelivery,
            isDark: isDark,
            onTap: () async {
              final result =
                  await context.push<Map<String, dynamic>>('/map-picker');
              if (result != null) {
                if (!context.mounted) return;
                final lat = result['lat'] as double?;
                final lng = result['lng'] as double?;
                final addr = result['address'] as String;
                if (lat != null && lng != null) {
                  context
                      .read<CheckoutCubit>()
                      .setAddressAndCalculateDelivery(lat, lng, addr);
                }
              }
            },
          )
        else ...[
          if (_isLoadingBranches)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: AppColors.primary,
                  ),
                ),
              ),
            )
          else if (_branches.isEmpty)
            Container(
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
            )
          else
            Column(
              children: _branches.map((branch) {
                final isSelected = checkoutState.branchId == branch.id;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
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
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? (isDark
                                  ? AppColors.primary.withValues(alpha: 0.15)
                                  : AppColors.primaryLight)
                              : (isDark
                                  ? AppColors.darkSurface
                                  : Colors.white),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : (isDark
                                    ? AppColors.neutral800
                                    : AppColors.neutral200),
                            width: isSelected ? 1.5 : 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(
                                  alpha: isDark ? 0.2 : 0.04),
                              blurRadius: 6,
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
                                    : (isDark
                                        ? AppColors.neutral800
                                        : AppColors.neutral100),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.storefront_rounded,
                                color: isSelected
                                    ? AppColors.primary
                                    : (isDark
                                        ? AppColors.neutral400
                                        : AppColors.neutral600),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                branch.title,
                                style: AppTextStyles.labelMedium.copyWith(
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.w600,
                                  color: isSelected
                                      ? AppColors.primary
                                      : Theme.of(context)
                                          .textTheme
                                          .bodyLarge
                                          ?.color,
                                  fontSize: 14,
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
                                      : (isDark
                                          ? AppColors.neutral700
                                          : AppColors.neutral300),
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
            ),
        ],
        const SizedBox(height: 32),
      ],
    );
  }

  /// Step 2: Chegirma + To'lov + Narx breakdown
  Widget _buildStep2(
    BuildContext context,
    CheckoutState checkoutState,
    List<PaymentMethodEntity> paymentMethods,
    double subtotal,
    double discount,
    double finalTotal,
    bool isDark,
  ) {
    final isDelivery = checkoutState.isDelivery;
    final locationTitle = isDelivery
        ? (checkoutState.address != null && checkoutState.address!.isNotEmpty
            ? checkoutState.address!
            : 'checkout.select_address'.tr())
        : (checkoutState.branchTitle != null &&
                checkoutState.branchTitle!.isNotEmpty
            ? checkoutState.branchTitle!
            : (_branches
                    .cast<CheckoutBranch?>()
                    .firstWhere((b) => b?.id == checkoutState.branchId,
                        orElse: () => null)
                    ?.title ??
                'checkout.branch'.tr()));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── 1. Yetkazib berish va Qabul qiluvchi ma'lumotlari ──
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'checkout.order_summary'.tr(),
              style: AppTextStyles.h3.copyWith(
                color: Theme.of(context).textTheme.headlineMedium?.color,
              ),
            ),
            TextButton.icon(
              onPressed: () => setState(() => _currentStep = 0),
              icon: const Icon(Icons.edit_outlined,
                  size: 15, color: AppColors.primary),
              label: Text(
                'common.change'.tr(),
                style:
                    AppTextStyles.labelSmall.copyWith(color: AppColors.primary),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? AppColors.neutral800 : AppColors.neutral200,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Yetkazib berish / Olib ketish joyi
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isDelivery
                          ? AppColors.primary.withValues(alpha: 0.1)
                          : AppColors.secondary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      isDelivery
                          ? Icons.delivery_dining_rounded
                          : Icons.storefront_rounded,
                      color:
                          isDelivery ? AppColors.primary : AppColors.secondary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isDelivery
                              ? 'checkout.delivery_location'.tr()
                              : 'checkout.pickup_location'.tr(),
                          style: AppTextStyles.bodyExtraSmall.copyWith(
                            color: isDark
                                ? AppColors.neutral400
                                : AppColors.neutral600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          locationTitle,
                          style: AppTextStyles.labelMedium.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Divider(height: 1),
              ),
              // Qabul qiluvchi ma'lumotlari (Ism + Telefon)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 36,
                    height: 36,
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
                          'checkout.recipient'.tr(),
                          style: AppTextStyles.bodyExtraSmall.copyWith(
                            color: isDark
                                ? AppColors.neutral400
                                : AppColors.neutral600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _userName != null && _userName!.isNotEmpty
                              ? _userName!
                              : 'profile.guest'.tr(),
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
                              color: isDark
                                  ? AppColors.neutral400
                                  : AppColors.neutral600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // ── 2. To'lov usuli ──
        Text('checkout.payment'.tr(),
            style: AppTextStyles.h3.copyWith(
                color: Theme.of(context).textTheme.headlineMedium?.color)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: isDark ? AppColors.neutral800 : AppColors.neutral200),
          ),
          child: Row(
            children: [
              for (int i = 0; i < paymentMethods.take(3).length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(
                  child: InkWell(
                    onTap: () {
                      context
                          .read<CheckoutCubit>()
                          .setPaymentMethod(paymentMethods[i].key);
                      if (paymentMethods[i].key != '0') {
                        setState(() {
                          _showChangeInput = false;
                          _changeController.clear();
                        });
                        context
                            .read<CheckoutCubit>()
                            .setChangeAmount(null);
                      }
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      height: 50,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: checkoutState.selectedPaymentMethodKey ==
                                paymentMethods[i].key
                            ? AppColors.primaryLight
                            : Colors.transparent,
                        border: Border.all(
                          color: checkoutState.selectedPaymentMethodKey ==
                                  paymentMethods[i].key
                              ? AppColors.primary
                              : (isDark
                                  ? AppColors.neutral700
                                  : AppColors.neutral200),
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _getPaymentMethodId(paymentMethods[i].key) == 1
                                ? Icons.account_balance_wallet_outlined
                                : (_getPaymentMethodId(
                                            paymentMethods[i].key) ==
                                        2
                                    ? Icons.credit_card_outlined
                                    : Icons.payments_outlined),
                            color: checkoutState.selectedPaymentMethodKey ==
                                    paymentMethods[i].key
                                ? AppColors.primary
                                : AppColors.neutral500,
                            size: 18,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            paymentMethods[i].value,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.bodyExtraSmall.copyWith(
                              color: checkoutState.selectedPaymentMethodKey ==
                                      paymentMethods[i].key
                                  ? AppColors.primary
                                  : AppColors.neutral600,
                              fontWeight: checkoutState
                                          .selectedPaymentMethodKey ==
                                      paymentMethods[i].key
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Qo'shimcha (Promo kod, Valyuta, Izoh)
        Text('checkout.additional'.tr(),
            style: AppTextStyles.h3.copyWith(
                color: Theme.of(context).textTheme.headlineMedium?.color)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: isDark ? AppColors.neutral800 : AppColors.neutral200),
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
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _promoController,
                        textCapitalization: TextCapitalization.characters,
                        decoration: InputDecoration(
                          hintText: 'cart.enter_promo'.tr(),
                          errorText: checkoutState.promoError,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                        ),
                      ),
                    ),
                    if (checkoutState.loadingPromo)
                      const SizedBox(
                          width: 24,
                          height: 24,
                          child:
                              CircularProgressIndicator(strokeWidth: 2))
                    else
                      TextButton(
                        onPressed: () {
                          context.read<CheckoutCubit>().applyPromo(
                              _promoController.text.trim().toUpperCase(),
                              subtotal);
                          FocusScope.of(context).unfocus();
                        },
                        child: Text('cart.apply'.tr(),
                            style: AppTextStyles.labelMedium
                                .copyWith(color: AppColors.primary)),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              const Divider(height: 16),

              // Qayta pul berish
              if (checkoutState.selectedPaymentMethodKey == '0') ...[
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
                  TextField(
                    controller: _changeController,
                    keyboardType: TextInputType.number,
                    onChanged: (val) => context
                        .read<CheckoutCubit>()
                        .setChangeAmount(double.tryParse(val)),
                    decoration: InputDecoration(
                      hintText: 'checkout.enter_amount'.tr(),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                const Divider(height: 16),
              ],

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
                TextField(
                  controller: _commentController,
                  maxLines: 3,
                  onChanged: (val) =>
                      context.read<CheckoutCubit>().setComment(val),
                  decoration: InputDecoration(
                    hintText: 'checkout.comment_hint'.tr(),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ],
          ),
        ),
        const SizedBox(height: 32),

        // Narx bo'linishi
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: isDark ? AppColors.neutral800 : AppColors.neutral200),
          ),
          child: Column(
            children: [
              _PriceLine(label: 'cart.subtotal'.tr(), value: subtotal),
              if (checkoutState.isDelivery) ...[
                const Divider(height: 16),
                _PriceLine(
                    label: 'cart.delivery'.tr(),
                    value: checkoutState.deliveryPrice),
              ],
              if (discount > 0) ...[
                const Divider(height: 16),
                _PriceLine(
                    label: 'cart.promo'.tr(),
                    value: discount,
                    isNegative: true),
              ],
              const Divider(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('cart.total'.tr(),
                      style: AppTextStyles.labelLarge.copyWith(
                          color: Theme.of(context)
                              .textTheme
                              .bodyLarge
                              ?.color)),
                  Text(
                    '${NumberFormatter.formatSum(finalTotal.toInt())} ${'common.currency'.tr()}',
                    style: AppTextStyles.h3
                        .copyWith(color: AppColors.primary),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildBottomBar(
    BuildContext context,
    CheckoutState checkoutState,
    CartState cartState,
    double subtotal,
    double discount,
    double finalTotal,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.neutral800 : AppColors.neutral200,
            width: 1,
          ),
        ),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -4))
        ],
      ),
      child: SafeArea(
        top: false,
        child: _currentStep == 0
            ? ElevatedButton(
                onPressed: (checkoutState.isDelivery
                        ? (checkoutState.address != null &&
                            !checkoutState.loadingDelivery)
                        : checkoutState.branchId != null)
                    ? () {
                        AnalyticsService.instance.logCheckoutStarted(
                          itemCount: cartState.items.length,
                          totalAmount: finalTotal,
                          isDelivery: checkoutState.isDelivery,
                        );
                        setState(() => _currentStep = 1);
                      }
                    : null,
                child: Text('checkout.next'.tr()),
              )
            : ElevatedButton(
                onPressed: (checkoutState.isSubmitting ||
                        cartState.items.isEmpty)
                    ? null
                    : () {
                        final products = cartState.items.map((item) {
                          final variantId = item.variant?.id ??
                              item.product.variants.firstOrNull?.id ??
                              0;
                          return {
                            'id': variantId,
                            'variant_id': variantId,
                            'quantity': item.quantity,
                          };
                        }).toList();
                        context.read<CheckoutCubit>().submitOrder(
                            products: products);
                      },
                child: checkoutState.isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : Text('checkout.submit_order'.tr()),
              ),
      ),
    );
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
    final color = (isActive || isDone) ? AppColors.primary : AppColors.neutral300;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary : (isDone ? AppColors.primary : Colors.transparent),
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 2),
          ),
          child: Center(
            child: isDone
                ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                : Text(
                    '$number',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: isActive ? Colors.white : AppColors.neutral400,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTextStyles.bodyExtraSmall.copyWith(
            color: color,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _DeliveryTypeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _DeliveryTypeButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryLight : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  color:
                      isSelected ? AppColors.primary : AppColors.neutral500,
                  size: 20),
              const SizedBox(width: 8),
              Text(label,
                  style: AppTextStyles.labelMedium.copyWith(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.neutral500)),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectorCard extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool isPlaceholder;
  final bool isLoading;
  final bool isDark;
  final VoidCallback onTap;

  const _SelectorCard({
    required this.icon,
    required this.text,
    required this.isPlaceholder,
    required this.isLoading,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: isDark ? AppColors.neutral800 : AppColors.neutral200),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: isPlaceholder
                      ? AppColors.neutral400
                      : Theme.of(context).textTheme.bodyMedium?.color,
                ),
              ),
            ),
            if (isLoading)
              const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2))
            else
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.neutral400),
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
          child: Text(label,
              style: AppTextStyles.bodyMedium.copyWith(
                  color:
                      Theme.of(context).textTheme.bodyMedium?.color)),
        ),
        Switch.adaptive(value: value, onChanged: onChanged),
      ],
    );
  }
}

class _PriceLine extends StatelessWidget {
  final String label;
  final double value;
  final bool isNegative;

  const _PriceLine(
      {required this.label, required this.value, this.isNegative = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: AppTextStyles.bodyMedium
                .copyWith(color: AppColors.neutral500)),
        Text(
          '${isNegative ? '- ' : ''}${NumberFormatter.formatSum(value.toInt())} ${'common.currency'.tr()}',
          style: AppTextStyles.labelSmall.copyWith(
            color: isNegative
                ? AppColors.error
                : Theme.of(context).textTheme.bodyMedium?.color,
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
      latitude:
          double.tryParse(json['latitude']?.toString() ?? '0') ?? 0,
      longitude:
          double.tryParse(json['longitude']?.toString() ?? '0') ?? 0,
    );
  }
}
