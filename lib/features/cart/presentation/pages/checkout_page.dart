import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pizza_strada/core/theme/app_colors.dart';
import 'package:pizza_strada/core/theme/app_text_styles.dart';
import 'package:pizza_strada/features/cart/presentation/bloc/cart_cubit.dart';
import 'package:pizza_strada/features/cart/presentation/bloc/checkout/checkout_cubit.dart';
import 'package:pizza_strada/features/cart/presentation/bloc/checkout/checkout_state.dart';
import 'package:go_router/go_router.dart';
import 'package:pizza_strada/features/cart/presentation/pages/checkout_payment_page.dart';
import 'package:pizza_strada/features/home/domain/entities/home_entities.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:pizza_strada/core/network/graphql_client.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  List<CheckoutBranch> _branches = [];
  bool _isLoadingBranches = false;

  @override
  void initState() {
    super.initState();
    _loadBranches();
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

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CheckoutCubit, CheckoutState>(
      builder: (context, checkoutState) {
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
                // Progress Indicator 1/2
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle)),
                    Container(width: 40, height: 2, color: AppColors.primary, margin: const EdgeInsets.symmetric(horizontal: 4)),
                    Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.neutral300, shape: BoxShape.circle)),
                  ],
                ),
                const SizedBox(height: 8),
                Center(child: Text('checkout.step_one_title'.tr(), style: AppTextStyles.bodySmall.copyWith(color: AppColors.neutral600))),
                const SizedBox(height: 24),

                // Cart Items (Order Summary)
                Text('checkout.your_order'.tr(), style: AppTextStyles.h3.copyWith(color: Theme.of(context).textTheme.headlineMedium?.color)),
                const SizedBox(height: 16),
                BlocBuilder<CartCubit, CartState>(
                  builder: (context, cartState) {
                    if (cartState.items.isEmpty) {
                      return Center(child: Text('cart.empty'.tr(), style: AppTextStyles.bodyMedium));
                    }
                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: cartState.items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final item = cartState.items[index];
                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.neutral200),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  image: DecorationImage(image: NetworkImage(item.product.image), fit: BoxFit.cover),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item.product.title, style: AppTextStyles.labelMedium.copyWith(color: Theme.of(context).textTheme.bodyMedium?.color), maxLines: 1, overflow: TextOverflow.ellipsis),
                                    if (item.variant != null) ...[
                                      const SizedBox(height: 4),
                                      Text(item.variant!.title, style: AppTextStyles.bodySmall.copyWith(color: AppColors.neutral500)),
                                    ]
                                  ],
                                ),
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove_circle_outline, color: AppColors.primary),
                                    onPressed: () => context.read<CartCubit>().updateQuantity(item, -1),
                                  ),
                                  Text('${item.quantity}', style: AppTextStyles.labelLarge.copyWith(color: Theme.of(context).textTheme.bodyLarge?.color)),
                                  IconButton(
                                    icon: const Icon(Icons.add_circle_outline, color: AppColors.primary),
                                    onPressed: () => context.read<CartCubit>().updateQuantity(item, 1),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: 32),

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
                      if (result != null && mounted) {
                        final lat = result['lat'] as double;
                        final lng = result['lng'] as double;
                        final address = result['address'] as String;
                        context.read<CheckoutCubit>().setAddressAndCalculateDelivery(lat, lng, address);
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
              child: BlocBuilder<CartCubit, CartState>(
                builder: (context, cartState) {
                  final bool isEmpty = cartState.items.isEmpty;
                  final bool isAddressValid = checkoutState.isDelivery ? checkoutState.address != null && checkoutState.deliveryPrice > 0 : checkoutState.branchId != null;
                  
                  return ElevatedButton(
                    onPressed: (isEmpty || !isAddressValid || checkoutState.loadingDelivery) ? null : () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BlocProvider.value(
                            value: context.read<CheckoutCubit>(),
                            child: const CheckoutPaymentPage(),
                          ),
                        ),
                      );
                    },
                    style: (isEmpty || !isAddressValid) ? ElevatedButton.styleFrom(backgroundColor: AppColors.neutral300) : null,
                    child: Text(isEmpty ? 'cart.empty'.tr() : (!isAddressValid && checkoutState.isDelivery ? 'checkout.select_address'.tr() : 'checkout.continue'.tr())),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
