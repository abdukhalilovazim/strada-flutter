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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Status rang — Laravel `status-1`..`status-7` ga mos
    Color statusColor = AppColors.neutral500;
    switch (order.status) {
      case 1: statusColor = const Color(0xFFEF4444); break; // Bekor qilindi — qizil
      case 2: statusColor = const Color(0xFFF59E0B); break; // Yangi
      case 3: statusColor = const Color(0xFF3B82F6); break; // Qabul qilindi
      case 4: statusColor = const Color(0xFFF97316); break; // Tayyorlanmoqda
      case 5: statusColor = const Color(0xFF8B5CF6); break; // Yetkazilmoqda
      case 6: statusColor = const Color(0xFF10B981); break; // Bajarildi — yashil
      case 7: statusColor = AppColors.neutral500; break;    // Arxiv
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.neutral800 : AppColors.neutral200,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.1 : 0.04),
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
                      color: statusColor.withValues(alpha: 0.1),
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
