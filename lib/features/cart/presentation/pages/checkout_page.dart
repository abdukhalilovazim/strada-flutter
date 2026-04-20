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
import 'package:yandex_mapkit/yandex_mapkit.dart';

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

  late GraphQLClient _gqlClient;

  @override
  void initState() {
    super.initState();
    _initClient();
  }

  void _initClient() {
    setState(() => _gqlClient = buildGraphQLClient());
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
      }
    });
  }

  // ─── Discount calculation ─────────────────────────────────────────────────
  double _computeDiscount(double subtotal) {
    if (_appliedPromoCode == null || _promoValue == null) return 0;
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
        backgroundColor: Colors.white,
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
                          final point = result['point'] as Point;
                          final address = result['address'] as String;
                          setState(() {
                            _addressController.text = address;
                          });
                          _calculateDelivery(lat: point.latitude, lng: point.longitude);
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
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                      child: Row(
                        children: [
                          const Icon(Icons.storefront_rounded, color: AppColors.primary, size: 22),
                          const SizedBox(width: 12),
                          Expanded(child: Text('Pizza Strada (Asosiy filial)', style: AppTextStyles.bodyMedium)),
                          const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.neutral400, size: 20),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 20),

                // ── Payment method + Qaytim ───────────────────────────────
                _sectionLabel('checkout.payment'.tr()),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.neutral100),
                  ),
                  child: Column(
                    children: [
                      // Cash row
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        child: Row(
                          children: [
                            const Icon(Icons.payments_outlined, color: AppColors.primary, size: 20),
                            const SizedBox(width: 12),
                            Expanded(child: Text('checkout.cash'.tr(), style: AppTextStyles.bodyMedium)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.primaryLight,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text('checkout.cash'.tr(),
                                  style: AppTextStyles.bodyExtraSmall.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w700,
                                  )),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1, color: AppColors.neutral100),
                      // Qaytim toggle row
                      Padding(
                        padding: const EdgeInsets.only(left: 16, right: 8, top: 4, bottom: 4),
                        child: Row(
                          children: [
                            const Icon(Icons.receipt_long_outlined, color: AppColors.primary, size: 20),
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
                      ),
                      // Animated input expansion
                      AnimatedSize(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeInOut,
                        child: _showChangeInput
                            ? Column(
                                children: [
                                  const Divider(height: 1, color: AppColors.neutral100),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                    child: TextField(
                                      controller: _changeController,
                                      keyboardType: TextInputType.number,
                                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                      autofocus: true,
                                      onChanged: (_) => setState(() {}),
                                      decoration: InputDecoration(
                                        hintText: 'checkout.change_hint'.tr(),
                                        hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.neutral400),
                                        border: InputBorder.none,
                                        prefixIcon: const Padding(
                                          padding: EdgeInsets.only(right: 8),
                                          child: Icon(Icons.money_rounded, color: AppColors.primary, size: 20),
                                        ),
                                        prefixIconConstraints: const BoxConstraints(minWidth: 0),
                                        suffix: Text('common.currency'.tr(),
                                            style: AppTextStyles.bodySmall.copyWith(color: AppColors.neutral500)),
                                      ),
                                    ),
                                  ),
                                  if (change != null)
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppColors.success),
                                          const SizedBox(width: 6),
                                          Text(
                                            '${'checkout.change_info'.tr()}: ${NumberFormatter.formatSum(change)} ${'common.currency'.tr()}',
                                            style: AppTextStyles.bodySmall.copyWith(
                                                color: AppColors.success, fontWeight: FontWeight.w600),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              )
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ── Promo code ────────────────────────────────────────────
                _sectionLabel('cart.promo'.tr()),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildCardField(
                        child: TextField(
                          controller: _promoController,
                          textCapitalization: TextCapitalization.characters,
                          decoration: InputDecoration(
                            hintText: 'checkout.promo_hint'.tr(),
                            hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.neutral400),
                            border: InputBorder.none,
                            prefixIcon: const Icon(Icons.local_offer_outlined, color: AppColors.primary, size: 20),
                          ),
                          onChanged: (_) {
                            if (_appliedPromoCode != null) {
                              setState(() {
                                _appliedPromoCode = null;
                                _promoType = null;
                                _promoValue = null;
                              });
                            }
                          },
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
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                        child: _loadingPromo
                            ? const SizedBox(width: 18, height: 18,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : Text('cart.apply'.tr(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                      ),
                    ),
                  ],
                ),
                if (_promoError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8, left: 4),
                    child: Text(_promoError!, style: AppTextStyles.bodySmall.copyWith(color: AppColors.error)),
                  ),
                if (_appliedPromoCode != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8, left: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          '$_appliedPromoCode — -${NumberFormatter.formatSum(_computeDiscount(subtotal))} ${'common.currency'.tr()}',
                          style: AppTextStyles.bodySmall.copyWith(color: AppColors.success, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 20),

                // ── Comment ───────────────────────────────────────────────
                _sectionLabel('checkout.comment'.tr()),
                const SizedBox(height: 8),
                _buildCardField(
                  child: TextField(
                    controller: _commentController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: '${'checkout.comment'.tr()}...',
                      hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.neutral400),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // ── Order Summary ─────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
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
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -4))],
        ),
        child: SafeArea(
          child: SizedBox(
            height: 54,
            width: double.infinity,
            child: BlocBuilder<HomeCubit, HomeState>(
              builder: (context, homeState) {
                final canOrder = homeState is HomeLoaded ? (homeState.settings?.canOrder ?? true) : true;
                return ElevatedButton(
                  onPressed: (!canOrder || (_isDelivery && _loadingDelivery)) ? null : _onConfirm,
                  style: !canOrder ? ElevatedButton.styleFrom(
                    backgroundColor: AppColors.neutral300,
                  ) : null,
                  child: Text('checkout.confirm'.tr()),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  void _onConfirm() {
    // Check if store is open
    final homeState = context.read<HomeCubit>().state;
    if (homeState is HomeLoaded) {
      if (!(homeState.settings?.canOrder ?? true)) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('error.order_disabled'.tr()),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
        return;
      }
    }

    final cartCubit = context.read<CartCubit>();
    context.go('/orders');
    cartCubit.clear();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('checkout.order_placed'.tr()),
      backgroundColor: AppColors.success,
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
            color: isActive ? Colors.white : Colors.transparent,
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
        color: Colors.white,
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
