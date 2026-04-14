import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pizza_strada/core/di/injection.dart';
import 'package:pizza_strada/core/theme/app_colors.dart';
import 'package:pizza_strada/core/theme/app_text_styles.dart';
import 'package:pizza_strada/core/theme/app_icons.dart';
import 'package:pizza_strada/features/orders/domain/entities/order_entity.dart';
import 'package:pizza_strada/features/orders/presentation/bloc/order_cubit.dart';
import 'package:cached_network_image/cached_network_image.dart';

class OrdersPage extends StatelessWidget {
  const OrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<OrderCubit>()..getOrders(),
      child: Scaffold(
        backgroundColor: AppColors.surface,
        appBar: AppBar(
          title: Text('orders.title'.tr(), style: AppTextStyles.h2.copyWith(color: AppColors.neutral900)),
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
        ),
        body: BlocBuilder<OrderCubit, OrderState>(
          builder: (context, state) {
            if (state is OrderLoading) {
              return const Center(child: CircularProgressIndicator(color: AppColors.primary));
            } else if (state is OrderFailure) {
              return Center(child: Text(state.message, style: AppTextStyles.bodyMedium));
            } else if (state is OrderLoaded) {
              if (state.orders.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(AppIcons.noOrders, size: 64, color: AppColors.neutral200),
                      const SizedBox(height: 16),
                      Text('orders.empty'.tr(), style: AppTextStyles.bodyLarge.copyWith(color: AppColors.neutral400)),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                itemCount: state.orders.length,
                itemBuilder: (context, index) {
                  final order = state.orders[index];
                  return OrderCard(order: order);
                },
              );
            }
            return const SizedBox();
          },
        ),
      ),
    );
  }
}

class OrderCard extends StatelessWidget {
  final OrderEntity order;
  const OrderCard({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    // Determine status color
    Color statusColor = AppColors.neutral700;
    if (order.status == 6) statusColor = Colors.green; // Completed
    if (order.status == 1) statusColor = Colors.red; // Rejected
    if (order.status == 4) statusColor = Colors.orange; // In Progress

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: ID and Status
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '#${order.id}',
                      style: AppTextStyles.h4.copyWith(color: AppColors.neutral900),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      order.type ?? '',
                      style: AppTextStyles.bodyExtraSmall.copyWith(color: AppColors.neutral500),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    order.statusText,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.neutral100),

          // Details: Branch or Address
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (order.branch != null) ...[
                  Row(
                    children: [
                      const Icon(Icons.store_rounded, size: 16, color: AppColors.neutral400),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          order.branch!,
                          style: AppTextStyles.bodySmall.copyWith(color: AppColors.neutral700),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
                if (order.address != null) ...[
                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded, size: 16, color: AppColors.neutral400),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          order.address!,
                          style: AppTextStyles.bodySmall.copyWith(color: AppColors.neutral700),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // Items Summary (Simplified list to avoid overflow)
          if (order.products.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: order.products.take(3).map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CachedNetworkImage(
                          imageUrl: item.image,
                          width: 32,
                          height: 32,
                          fit: BoxFit.cover,
                          errorWidget: (context, url, error) => Container(
                            color: AppColors.neutral100,
                            child: const Icon(Icons.image_not_supported_outlined, size: 16),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          item.title,
                          style: AppTextStyles.bodySmall.copyWith(color: AppColors.neutral800),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'x${item.quantity}',
                        style: AppTextStyles.labelSmall.copyWith(color: AppColors.neutral600),
                      ),
                    ],
                  ),
                )).toList(),
              ),
            ),
          
          if (order.products.length > 3)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Text(
                '+ ${order.products.length - 3} more items',
                style: AppTextStyles.bodyExtraSmall.copyWith(color: AppColors.neutral400),
              ),
            ),

          const SizedBox(height: 8),
          const Divider(height: 1, color: AppColors.neutral100),

          // Total Price
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'cart.total'.tr(),
                      style: AppTextStyles.bodyExtraSmall.copyWith(color: AppColors.neutral500),
                    ),
                    Text(
                      '${order.totalPrice.toInt()} sum',
                      style: AppTextStyles.h4.copyWith(color: AppColors.primary),
                    ),
                  ],
                ),
                if (order.paymentUrl != null && order.status != 6 && order.status != 1)
                  ElevatedButton(
                    onPressed: () {}, // Payment logic
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      elevation: 0,
                    ),
                    child: const Text('Pay'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
