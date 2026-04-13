import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pizza_strada/core/di/injection.dart';
import 'package:pizza_strada/core/theme/app_colors.dart';
import 'package:pizza_strada/core/theme/app_text_styles.dart';
import 'package:pizza_strada/core/theme/app_icons.dart';
import 'package:pizza_strada/features/orders/presentation/bloc/order_cubit.dart';
import 'package:pizza_strada/features/orders/domain/entities/order_entity.dart';
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
          title: Text("Заказы", style: AppTextStyles.h2.copyWith(color: AppColors.neutral900)),
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
                      Text("У вас пока нет заказов", style: AppTextStyles.bodyLarge.copyWith(color: AppColors.neutral400)),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                itemCount: state.orders.length,
                itemBuilder: (context, index) {
                  final order = state.orders[index];
                  return _OrderCard(order: order);
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

class _OrderCard extends StatelessWidget {
  final OrderEntity order;
  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.neutral200),
      ),
      child: InkWell(
        onTap: () => context.push('/order/${order.number}'),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: #OrderNumber and Status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("#${order.number}", style: AppTextStyles.labelLarge.copyWith(color: AppColors.neutral900, fontWeight: FontWeight.w700)),
                  _buildStatusBadge(order.status),
                ],
              ),
              const SizedBox(height: 16),
              
              // Product entries
              ...order.products.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.neutral100),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CachedNetworkImage(
                          imageUrl: item.product.thumbnail,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => const Icon(AppIcons.pizza, size: 24, color: AppColors.neutral200),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.product.title, style: AppTextStyles.labelSmall.copyWith(color: AppColors.neutral900)),
                          if (item.variant != null)
                            Text(item.variant!.title, style: AppTextStyles.bodySmall.copyWith(color: AppColors.neutral600)),
                          Text(
                            "${item.quantity} x ${item.price.toInt()} so'm",
                            style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
              
              const Divider(height: 24, color: AppColors.neutral100),

              // Bottom info: Type, Payment, Total
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Olib ketish • Naqd",
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.neutral600),
                  ),
                  Text(
                    "${order.total.toInt()} so'm",
                    style: AppTextStyles.labelLarge.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bgColor;
    Color textColor;
    String text;
    
    switch (status.toLowerCase()) {
      case 'completed':
        bgColor = AppColors.neutral100;
        textColor = AppColors.neutral600;
        text = "Tugallangan";
        break;
      case 'rejected':
      case 'cancelled':
      case 'rad etilgan':
        bgColor = AppColors.error.withOpacity(0.1);
        textColor = AppColors.error;
        text = "Rad etilgan";
        break;
      default:
        bgColor = AppColors.info.withOpacity(0.1);
        textColor = AppColors.info;
        text = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: AppTextStyles.labelSmall.copyWith(color: textColor, fontSize: 11),
      ),
    );
  }
}
