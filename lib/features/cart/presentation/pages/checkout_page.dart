import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:pizza_strada/core/network/graphql_client.dart';
import 'package:pizza_strada/core/storage/secure_storage.dart';
import 'package:pizza_strada/core/theme/app_colors.dart';
import 'package:pizza_strada/core/theme/app_text_styles.dart';
import 'package:pizza_strada/core/utils/number_formatter.dart';
import 'package:pizza_strada/features/cart/presentation/bloc/cart_cubit.dart';
import 'package:pizza_strada/features/home/presentation/bloc/home_cubit.dart';
import 'package:pizza_strada/features/home/domain/entities/home_entities.dart';
import 'package:url_launcher/url_launcher.dart';


class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  bool _isDelivery = true;

  final _addressController = TextEditingController();
  final _commentController = TextEditingController();
  final _promoController = TextEditingController();
  final _changeController = TextEditingController();

  // Delivery
  double? _deliveryPrice;
  bool _loadingDelivery = false;

  // Promo
  String? _appliedPromoCode;
  int? _promoType;    // 0 = fixed, 1 = percent
  double? _promoValue;
  bool _loadingPromo = false;
  String? _promoError;

  // Qaytim (change)
  bool _showChangeInput = false;
  bool _showCommentInput = false;
  bool _showPromoInput = false;

  // Location
  double? _lat;
  double? _lng;

  bool _isSubmitting = false;

  // Branches
  List<CheckoutBranch> _branches = [];
  CheckoutBranch? _selectedBranch;
  bool _isLoadingBranches = false;

  // Payment Method
  String _selectedPaymentMethodKey = '0';

  int _getPaymentMethodId(String key) {
    final cleanKey = key.toLowerCase().trim();
    if (cleanKey == 'payme' || cleanKey == '1') {
      return 1;
    } else if (cleanKey == 'click' || cleanKey == '2') {
      return 2;
    }
    return 0; // Default Cash (Naqd)
  }

  Future<void> _loadBranches() async {
    setState(() => _isLoadingBranches = true);
    try {
      const query = r'''
        query Branches {
          branches {
            id
            title
            latitude
            longitude
          }
        }
      ''';
      
      final result = await _gqlClient.query(QueryOptions(
        document: gql(query),
        operationName: 'Branches',
        fetchPolicy: FetchPolicy.networkOnly,
      ));

      if (!result.hasException && result.data?['branches'] != null) {
        final list = result.data?['branches'] as List;
        setState(() {
          _branches = list.map((e) => CheckoutBranch.fromJson(e)).toList();
          if (_branches.isNotEmpty) {
            _selectedBranch = _branches.first;
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading branches: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingBranches = false);
      }
    }
  }

  void _showBranchPicker() {
    if (_branches.isEmpty) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top drag indicator
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.neutral300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'checkout.branch'.tr(),
                style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _branches.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.neutral100),
                  itemBuilder: (context, index) {
                    final branch = _branches[index];
                    final isSelected = _selectedBranch?.id == branch.id;
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        branch.title,
                        style: AppTextStyles.labelMedium.copyWith(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected ? AppColors.primary : Theme.of(context).textTheme.bodyMedium?.color,
                        ),
                      ),
                      subtitle: Text(
                        branch.address,
                        style: AppTextStyles.bodySmall.copyWith(color: AppColors.neutral500),
                      ),
                      trailing: isSelected 
                          ? const Icon(Icons.check_circle_rounded, color: AppColors.primary)
                          : null,
                      onTap: () {
                        setState(() {
                          _selectedBranch = branch;
                        });
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  late GraphQLClient _gqlClient;

  @override
  void initState() {
    super.initState();
    _initClient();
  }

  void _initClient() {
    setState(() => _gqlClient = buildGraphQLClient());
    _loadBranches();

    // Set initial payment method from HomeLoaded settings
    final homeState = context.read<HomeCubit>().state;
    if (homeState is HomeLoaded) {
      final methods = homeState.settings?.paymentMethods ?? [];
      if (methods.isNotEmpty) {
        _selectedPaymentMethodKey = methods.first.key;
      }
    }
  }

  @override
  void dispose() {
    _addressController.dispose();
    _commentController.dispose();
    _promoController.dispose();
    _changeController.dispose();
    super.dispose();
  }

  // ─── Delivery price mutation ──────────────────────────────────────────────
  Future<void> _calculateDelivery({double? lat, double? lng}) async {
    if (lat == null || lng == null) return;
    setState(() => _loadingDelivery = true);
    const mutation = r'''
      mutation CalculateDeliveryPrice($latitude: Float!, $longitude: Float!) {
        calculateDeliveryPrice(latitude: $latitude, longitude: $longitude)
      }
    ''';
    final result = await _gqlClient.mutate(MutationOptions(
      document: gql(mutation),
      variables: {'latitude': lat, 'longitude': lng},
      operationName: 'CalculateDeliveryPrice',
    ));
    setState(() {
      _loadingDelivery = false;
      if (!result.hasException) {
        _lat = lat;
        _lng = lng;
        _deliveryPrice = double.tryParse(
          result.data?['calculateDeliveryPrice']?.toString() ?? '0',
        );
      }
    });
  }

  // ─── Promo code mutation ──────────────────────────────────────────────────
  Future<void> _applyPromo(double subtotal) async {
    final code = _promoController.text.trim();
    if (code.isEmpty) return;

    setState(() {
      _loadingPromo = true;
      _promoError = null;
    });

    const mutation = r'''
      mutation CheckPromoCode($promo_code: String!, $total_price: Int!) {
        checkPromoCode(promo_code: $promo_code, total_price: $total_price) {
          promo_code
          type
          value
        }
      }
    ''';

    final result = await _gqlClient.mutate(MutationOptions(
      document: gql(mutation),
      variables: {'promo_code': code, 'total_price': subtotal.toInt()},
      operationName: 'CheckPromoCode',
    ));

    setState(() {
      _loadingPromo = false;
      if (result.hasException) {
        _appliedPromoCode = null;
        _promoType = null;
        _promoValue = null;
        // Extract server error message
        final msg = result.exception?.graphqlErrors.firstOrNull?.message ?? 'checkout.promo_invalid'.tr();
        _promoError = msg;
      } else {
        final data = result.data?['checkPromoCode'];
        _appliedPromoCode = data?['promo_code'] as String?;
        _promoType = data?['type'] as int?;
        _promoValue = double.tryParse(data?['value']?.toString() ?? '0');
        _promoError = null;
        FocusManager.instance.primaryFocus?.unfocus();
      }
    });
  }

  // ─── Discount calculation ─────────────────────────────────────────────────
  double _computeDiscount(double subtotal) {
    if (!_showPromoInput || _appliedPromoCode == null || _promoValue == null) return 0;
    if (_promoType == 1) {
      // Percent — only from products, not delivery
      return subtotal * _promoValue! / 100;
    } else {
      // Fixed — deducted from total
      return _promoValue!;
    }
  }

  // ─── Change (qaytim) calculation ─────────────────────────────────────────
  double? get _changeAmount {
    final text = _changeController.text.trim().replaceAll(' ', '');
    if (text.isEmpty) return null;
    final paid = double.tryParse(text);
    if (paid == null) return null;
    final subtotal = context.read<CartCubit>().state.subtotal;
    final delivery = _isDelivery ? (_deliveryPrice ?? 0) : 0;
    final discount = _computeDiscount(subtotal);
    final total = subtotal + delivery - discount;
    final change = paid - total;
    return change > 0 ? change : null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text('checkout.title'.tr()),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: BlocBuilder<CartCubit, CartState>(
        builder: (context, cartState) {
          final subtotal = cartState.subtotal;
          final delivery = _isDelivery ? (_deliveryPrice ?? 0) : 0.0;
          final discount = _computeDiscount(subtotal);
          final total = subtotal + delivery - discount;
          final change = _changeAmount;
          final homeState = context.read<HomeCubit>().state;
          List<PaymentMethodEntity> paymentMethods = [];
          if (homeState is HomeLoaded) {
            paymentMethods = homeState.settings?.paymentMethods ?? [];
          }
          if (paymentMethods.isEmpty) {
            paymentMethods = [
              const PaymentMethodEntity(key: '0', value: 'Naqd pul'),
            ];
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Store Closed Warning ──────────────────────────────────
                BlocBuilder<HomeCubit, HomeState>(
                  builder: (context, homeState) {
                    final canOrder = homeState is HomeLoaded ? (homeState.settings?.canOrder ?? true) : true;
                    if (!canOrder) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 20),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.error.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.error.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline_rounded, color: AppColors.error),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'error.order_disabled'.tr(),
                                style: AppTextStyles.bodySmall.copyWith(color: AppColors.error, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
                // ── Delivery / Pickup Toggle ──────────────────────────────
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.neutral100,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      _buildToggleItem(
                        title: 'checkout.delivery'.tr(),
                        icon: Icons.delivery_dining_rounded,
                        isActive: _isDelivery,
                        onTap: () {
                          setState(() => _isDelivery = true);
                          _calculateDelivery();
                        },
                      ),
                      _buildToggleItem(
                        title: 'checkout.pickup'.tr(),
                        icon: Icons.storefront_rounded,
                        isActive: !_isDelivery,
                        onTap: () => setState(() {
                          _isDelivery = false;
                          _deliveryPrice = 0;
                        }),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ── Address / Branch ──────────────────────────────────────
                if (_isDelivery) ...[
                  _sectionLabel('checkout.address'.tr()),
                  const SizedBox(height: 8),
                  _buildCardField(
                    child: TextField(
                      controller: _addressController,
                      readOnly: true,
                      onTap: () async {
                        final result = await context.push<Map<String, dynamic>>('/map-picker');
                        if (result != null) {
                          final lat = result['lat'] as double;
                          final lng = result['lng'] as double;
                          final address = result['address'] as String;
                          setState(() {
                            _addressController.text = address;
                          });
                          _calculateDelivery(lat: lat, lng: lng);
                        }
                      },
                      decoration: InputDecoration(
                        hintText: 'checkout.select_address'.tr(),
                        hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.neutral400),
                        border: InputBorder.none,
                        prefixIcon: const Icon(Icons.location_on_rounded, color: AppColors.primary, size: 20),
                        suffixIcon: const Icon(Icons.chevron_right_rounded, color: AppColors.neutral400),
                      ),
                    ),
                  ),
                ] else ...[
                  _sectionLabel('checkout.branch'.tr()),
                  const SizedBox(height: 8),
                  _buildCardField(
                    child: InkWell(
                      onTap: _showBranchPicker,
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                        child: Row(
                          children: [
                            const Icon(Icons.storefront_rounded, color: AppColors.primary, size: 22),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _selectedBranch != null 
                                    ? _selectedBranch!.title 
                                    : (_isLoadingBranches ? 'checkout.calculating'.tr() : 'checkout.branch'.tr()), 
                                style: AppTextStyles.bodyMedium,
                              ),
                            ),
                            if (_isLoadingBranches)
                              const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            else
                              const Icon(Icons.chevron_right_rounded, color: AppColors.neutral400),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 24),

                // ── Payment method ────────────────────────────────────────
                _sectionLabel('checkout.payment'.tr()),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppColors.neutral800
                          : AppColors.neutral100,
                    ),
                  ),
                  child: Row(
                    children: [
                      for (int i = 0; i < paymentMethods.take(3).length; i++) ...[
                        if (i > 0) const SizedBox(width: 8),
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _selectedPaymentMethodKey = paymentMethods[i].key;
                                if (_selectedPaymentMethodKey != '0') {
                                  _showChangeInput = false;
                                  _changeController.clear();
                                }
                              });
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              height: 48,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: _selectedPaymentMethodKey == paymentMethods[i].key
                                    ? (Theme.of(context).brightness == Brightness.dark ? AppColors.primary.withOpacity(0.15) : AppColors.primaryLight)
                                    : (Theme.of(context).brightness == Brightness.dark ? AppColors.darkBackground : AppColors.neutral50),
                                border: Border.all(
                                  color: _selectedPaymentMethodKey == paymentMethods[i].key
                                      ? AppColors.primary
                                      : (Theme.of(context).brightness == Brightness.dark ? AppColors.neutral800 : AppColors.neutral200),
                                  width: 1.5,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    _getPaymentMethodId(paymentMethods[i].key) == 1
                                        ? Icons.account_balance_wallet_outlined
                                        : (_getPaymentMethodId(paymentMethods[i].key) == 2
                                            ? Icons.credit_card_outlined
                                            : Icons.payments_outlined),
                                    color: _selectedPaymentMethodKey == paymentMethods[i].key
                                        ? AppColors.primary
                                        : (Theme.of(context).brightness == Brightness.dark ? AppColors.neutral400 : AppColors.neutral600),
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      paymentMethods[i].value,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTextStyles.labelSmall.copyWith(
                                        color: _selectedPaymentMethodKey == paymentMethods[i].key
                                            ? AppColors.primary
                                            : (Theme.of(context).brightness == Brightness.dark ? Colors.white : AppColors.neutral800),
                                        fontWeight: _selectedPaymentMethodKey == paymentMethods[i].key ? FontWeight.bold : FontWeight.w500,
                                      ),
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
                const SizedBox(height: 20),

                // ── Unified Extras Group (Promo, Change, Comment) ──────────
                _sectionLabel('checkout.additional'.tr()),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppColors.neutral800
                          : AppColors.neutral100,
                    ),
                  ),
                  child: Column(
                    children: [
                      // 1. Promo Code section
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.local_offer_outlined, color: AppColors.primary, size: 20),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text('cart.promo'.tr(), style: AppTextStyles.bodyMedium),
                                ),
                                Switch.adaptive(
                                  value: _showPromoInput,
                                  onChanged: (val) => setState(() {
                                    _showPromoInput = val;
                                    if (!val) {
                                      _promoController.clear();
                                      _appliedPromoCode = null;
                                      _promoType = null;
                                      _promoValue = null;
                                      _promoError = null;
                                    }
                                  }),
                                  activeColor: AppColors.primary,
                                ),
                              ],
                            ),
                            AnimatedSize(
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeInOut,
                              child: _showPromoInput
                                  ? Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  color: Theme.of(context).brightness == Brightness.dark
                                                      ? AppColors.darkBackground
                                                      : AppColors.neutral50,
                                                  borderRadius: BorderRadius.circular(12),
                                                  border: Border.all(
                                                    color: Theme.of(context).brightness == Brightness.dark
                                                        ? AppColors.neutral800
                                                        : AppColors.neutral200,
                                                  ),
                                                ),
                                                child: TextField(
                                                  controller: _promoController,
                                                  style: AppTextStyles.bodyMedium,
                                                  textAlignVertical: TextAlignVertical.center,
                                                  inputFormatters: [
                                                    UpperCaseTextFormatter(),
                                                  ],
                                                  decoration: InputDecoration(
                                                    hintText: 'checkout.promo_hint'.tr(),
                                                    hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.neutral400),
                                                    border: InputBorder.none,
                                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            SizedBox(
                                              height: 44,
                                              child: ElevatedButton(
                                                onPressed: _loadingPromo ? null : () => _applyPromo(subtotal),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: AppColors.primary,
                                                  foregroundColor: Colors.white,
                                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                  elevation: 0,
                                                ),
                                                child: _loadingPromo
                                                    ? const SizedBox(
                                                        width: 18,
                                                        height: 18,
                                                        child: CircularProgressIndicator(
                                                          strokeWidth: 2,
                                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                                        ),
                                                      )
                                                    : Text(
                                                        'cart.apply'.tr(),
                                                        style: AppTextStyles.labelMedium.copyWith(
                                                          color: Colors.white,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (_promoError != null) ...[
                                          const SizedBox(height: 6),
                                          Text(
                                            _promoError!,
                                            style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
                                          ),
                                        ],
                                      ],
                                    )
                                  : const SizedBox.shrink(),
                            ),
                          ],
                        ),
                      ),
                      Divider(
                        height: 1,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? AppColors.neutral800
                            : AppColors.neutral100,
                      ),
                      
                      // 2. Change for amount section (Only shown for Cash payment method, i.e., key: "0")
                      if (_selectedPaymentMethodKey == '0') ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.payments_outlined, color: AppColors.primary, size: 20),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text('checkout.change'.tr(), style: AppTextStyles.bodyMedium),
                                  ),
                                  Switch.adaptive(
                                    value: _showChangeInput,
                                    onChanged: (val) => setState(() {
                                      _showChangeInput = val;
                                      if (!val) _changeController.clear();
                                    }),
                                    activeColor: AppColors.primary,
                                  ),
                                ],
                              ),
                              AnimatedSize(
                                duration: const Duration(milliseconds: 250),
                                curve: Curves.easeInOut,
                                child: _showChangeInput
                                    ? Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const SizedBox(height: 6),
                                          Container(
                                            decoration: BoxDecoration(
                                              color: Theme.of(context).brightness == Brightness.dark
                                                  ? AppColors.darkBackground
                                                  : AppColors.neutral50,
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(
                                                color: Theme.of(context).brightness == Brightness.dark
                                                    ? AppColors.neutral800
                                                    : AppColors.neutral200,
                                              ),
                                            ),
                                            child: Row(
                                              children: [
                                                Expanded(
                                                  child: TextField(
                                                    controller: _changeController,
                                                    keyboardType: TextInputType.number,
                                                    style: AppTextStyles.bodyMedium,
                                                    textAlignVertical: TextAlignVertical.center,
                                                    onChanged: (val) => setState(() {}),
                                                    decoration: InputDecoration(
                                                      hintText: 'checkout.change_hint'.tr(),
                                                      hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.neutral400),
                                                      border: InputBorder.none,
                                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                                    ),
                                                  ),
                                                ),
                                                Padding(
                                                  padding: const EdgeInsets.only(right: 12),
                                                  child: Text(
                                                    'common.currency'.tr(),
                                                    style: AppTextStyles.bodyMedium.copyWith(
                                                      color: AppColors.neutral500,
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          if (change != null) ...[
                                            const SizedBox(height: 6),
                                            Row(
                                              children: [
                                                const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppColors.success),
                                                const SizedBox(width: 6),
                                                Text(
                                                  '${'checkout.change_info'.tr()}: ${NumberFormatter.formatSum(change)} ${'common.currency'.tr()}',
                                                  style: AppTextStyles.bodySmall.copyWith(
                                                    color: AppColors.success,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ],
                                      )
                                    : const SizedBox.shrink(),
                              ),
                            ],
                          ),
                        ),
                        Divider(
                          height: 1,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? AppColors.neutral800
                              : AppColors.neutral100,
                        ),
                      ],

                      // 3. Comment section
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.comment_outlined, color: AppColors.primary, size: 20),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text('checkout.comment'.tr(), style: AppTextStyles.bodyMedium),
                                ),
                                Switch.adaptive(
                                  value: _showCommentInput,
                                  onChanged: (val) => setState(() {
                                    _showCommentInput = val;
                                    if (!val) _commentController.clear();
                                  }),
                                  activeColor: AppColors.primary,
                                ),
                              ],
                            ),
                            AnimatedSize(
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeInOut,
                              child: _showCommentInput
                                  ? Column(
                                      children: [
                                        const SizedBox(height: 6),
                                        Container(
                                          decoration: BoxDecoration(
                                            color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkBackground : AppColors.neutral50,
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(
                                              color: Theme.of(context).brightness == Brightness.dark
                                                  ? AppColors.neutral800
                                                  : AppColors.neutral200,
                                            ),
                                          ),
                                          child: TextField(
                                            controller: _commentController,
                                            maxLines: 1,
                                            style: AppTextStyles.bodyMedium,
                                            textAlignVertical: TextAlignVertical.center,
                                            decoration: InputDecoration(
                                              hintText: '${'checkout.comment'.tr()}...',
                                              hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.neutral400),
                                              border: InputBorder.none,
                                              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                                            ),
                                          ),
                                        ),
                                      ],
                                    )
                                  : const SizedBox.shrink(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ── Order Summary ─────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildRow('cart.subtotal'.tr(), NumberFormatter.formatSum(subtotal)),
                      if (_isDelivery) ...[
                        const SizedBox(height: 12),
                        _buildRow(
                          'cart.delivery'.tr(),
                          _loadingDelivery
                              ? 'checkout.calculating'.tr()
                              : '${NumberFormatter.formatSum(delivery)} ${'common.currency'.tr()}',
                        ),
                      ],
                      if (discount > 0) ...[
                        const SizedBox(height: 12),
                        _buildRow('cart.discount'.tr(), '- ${NumberFormatter.formatSum(discount)} ${'common.currency'.tr()}',
                            isDiscount: true),
                      ],
                      const Divider(height: 28, color: AppColors.neutral100),
                      _buildRow('cart.total'.tr(), '${NumberFormatter.formatSum(total)} ${'common.currency'.tr()}', isTotal: true),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -4))],
        ),
        child: SafeArea(
          child: SizedBox(
            height: 54,
            width: double.infinity,
            child: BlocBuilder<HomeCubit, HomeState>(
              builder: (context, homeState) {
                final canOrder = homeState is HomeLoaded ? (homeState.settings?.canOrder ?? true) : true;
                return ElevatedButton(
                  onPressed: (!canOrder || (_isDelivery && _loadingDelivery) || _isSubmitting) ? null : _onConfirm,
                  style: !canOrder ? ElevatedButton.styleFrom(
                    backgroundColor: AppColors.neutral300,
                  ) : null,
                  child: _isSubmitting
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text('checkout.confirm'.tr()),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  void _onConfirm() async {
    // 1. Validation
    if (_isDelivery) {
      if (_addressController.text.isEmpty) {
        _showError('checkout.select_address'.tr());
        return;
      }
      if (_deliveryPrice == null) {
        _showError('checkout.calculating'.tr());
        return;
      }
    } else {
      if (_selectedBranch == null) {
        _showError('checkout.branch'.tr());
        return;
      }
    }

    // Check if store is open
    final homeState = context.read<HomeCubit>().state;
    if (homeState is HomeLoaded) {
      if (!(homeState.settings?.canOrder ?? true)) {
        _showError('error.order_disabled'.tr());
        return;
      }
    }

    setState(() => _isSubmitting = true);

    try {
      final cartState = context.read<CartCubit>().state;
      
      final productsJson = cartState.items.map((item) {
        final variantId = item.variant?.id ?? item.product.variants.firstOrNull?.id;
        return {
          'variant_id': variantId ?? 0,
          'quantity': item.quantity,
        };
      }).toList();

      const mutation = r'''
        mutation createOrder(
          $type: Int!,
          $branch_id: Int,
          $latitude: Float,
          $longitude: Float,
          $payment_method: Int!,
          $products: [OrderProductInput!]!,
          $promo_code: String,
          $comment: String,
          $address: String,
          $change: Int
        ) {
          createOrder(
            type: $type,
            branch_id: $branch_id,
            latitude: $latitude,
            longitude: $longitude,
            payment_method: $payment_method,
            products: $products,
            promo_code: $promo_code,
            comment: $comment,
            address: $address,
            change: $change
          ) {
            order_id
            status
            payment_url
          }
        }
      ''';

      final result = await _gqlClient.mutate(MutationOptions(
        document: gql(mutation),
        operationName: 'createOrder',
        variables: {
          'type': _isDelivery ? 0 : 1,
          'branch_id': _isDelivery ? null : _selectedBranch?.id,
          'latitude': _isDelivery ? _lat : null,
          'longitude': _isDelivery ? _lng : null,
          'payment_method': _getPaymentMethodId(_selectedPaymentMethodKey),
          'products': productsJson,
          'promo_code': _showPromoInput ? _appliedPromoCode : null,
          'comment': _showCommentInput ? _commentController.text.trim() : null,
          'address': _isDelivery ? _addressController.text.trim() : null,
          'change': _showChangeInput ? (int.tryParse(_changeController.text.trim()) ?? 0) : null,
        },
      ));

      if (result.hasException) {
        final msg = result.exception?.graphqlErrors.firstOrNull?.message ?? 
                    result.exception?.linkException?.toString() ?? 
                    'error.server'.tr();
        _showError(msg);
        return;
      }

      // Success
      final orderData = result.data?['createOrder'];
      final paymentUrl = orderData?['payment_url'] as String?;

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
        context.read<CartCubit>().clear();
        context.go('/orders');
      }
      
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('checkout.order_placed'.tr()),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: AppColors.error,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Widget _sectionLabel(String text) =>
      Text(text, style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w700));

  Widget _buildToggleItem({
    required String title,
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? Theme.of(context).cardColor : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isActive
                ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))]
                : null,
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: isActive ? AppColors.primary : AppColors.neutral600),
              const SizedBox(width: 6),
              Text(
                title,
                style: AppTextStyles.labelMedium.copyWith(
                  color: isActive ? AppColors.primary : AppColors.neutral600,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardField({required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.neutral100),
      ),
      child: child,
    );
  }

  Widget _buildRow(String label, String value, {bool isTotal = false, bool isDiscount = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: isTotal
              ? AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w700)
              : AppTextStyles.bodyMedium.copyWith(color: AppColors.neutral400),
        ),
        Text(
          value,
          style: isTotal
              ? AppTextStyles.h2.copyWith(color: AppColors.primary)
              : isDiscount
                  ? AppTextStyles.labelSmall.copyWith(color: AppColors.success, fontWeight: FontWeight.w600)
                  : AppTextStyles.labelSmall.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class CheckoutBranch {
  final int id;
  final String title;
  final String address;
  final double? latitude;
  final double? longitude;

  CheckoutBranch({
    required this.id,
    required this.title,
    required this.address,
    this.latitude,
    this.longitude,
  });

  factory CheckoutBranch.fromJson(Map<String, dynamic> json) {
    return CheckoutBranch(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      title: json['title'] as String? ?? '',
      address: json['address'] as String? ?? json['title'] as String? ?? '',
      latitude: double.tryParse(json['latitude']?.toString() ?? ''),
      longitude: double.tryParse(json['longitude']?.toString() ?? ''),
    );
  }
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}
