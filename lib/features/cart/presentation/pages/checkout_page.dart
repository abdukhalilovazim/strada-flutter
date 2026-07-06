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
import 'package:pizza_strada/features/loyalty/presentation/bloc/loyalty_cubit.dart';
import 'package:go_router/go_router.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:pizza_strada/core/network/graphql_client.dart';
import 'package:url_launcher/url_launcher.dart';

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

  @override
  void initState() {
    super.initState();
    _loadBranches();
    
    // Defer reading context until after build if needed, but safe here if we just read state
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
      final client = buildGraphQLClient();
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
      
      final result = await client.query(QueryOptions(
        document: gql(query),
        operationName: 'Branches',
        fetchPolicy: FetchPolicy.networkOnly,
      ));

      if (!result.hasException && result.data?['branches'] != null) {
        final list = result.data?['branches'] as List;
        setState(() {
          _branches = list.map((e) => CheckoutBranch.fromJson(e)).toList();
          if (_branches.isNotEmpty && context.read<CheckoutCubit>().state.branchId == null) {
            context.read<CheckoutCubit>().setBranch(_branches.first.id);
          }
        });
      }
    } catch (_) {} finally {
      if (mounted) setState(() => _isLoadingBranches = false);
    }
  }

  void _showBranchPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Container(
          padding: const EdgeInsets.only(top: 20),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('checkout.select_branch'.tr(), style: AppTextStyles.h3),
              const SizedBox(height: 16),
              if (_isLoadingBranches)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                    itemCount: _branches.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final branch = _branches[i];
                      final isSelected = context.read<CheckoutCubit>().state.branchId == branch.id;
                      return ListTile(
                        contentPadding: EdgeInsets.symmetric(horizontal: 20),
                        title: Text(
                          branch.title,
                          style: AppTextStyles.labelMedium.copyWith(
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected ? AppColors.primary : Theme.of(context).textTheme.bodyMedium?.color,
                          ),
                        ),
                        trailing: isSelected ? const Icon(Icons.check_circle_rounded, color: AppColors.primary) : null,
                        onTap: () {
                          context.read<CheckoutCubit>().setBranch(branch.id);
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

  int _getPaymentMethodId(String key) {
    final cleanKey = key.toLowerCase().trim();
    if (cleanKey == 'payme' || cleanKey == '1') return 1;
    if (cleanKey == 'click' || cleanKey == '2') return 2;
    return 0; // Default Cash
  }

  double _computeDiscount(CheckoutState state, double subtotal) {
    if (!state.useLoyaltyPoints && state.appliedPromoCode == null) return 0;
    
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
        
        // Loyalty calculation
        int usedPoints = 0;
        final loyaltyState = context.read<LoyaltyCubit>().state;
        if (checkoutState.useLoyaltyPoints && loyaltyState is LoyaltyLoaded) {
          final maxAllowed = (subtotal + checkoutState.deliveryPrice - discount).toInt();
          usedPoints = loyaltyState.loyalty.points > maxAllowed ? maxAllowed : loyaltyState.loyalty.points;
        }

        final finalTotal = (subtotal + checkoutState.deliveryPrice - discount - usedPoints).clamp(0, double.infinity);

        return Scaffold(
          backgroundColor: AppColors.surface,
          appBar: AppBar(
            title: Text('checkout.title'.tr(), style: AppTextStyles.h2.copyWith(color: Theme.of(context).textTheme.headlineMedium?.color)),
            centerTitle: true,
            backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios_new_rounded, color: Theme.of(context).iconTheme.color),
              onPressed: () => context.pop(),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Delivery Type
                Text('checkout.delivery_type'.tr(), style: AppTextStyles.h3.copyWith(color: Theme.of(context).textTheme.headlineMedium?.color)),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.neutral200),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => context.read<CheckoutCubit>().setDeliveryType(true),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: checkoutState.isDelivery ? AppColors.primaryLight : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.center,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.moped_rounded, color: checkoutState.isDelivery ? AppColors.primary : AppColors.neutral500, size: 20),
                                const SizedBox(width: 8),
                                Text('checkout.delivery'.tr(), style: AppTextStyles.labelMedium.copyWith(color: checkoutState.isDelivery ? AppColors.primary : AppColors.neutral500)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => context.read<CheckoutCubit>().setDeliveryType(false),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: !checkoutState.isDelivery ? AppColors.primaryLight : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.center,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.storefront_rounded, color: !checkoutState.isDelivery ? AppColors.primary : AppColors.neutral500, size: 20),
                                const SizedBox(width: 8),
                                Text('checkout.pickup'.tr(), style: AppTextStyles.labelMedium.copyWith(color: !checkoutState.isDelivery ? AppColors.primary : AppColors.neutral500)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Address or Branch
                Text(checkoutState.isDelivery ? 'checkout.address'.tr() : 'checkout.branch'.tr(), style: AppTextStyles.h3.copyWith(color: Theme.of(context).textTheme.headlineMedium?.color)),
                const SizedBox(height: 12),
                if (checkoutState.isDelivery)
                  InkWell(
                    onTap: () async {
                      final result = await context.push<Map<String, dynamic>>('/map-picker');
                      if (result != null) {
                        if (!context.mounted) return;
                        final lat = result['lat'] as double?;
                        final lng = result['lng'] as double?;
                        final addr = result['address'] as String;
                        if (lat != null && lng != null) {
                          context.read<CheckoutCubit>().setAddressAndCalculateDelivery(lat, lng, addr);
                        } else {
                          // Handle manual address if fallback implemented
                        }
                      }
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.neutral200),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.location_on_rounded, color: AppColors.primary),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              checkoutState.address ?? 'checkout.select_address'.tr(),
                              style: checkoutState.address != null ? AppTextStyles.bodyMedium.copyWith(color: Theme.of(context).textTheme.bodyMedium?.color) : AppTextStyles.bodyMedium.copyWith(color: AppColors.neutral500),
                            ),
                          ),
                          if (checkoutState.loadingDelivery)
                            const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          else
                            const Icon(Icons.chevron_right_rounded, color: AppColors.neutral400),
                        ],
                      ),
                    ),
                  )
                else
                  InkWell(
                    onTap: _showBranchPicker,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.neutral200),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.storefront_rounded, color: AppColors.primary),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _branches.cast<CheckoutBranch?>().firstWhere((b) => b?.id == checkoutState.branchId, orElse: () => null)?.title ?? 'checkout.branch'.tr(),
                              style: AppTextStyles.bodyMedium.copyWith(color: Theme.of(context).textTheme.bodyMedium?.color),
                            ),
                          ),
                          if (_isLoadingBranches)
                            const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          else
                            const Icon(Icons.chevron_right_rounded, color: AppColors.neutral400),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 24),

                // Loyalty Points
                BlocBuilder<LoyaltyCubit, LoyaltyState>(
                  builder: (context, state) {
                    if (state is LoyaltyLoaded && state.loyalty.points > 0) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('checkout.loyalty_points'.tr(), style: AppTextStyles.h3.copyWith(color: Theme.of(context).textTheme.headlineMedium?.color)),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.stars_rounded, color: AppColors.primary, size: 28),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('${state.loyalty.points} ${'checkout.points_available'.tr()}', style: AppTextStyles.labelMedium.copyWith(color: Theme.of(context).textTheme.bodyMedium?.color)),
                                      Text('checkout.use_points_for_discount'.tr(), style: AppTextStyles.bodySmall.copyWith(color: AppColors.neutral500)),
                                    ],
                                  ),
                                ),
                                Switch.adaptive(
                                  value: checkoutState.useLoyaltyPoints,
                                  onChanged: (val) => context.read<CheckoutCubit>().toggleLoyaltyPoints(val),
                                  activeTrackColor: AppColors.primary,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),

                // Payment method
                Text('checkout.payment'.tr(), style: AppTextStyles.h3.copyWith(color: Theme.of(context).textTheme.headlineMedium?.color)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.neutral200),
                  ),
                  child: Row(
                    children: [
                      for (int i = 0; i < paymentMethods.take(3).length; i++) ...[
                        if (i > 0) const SizedBox(width: 8),
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              context.read<CheckoutCubit>().setPaymentMethod(paymentMethods[i].key);
                              if (paymentMethods[i].key != '0') {
                                setState(() {
                                  _showChangeInput = false;
                                  _changeController.clear();
                                });
                                context.read<CheckoutCubit>().setChangeAmount(null);
                              }
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              height: 48,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: checkoutState.selectedPaymentMethodKey == paymentMethods[i].key
                                    ? AppColors.primaryLight
                                    : Colors.transparent,
                                border: Border.all(
                                  color: checkoutState.selectedPaymentMethodKey == paymentMethods[i].key
                                      ? AppColors.primary
                                      : AppColors.neutral200,
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
                                    color: checkoutState.selectedPaymentMethodKey == paymentMethods[i].key
                                        ? AppColors.primary
                                        : AppColors.neutral600,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      paymentMethods[i].value,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTextStyles.labelSmall.copyWith(
                                        color: checkoutState.selectedPaymentMethodKey == paymentMethods[i].key
                                            ? AppColors.primary
                                            : Theme.of(context).textTheme.bodyMedium?.color,
                                        fontWeight: checkoutState.selectedPaymentMethodKey == paymentMethods[i].key ? FontWeight.bold : FontWeight.w500,
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
                const SizedBox(height: 24),

                // Additional Information (Promo, Change, Comment)
                Text('checkout.additional'.tr(), style: AppTextStyles.h3.copyWith(color: Theme.of(context).textTheme.headlineMedium?.color)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.neutral200),
                  ),
                  child: Column(
                    children: [
                      // Promo Code
                      Row(
                        children: [
                          const Icon(Icons.local_offer_outlined, color: AppColors.primary, size: 20),
                          const SizedBox(width: 12),
                          Expanded(child: Text('cart.promo'.tr(), style: AppTextStyles.bodyMedium.copyWith(color: Theme.of(context).textTheme.bodyMedium?.color))),
                          Switch.adaptive(
                            value: _showPromoInput,
                            onChanged: (val) {
                              setState(() => _showPromoInput = val);
                              if (!val) {
                                _promoController.clear();
                                context.read<CheckoutCubit>().clearPromo();
                              }
                            },
                            activeTrackColor: AppColors.primary,
                          ),
                        ],
                      ),
                      if (_showPromoInput) ...[
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _promoController,
                                style: AppTextStyles.bodyMedium.copyWith(color: Theme.of(context).textTheme.bodyMedium?.color),
                                textCapitalization: TextCapitalization.characters,
                                decoration: InputDecoration(
                                  hintText: 'cart.enter_promo'.tr(),
                                  filled: true,
                                  fillColor: AppColors.surface,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  errorText: checkoutState.promoError,
                                ),
                              ),
                            ),
                            if (checkoutState.loadingPromo)
                              const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                            else
                              TextButton(
                                onPressed: () {
                                  context.read<CheckoutCubit>().applyPromo(_promoController.text.trim().toUpperCase(), subtotal);
                                  FocusScope.of(context).unfocus();
                                },
                                child: Text('cart.apply'.tr(), style: AppTextStyles.labelMedium.copyWith(color: AppColors.primary)),
                              ),
                          ],
                        ),
                      ],
                      const Divider(height: 16),

                      // Change Amount (Only if Cash is selected)
                      if (checkoutState.selectedPaymentMethodKey == '0') ...[
                        Row(
                          children: [
                            const Icon(Icons.payments_outlined, color: AppColors.primary, size: 20),
                            const SizedBox(width: 12),
                            Expanded(child: Text('checkout.change_from'.tr(), style: AppTextStyles.bodyMedium.copyWith(color: Theme.of(context).textTheme.bodyMedium?.color))),
                            Switch.adaptive(
                              value: _showChangeInput,
                              onChanged: (val) {
                                setState(() => _showChangeInput = val);
                                if (!val) {
                                  _changeController.clear();
                                  context.read<CheckoutCubit>().setChangeAmount(null);
                                }
                              },
                              activeTrackColor: AppColors.primary,
                            ),
                          ],
                        ),
                        if (_showChangeInput) ...[
                          TextField(
                            controller: _changeController,
                            keyboardType: TextInputType.number,
                            style: AppTextStyles.bodyMedium.copyWith(color: Theme.of(context).textTheme.bodyMedium?.color),
                            onChanged: (val) => context.read<CheckoutCubit>().setChangeAmount(double.tryParse(val)),
                            decoration: InputDecoration(
                              hintText: 'checkout.enter_amount'.tr(),
                              filled: true,
                              fillColor: AppColors.surface,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                          ),
                        ],
                        const Divider(height: 16),
                      ],

                      // Comment
                      Row(
                        children: [
                          const Icon(Icons.chat_bubble_outline_rounded, color: AppColors.primary, size: 20),
                          const SizedBox(width: 12),
                          Expanded(child: Text('checkout.comment'.tr(), style: AppTextStyles.bodyMedium.copyWith(color: Theme.of(context).textTheme.bodyMedium?.color))),
                          Switch.adaptive(
                            value: _showCommentInput,
                            onChanged: (val) {
                              setState(() => _showCommentInput = val);
                              if (!val) {
                                _commentController.clear();
                                context.read<CheckoutCubit>().setComment('');
                              }
                            },
                            activeTrackColor: AppColors.primary,
                          ),
                        ],
                      ),
                      if (_showCommentInput) ...[
                        TextField(
                          controller: _commentController,
                          maxLines: 3,
                          style: AppTextStyles.bodyMedium.copyWith(color: Theme.of(context).textTheme.bodyMedium?.color),
                          onChanged: (val) => context.read<CheckoutCubit>().setComment(val),
                          decoration: InputDecoration(
                            hintText: 'checkout.comment_hint'.tr(),
                            filled: true,
                            fillColor: AppColors.surface,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                
                // Detailed Breakdown
                _buildPriceRow('cart.subtotal'.tr(), subtotal, isTotal: false),
                if (checkoutState.isDelivery) ...[
                  const SizedBox(height: 8),
                  _buildPriceRow('cart.delivery'.tr(), checkoutState.deliveryPrice, isTotal: false),
                ],
                if (discount > 0) ...[
                  const SizedBox(height: 8),
                  _buildPriceRow('cart.promo'.tr(), -discount, isTotal: false, isDiscount: true),
                ],
                if (usedPoints > 0) ...[
                  const SizedBox(height: 8),
                  _buildPriceRow('checkout.loyalty_discount'.tr(), -usedPoints.toDouble(), isTotal: false, isDiscount: true),
                ],
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(),
                ),
                _buildPriceRow('cart.total'.tr(), finalTotal.toDouble(), isTotal: true),
                const SizedBox(height: 80),
              ],
            ),
          ),
          bottomNavigationBar: Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -4))],
            ),
            child: SafeArea(
              child: ElevatedButton(
                onPressed: (checkoutState.isSubmitting || cartState.items.isEmpty || (checkoutState.isDelivery ? checkoutState.address == null || checkoutState.deliveryPrice <= 0 : checkoutState.branchId == null))
                    ? null
                    : () {
                        final products = cartState.items.map((item) {
                          final variantId = item.variant?.id ?? item.product.variants.firstOrNull?.id;
                          return {
                            'variant_id': variantId ?? 0,
                            'quantity': item.quantity,
                          };
                        }).toList();
                        context.read<CheckoutCubit>().submitOrder(products: products, usedPoints: usedPoints);
                      },
                child: checkoutState.isSubmitting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text('checkout.submit_order'.tr()),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPriceRow(String label, double value, {bool isTotal = false, bool isDiscount = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: isTotal
              ? AppTextStyles.h3.copyWith(color: Theme.of(context).textTheme.headlineMedium?.color)
              : AppTextStyles.bodyMedium.copyWith(color: AppColors.neutral600),
        ),
        Text(
          value == 0 && !isTotal ? 'checkout.free'.tr() : NumberFormatter.formatSum(value.toInt()),
          style: isTotal
              ? AppTextStyles.h3.copyWith(color: Theme.of(context).textTheme.headlineMedium?.color)
              : AppTextStyles.labelMedium.copyWith(color: isDiscount ? AppColors.error : Theme.of(context).textTheme.bodyMedium?.color),
        ),
      ],
    );
  }

  void _handleSuccess(Map<String, dynamic> data) async {
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
      context.go('/orders');
    }
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
