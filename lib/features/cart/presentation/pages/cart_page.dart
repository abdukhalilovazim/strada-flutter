import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pizza_strada/core/services/analytics_service.dart';
import 'package:pizza_strada/core/theme/app_colors.dart';
import 'package:pizza_strada/core/theme/app_text_styles.dart';
import 'package:pizza_strada/core/utils/number_formatter.dart';
import 'package:pizza_strada/core/widgets/pizza_image_placeholder.dart';
import 'package:pizza_strada/features/cart/presentation/bloc/cart_cubit.dart';
import 'package:pizza_strada/features/home/presentation/bloc/home_cubit.dart';

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
                        color: isDark ? AppColors.darkCard : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isDark
                              ? AppColors.darkBorder
                              : AppColors.neutral200.withValues(alpha: 0.7),
                          width: 1,
                        ),
                        boxShadow: AppColors.softShadow(isDark),
                      ),
                      child: Row(
                        children: [
                          // Mahsulot rasmi
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              width: 76,
                              height: 76,
                              color: isDark
                                  ? AppColors.neutral800
                                  : const Color(0xFFF8F9FA),
                              padding: const EdgeInsets.all(4),
                              child: (item.product.thumbnail.isNotEmpty || item.product.photo.isNotEmpty)
                                  ? CachedNetworkImage(
                                      imageUrl: item.product.thumbnail.isNotEmpty
                                          ? item.product.thumbnail
                                          : item.product.photo,
                                      fit: BoxFit.contain,
                                      placeholder: (_, __) => Container(
                                          color: isDark
                                              ? AppColors.neutral800
                                              : AppColors.neutral100),
                                      errorWidget: (_, __, ___) => const PizzaImagePlaceholder(
                                          fit: BoxFit.contain),
                                    )
                                  : const PizzaImagePlaceholder(fit: BoxFit.contain),
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
                                  style: AppTextStyles.h4.copyWith(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? Colors.white : AppColors.neutral900,
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
                                Builder(
                                  builder: (context) {
                                    final unitPrice = item.variant?.price ?? item.product.price;
                                    return Text.rich(
                                      TextSpan(
                                        children: [
                                          if (item.quantity > 1) ...[
                                            TextSpan(
                                              text: '${NumberFormatter.formatSum(unitPrice.toInt())} × ${item.quantity} = ',
                                              style: AppTextStyles.bodySmall.copyWith(
                                                color: isDark ? AppColors.neutral400 : AppColors.neutral600,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                          TextSpan(
                                            text: '${NumberFormatter.formatSum(item.totalPrice.toInt())} ${'common.currency'.tr()}',
                                            style: AppTextStyles.priceMedium.copyWith(
                                              color: AppColors.primary,
                                              fontSize: 15,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
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

              // ── Cross-sell / Upsell Carousel (KFC & Dodo Pizza andozasi) ──
              _buildUpsellSection(context, isDark),

              // Bottom panel — jami + rasmiylashtirish tugmasi
              Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : Colors.white,
                  border: Border(
                    top: BorderSide(
                      color: isDark ? AppColors.darkBorder : AppColors.neutral200,
                      width: 1,
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
                      blurRadius: 16,
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
                              color: isDark ? AppColors.neutral300 : AppColors.neutral700,
                            ),
                          ),
                          Text(
                            '${NumberFormatter.formatSum(state.subtotal)} ${'common.currency'.tr()}',
                            style: AppTextStyles.priceLarge.copyWith(
                              color: AppColors.primary,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
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

  /// 🍟 🥤 🥫 KFC & Dodo Pizza andozasidagi kross-sell karuseli
  Widget _buildUpsellSection(BuildContext context, bool isDark) {
    return BlocBuilder<HomeCubit, HomeState>(
      builder: (context, homeState) {
        if (homeState is! HomeLoaded) return const SizedBox.shrink();

        final cartItems = context.watch<CartCubit>().state.items;
        final cartSlugs = cartItems.map((ci) => ci.product.slug).toSet();

        // Candidates: souslar, drinks, side-dish
        final candidates = homeState.fullProducts.where((p) {
          final catSlug = p.category?.slug ?? '';
          final isComplementary =
              catSlug == 'souslar' || catSlug == 'drinks' || catSlug == 'side-dish';
          return isComplementary && !cartSlugs.contains(p.slug);
        }).take(8).toList();

        if (candidates.isEmpty) return const SizedBox.shrink();

        return Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : const Color(0xFFF8F9FA),
            border: Border(
              top: BorderSide(
                color: isDark ? AppColors.darkBorder : AppColors.neutral200,
                width: 1,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                child: Row(
                  children: [
                    Text(
                      'Buni ham qo\'shing',
                      style: AppTextStyles.labelMedium.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        color: isDark ? Colors.white : AppColors.neutral900,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text('🍟 🥤 🥫', style: TextStyle(fontSize: 11)),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              SizedBox(
                height: 116,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: candidates.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (ctx, i) {
                    final product = candidates[i];
                    return Container(
                      width: 110,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurface : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark ? AppColors.neutral800 : AppColors.neutral200,
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Rasm
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              height: 44,
                              width: double.infinity,
                              color: isDark ? AppColors.neutral800 : const Color(0xFFF1F3F5),
                              child: (product.thumbnail.isNotEmpty || product.photo.isNotEmpty)
                                  ? CachedNetworkImage(
                                      imageUrl: product.thumbnail.isNotEmpty
                                          ? product.thumbnail
                                          : product.photo,
                                      fit: BoxFit.contain,
                                      errorWidget: (_, __, ___) => const PizzaImagePlaceholder(
                                        fit: BoxFit.contain,
                                      ),
                                    )
                                  : const PizzaImagePlaceholder(fit: BoxFit.contain),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            product.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.labelSmall.copyWith(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : AppColors.neutral900,
                            ),
                          ),
                          const Spacer(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                NumberFormatter.formatSum(product.price),
                                style: AppTextStyles.priceMedium.copyWith(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primary,
                                ),
                              ),
                              Material(
                                color: AppColors.primaryLight,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: InkWell(
                                  onTap: () {
                                    context.read<CartCubit>().addToCart(
                                          product,
                                          variant: product.variants.firstOrNull,
                                        );
                                  },
                                  borderRadius: BorderRadius.circular(8),
                                  child: const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: Icon(
                                      Icons.add_rounded,
                                      size: 16,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
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
        borderRadius: BorderRadius.circular(14),
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
              width: 36,
              height: 36,
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
                fontWeight: FontWeight.w800,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
          ),
          // Qo'shish
          GestureDetector(
            onTap: onIncrement,
            child: Container(
              width: 36,
              height: 36,
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
