import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pizza_strada/core/services/analytics_service.dart';
import 'package:pizza_strada/core/theme/app_colors.dart';
import 'package:pizza_strada/core/theme/app_text_styles.dart';
import 'package:pizza_strada/core/utils/number_formatter.dart';
import 'package:pizza_strada/features/cart/presentation/bloc/cart_cubit.dart';

class CartPage extends StatelessWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'cart.title'.tr(),
          style: AppTextStyles.h2.copyWith(
            color: Theme.of(context).textTheme.headlineMedium?.color,
          ),
        ),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: isDark ? AppColors.neutral800 : AppColors.neutral200,
          ),
        ),
      ),
      body: BlocBuilder<CartCubit, CartState>(
        builder: (context, state) {
          if (state.items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.neutral800
                          : AppColors.neutral100,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.shopping_bag_outlined,
                      size: 48,
                      color: AppColors.neutral400,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'cart.empty'.tr(),
                    style: AppTextStyles.h3.copyWith(
                      color: Theme.of(context).textTheme.headlineMedium?.color,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'cart.empty_subtitle'.tr(),
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.neutral500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: 200,
                    child: ElevatedButton(
                      onPressed: () => context.go('/home'),
                      child: Text('cart.go_home'.tr()),
                    ),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  itemCount: state.items.length,
                  itemBuilder: (context, index) {
                    final item = state.items[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark
                              ? AppColors.neutral800
                              : AppColors.neutral200,
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color:
                                Colors.black.withValues(alpha: isDark ? 0.1 : 0.03),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          // Mahsulot rasmi
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              width: 72,
                              height: 72,
                              color: isDark
                                  ? AppColors.neutral800
                                  : const Color(0xFFF8F9FA),
                              padding: const EdgeInsets.all(4),
                              child: CachedNetworkImage(
                                imageUrl: item.product.thumbnail,
                                fit: BoxFit.contain,
                                placeholder: (_, __) => Container(
                                    color: isDark
                                        ? AppColors.neutral800
                                        : AppColors.neutral100),
                                errorWidget: (_, __, ___) => const Icon(
                                    Icons.image_not_supported_outlined,
                                    size: 28,
                                    color: AppColors.neutral400),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),

                          // Nom + variant + narx
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.product.title,
                                  style: AppTextStyles.labelMedium.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: Theme.of(context)
                                        .textTheme
                                        .bodyLarge
                                        ?.color,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (item.variant != null) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    item.variant!.title,
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: AppColors.neutral500,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 6),
                                Text(
                                  '${NumberFormatter.formatSum(item.totalPrice)} ${'common.currency'.tr()}',
                                  style: AppTextStyles.labelMedium.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Stepper (- qty +)
                          _QuantityStepper(
                            quantity: item.quantity,
                            onDecrement: () =>
                                context.read<CartCubit>().updateQuantity(item, -1),
                            onIncrement: () =>
                                context.read<CartCubit>().updateQuantity(item, 1),
                            isDark: isDark,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // Bottom panel — jami + rasmiylashtirish tugmasi
              Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  border: Border(
                    top: BorderSide(
                      color: isDark ? AppColors.neutral800 : AppColors.neutral200,
                      width: 1,
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 12,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: Column(
                    children: [
                      // Subtotal + Jami
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'cart.total'.tr(),
                            style: AppTextStyles.labelLarge.copyWith(
                              fontWeight: FontWeight.w700,
                              color: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.color,
                            ),
                          ),
                          Text(
                            '${NumberFormatter.formatSum(state.subtotal)} ${'common.currency'.tr()}',
                            style: AppTextStyles.h2.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: () {
                            AnalyticsService.instance.logEvent(
                              'cart_checkout_clicked',
                              {
                                'items_count': state.items.length,
                                'subtotal': state.subtotal,
                              },
                            );
                            context.push('/checkout');
                          },
                          child: Text('cart.checkout'.tr()),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Miqdor stepperi — olib tashlash/qo'shish tugmalar
class _QuantityStepper extends StatelessWidget {
  final int quantity;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;
  final bool isDark;

  const _QuantityStepper({
    required this.quantity,
    required this.onDecrement,
    required this.onIncrement,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.neutral800 : AppColors.neutral100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.neutral700 : AppColors.neutral200,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Olib tashlash
          GestureDetector(
            onTap: onDecrement,
            child: Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              child: Icon(
                quantity <= 1 ? Icons.delete_outline_rounded : Icons.remove_rounded,
                size: 18,
                color: quantity <= 1 ? AppColors.error : AppColors.primary,
              ),
            ),
          ),
          // Miqdor
          SizedBox(
            width: 28,
            child: Text(
              '$quantity',
              textAlign: TextAlign.center,
              style: AppTextStyles.labelMedium.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
          ),
          // Qo'shish
          GestureDetector(
            onTap: onIncrement,
            child: Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              child: const Icon(
                Icons.add_rounded,
                size: 18,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
