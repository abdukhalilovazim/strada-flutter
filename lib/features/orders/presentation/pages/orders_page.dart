import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pizza_strada/core/di/injection.dart';
import 'package:pizza_strada/core/theme/app_colors.dart';
import 'package:pizza_strada/core/theme/app_text_styles.dart';
import 'package:pizza_strada/core/theme/app_icons.dart';
import 'package:pizza_strada/features/orders/domain/entities/order_entity.dart';
import 'package:pizza_strada/features/orders/presentation/bloc/order_cubit.dart';
import 'package:pizza_strada/core/utils/number_formatter.dart';

class OrdersPage extends StatelessWidget {
  const OrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<OrderCubit>()..getOrders(),
      child: Scaffold(
        backgroundColor: AppColors.surface,
        appBar: AppBar(
          title: Text(
            'orders.title'.tr(), 
            style: AppTextStyles.h2.copyWith(
              color: Theme.of(context).textTheme.headlineMedium?.color,
            ),
          ),
          backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
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

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.neutral500,
          ),
        ),
        Text(
          value,
          style: AppTextStyles.bodySmall.copyWith(
            color: Theme.of(context).textTheme.bodyMedium?.color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

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
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => context.push('/order/${order.id}', extra: order),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: ID and Status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '#${order.id}',
                    style: AppTextStyles.h4.copyWith(
                      color: Theme.of(context).textTheme.headlineMedium?.color,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      order.statusText.startsWith('orders.status_')
                          ? order.statusText.tr()
                          : order.statusText,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Info rows: Type, Branch, Payment Method, Items count
              if (order.type != null && order.type!.isNotEmpty) ...[
                _buildInfoRow(context, 'orders.type'.tr(), order.type!),
                const SizedBox(height: 8),
              ],
              if (order.branch != null && order.branch!.isNotEmpty) ...[
                _buildInfoRow(context, 'orders.branch'.tr(), order.branch!),
                const SizedBox(height: 8),
              ],
              if (order.paymentMethodText != null && order.paymentMethodText!.isNotEmpty) ...[
                _buildInfoRow(context, 'orders.payment_method'.tr(), order.paymentMethodText!),
                const SizedBox(height: 8),
              ],
              _buildInfoRow(
                context,
                'orders.items'.tr(),
                'orders.items_count'.tr(namedArgs: {'count': order.products.length.toString()}),
              ),

              const Divider(height: 24, color: AppColors.neutral100),

              // Bottom Price & Chevron indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'cart.total'.tr(),
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.neutral500,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${NumberFormatter.formatSum(order.totalPrice)} ${'common.currency'.tr()}',
                        style: AppTextStyles.h4.copyWith(color: AppColors.primary),
                      ),
                    ],
                  ),
                  const Icon(Icons.chevron_right_rounded, color: AppColors.neutral300),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
