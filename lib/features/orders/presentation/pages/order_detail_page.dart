import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pizza_strada/core/theme/app_colors.dart';
import 'package:pizza_strada/core/theme/app_text_styles.dart';
import 'package:pizza_strada/core/utils/number_formatter.dart';
import 'package:pizza_strada/features/orders/domain/entities/order_entity.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pizza_strada/features/home/presentation/bloc/home_cubit.dart';
import 'package:pizza_strada/features/cart/presentation/bloc/cart_cubit.dart';
import 'package:pizza_strada/features/home/domain/entities/home_entities.dart';

class OrderDetailPage extends StatelessWidget {
  final String orderId;
  final OrderEntity? order;

  const OrderDetailPage({super.key, required this.orderId, this.order});

  @override
  Widget build(BuildContext context) {
    if (order == null) {
      return Scaffold(
        appBar: AppBar(title: Text('#$orderId')),
        body: Center(child: Text('error.not_found'.tr())),
      );
    }

    final o = order!;
    Color statusColor = AppColors.neutral700;
    if (o.status == 6) statusColor = Colors.green;
    if (o.status == 1) statusColor = Colors.red;
    if (o.status == 4) statusColor = Colors.orange;
    final showPayNow = o.paymentUrl != null && o.status != 6 && o.status != 1;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text('#${o.id}', style: AppTextStyles.h2),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Theme.of(context).brightness == Brightness.dark ? Colors.white : AppColors.neutral900,
            size: 20,
          ),
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
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.receipt_long_rounded, color: statusColor),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          o.statusText.startsWith('orders.status_')
                              ? o.statusText.tr()
                              : o.statusText,
                          style: AppTextStyles.h4.copyWith(color: statusColor),
                        ),
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
                color: Theme.of(context).cardColor,
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
                              Text('${NumberFormatter.formatSum(item.price)} ${'common.currency'.tr()}', style: AppTextStyles.labelSmall.copyWith(color: AppColors.primary)),
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

            // Order Details Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'product.info'.tr(), 
                    style: AppTextStyles.labelLarge.copyWith(
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (o.address != null && o.address!.isNotEmpty) ...[
                    _DetailRow(label: 'checkout.address'.tr(), value: o.address!),
                    const Divider(height: 24),
                  ],
                  if (o.branch != null && o.branch!.isNotEmpty) ...[
                    _DetailRow(label: 'checkout.branch'.tr(), value: o.branch!),
                    const Divider(height: 24),
                  ],
                  if (o.paymentMethodText != null && o.paymentMethodText!.isNotEmpty) ...[
                    _DetailRow(label: 'checkout.payment'.tr(), value: o.paymentMethodText!),
                    if (o.comment != null && o.comment!.isNotEmpty) const Divider(height: 24),
                  ],
                  if (o.comment != null && o.comment!.isNotEmpty)
                    _DetailRow(label: 'checkout.comment'.tr(), value: o.comment!),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Totals
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
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
      bottomNavigationBar: (showPayNow || o.status == 6)
          ? Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                child: Builder(
                  builder: (context) {
                    if (showPayNow) {
                      return SizedBox(
                        height: 50,
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            final url = o.paymentUrl;
                            if (url != null && url.isNotEmpty) {
                              final uri = Uri.tryParse(url);
                              if (uri != null) {
                                try {
                                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                                } catch (e) {
                                  debugPrint('Could not launch payment URL: $e');
                                }
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(
                            'orders.pay_now'.tr(),
                            style: AppTextStyles.labelMedium.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    }

                    return SizedBox(
                      height: 50,
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => _handleReorder(context, o),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          'orders.reorder'.tr(),
                          style: AppTextStyles.labelMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            )
          : null,
    );
  }

  void _handleReorder(BuildContext context, OrderEntity order) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Theme.of(dialogContext).cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'orders.reorder_confirm_title'.tr(),
            style: AppTextStyles.h3.copyWith(
              color: Theme.of(dialogContext).textTheme.headlineMedium?.color,
            ),
          ),
          content: Text(
            'orders.reorder_confirm_desc'.tr(),
            style: AppTextStyles.bodyMedium.copyWith(
              color: Theme.of(dialogContext).textTheme.bodyMedium?.color,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                'common.no'.tr(),
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.neutral600,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                _executeReorder(context, order);
              },
              child: Text(
                'common.yes'.tr(),
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _executeReorder(BuildContext context, OrderEntity order) {
    final homeState = context.read<HomeCubit>().state;
    if (homeState is! HomeLoaded) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('orders.reorder_error'.tr()),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final fullProducts = homeState.fullProducts;
    bool someFailed = false;

    // Clear cart first
    context.read<CartCubit>().clear();

    for (final orderItem in order.products) {
      // Find matching product
      final matchedProductList = fullProducts.where((p) => p.slug == orderItem.slug);
      if (matchedProductList.isEmpty) {
        someFailed = true;
        continue;
      }
      final matchedProduct = matchedProductList.first;

      VariantEntity? matchedVariant;
      if (orderItem.variantName != null) {
        final matchedVariantList = matchedProduct.variants.where((v) => v.title == orderItem.variantName);
        if (matchedVariantList.isEmpty) {
          someFailed = true;
          continue;
        }
        matchedVariant = matchedVariantList.first;
      }

      // Add to cart with correct quantity
      for (int i = 0; i < orderItem.quantity; i++) {
        context.read<CartCubit>().addToCart(matchedProduct, variant: matchedVariant);
      }
    }

    if (someFailed) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('orders.reorder_error'.tr()),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('orders.reorder_success'.tr()),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }

    // Go to cart
    context.go('/cart');
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
        Text(label, style: isTotal ? AppTextStyles.labelLarge.copyWith(color: Theme.of(context).textTheme.bodyLarge?.color) : AppTextStyles.bodyMedium.copyWith(color: AppColors.neutral500)),
        Text(
          "${isNegative ? '- ' : ''}${NumberFormatter.formatSum(price)} ${'common.currency'.tr()}",
          style: isTotal
            ? AppTextStyles.h4.copyWith(color: AppColors.primary)
            : AppTextStyles.labelSmall.copyWith(color: Theme.of(context).textTheme.bodySmall?.color),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.neutral500),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: AppTextStyles.labelSmall.copyWith(
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
        ),
      ],
    );
  }
}
