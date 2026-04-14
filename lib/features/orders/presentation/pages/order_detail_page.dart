import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pizza_strada/core/theme/app_colors.dart';
import 'package:pizza_strada/core/theme/app_text_styles.dart';
import 'package:pizza_strada/features/orders/domain/entities/order_entity.dart';
import 'package:cached_network_image/cached_network_image.dart';

class OrderDetailPage extends StatelessWidget {
  final String orderId;
  final OrderEntity? order;

  const OrderDetailPage({super.key, required this.orderId, this.order});

  @override
  Widget build(BuildContext context) {
    if (order == null) {
      return Scaffold(
        appBar: AppBar(title: Text('#$orderId')),
        body: const Center(child: Text('Order details not found')),
      );
    }

    final o = order!;
    Color statusColor = AppColors.neutral700;
    if (o.status == 6) statusColor = Colors.green;
    if (o.status == 1) statusColor = Colors.red;
    if (o.status == 4) statusColor = Colors.orange;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text('#${o.id}', style: AppTextStyles.h2),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.neutral900),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Status Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.receipt_long_rounded, color: statusColor),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(o.statusText, style: AppTextStyles.h4.copyWith(color: statusColor)),
                        Text(o.type ?? '', style: AppTextStyles.bodySmall.copyWith(color: AppColors.neutral500)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Products List
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('orders.items'.tr(), style: AppTextStyles.labelLarge),
                  const SizedBox(height: 16),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: o.products.length,
                    separatorBuilder: (_, __) => const Divider(height: 24),
                    itemBuilder: (_, i) {
                      final item = o.products[i];
                      return Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: CachedNetworkImage(
                              imageUrl: item.image,
                              width: 56,
                              height: 56,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.title, style: AppTextStyles.labelSmall),
                                if (item.variantName != null)
                                  Text(item.variantName!, style: AppTextStyles.bodyExtraSmall.copyWith(color: AppColors.neutral500)),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('x${item.quantity}', style: AppTextStyles.bodySmall),
                              Text('${item.price.toInt()} sum', style: AppTextStyles.labelSmall.copyWith(color: AppColors.primary)),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Totals
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  _PriceRow(label: 'cart.subtotal'.tr(), price: o.subtotalPrice),
                  if (o.deliveryPrice > 0)
                     Padding(
                       padding: const EdgeInsets.only(top: 12),
                       child: _PriceRow(label: 'cart.delivery'.tr(), price: o.deliveryPrice),
                     ),
                  if (o.discountAmount > 0)
                     Padding(
                       padding: const EdgeInsets.only(top: 12),
                       child: _PriceRow(label: 'cart.discount'.tr(), price: o.discountAmount, isNegative: true),
                     ),
                  const Divider(height: 32),
                  _PriceRow(label: 'cart.total'.tr(), price: o.totalPrice, isTotal: true),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: o.paymentUrl != null && o.status != 6 && o.status != 1
          ? Container(
              padding: const EdgeInsets.all(20),
              color: Colors.white,
              child: SafeArea(
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Pay Now', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            )
          : null,
    );
  }
}

class _PriceRow extends StatelessWidget {
  final String label;
  final double price;
  final bool isNegative;
  final bool isTotal;

  const _PriceRow({
    required this.label,
    required this.price,
    this.isNegative = false,
    this.isTotal = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: isTotal ? AppTextStyles.labelLarge : AppTextStyles.bodyMedium.copyWith(color: AppColors.neutral500)),
        Text(
          "${isNegative ? '-' : ''}${price.toInt()} sum",
          style: isTotal 
            ? AppTextStyles.h4.copyWith(color: AppColors.primary)
            : AppTextStyles.labelSmall.copyWith(color: AppColors.neutral900),
        ),
      ],
    );
  }
}
