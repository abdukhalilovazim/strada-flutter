import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pizza_strada/core/theme/app_colors.dart';
import 'package:pizza_strada/core/theme/app_text_styles.dart';
import 'package:pizza_strada/core/utils/number_formatter.dart';
import 'package:pizza_strada/core/widgets/strada_refresh_control.dart';
import 'package:pizza_strada/features/cart/presentation/bloc/cart_cubit.dart';
import 'package:pizza_strada/features/cart/presentation/bloc/checkout/checkout_cubit.dart';
import 'package:pizza_strada/features/home/domain/entities/home_entities.dart';
import 'package:pizza_strada/features/home/presentation/bloc/home_cubit.dart';
import 'package:pizza_strada/features/home/presentation/widgets/product_card.dart';
import 'package:pizza_strada/features/home/presentation/widgets/product_detail_modal.dart';
import '../../domain/entities/promotion_deal_entity.dart';
import '../bloc/promotions_cubit.dart';

/// 🏷️ PromotionsPage powered 100% by Native Flutter UI & BLoC
class PromotionsPage extends StatelessWidget {
  const PromotionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => PromotionsCubit()..loadPromotions(),
      child: const _PromotionsView(),
    );
  }
}

class _PromotionsView extends StatelessWidget {
  const _PromotionsView();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'nav.promotions'.tr(),
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
      body: BlocBuilder<PromotionsCubit, PromotionsState>(
        builder: (context, promoState) {
          if (promoState is PromotionsLoading || promoState is PromotionsInitial) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (promoState is PromotionsFailure) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.neutral400),
                    const SizedBox(height: 12),
                    Text(
                      promoState.message,
                      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.neutral600),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => context.read<PromotionsCubit>().loadPromotions(forceRefresh: true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text('common.retry'.tr()),
                    ),
                  ],
                ),
              ),
            );
          }

          final deals = promoState is PromotionsLoaded ? promoState.deals : <PromotionDealEntity>[];
          
          // Agar promotions APIdan discountProducts bo'lsa uni olamiz, aks holda HomeCubit'dan to'ldiramiz
          List<ProductEntity> discountProducts = promoState is PromotionsLoaded ? promoState.discountProducts : [];
          if (discountProducts.isEmpty) {
            final homeState = context.watch<HomeCubit>().state;
            if (homeState is HomeLoaded) {
              discountProducts = homeState.fullProducts
                  .where((p) => p.oldPrice != null || p.badges.isNotEmpty)
                  .toList();
            }
          }

          if (deals.isEmpty && discountProducts.isEmpty) {
            return CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
              slivers: [
                StradaSliverRefreshControl(
                  onRefresh: () => context.read<PromotionsCubit>().loadPromotions(forceRefresh: true),
                ),
                SliverFillRemaining(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.darkCard : const Color(0xFFF1F3F5),
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: Icon(Icons.local_offer_outlined, size: 32, color: AppColors.neutral400),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'promotions.empty_title'.tr(),
                            style: AppTextStyles.h4.copyWith(
                              color: isDark ? Colors.white : AppColors.neutral800,
                              fontWeight: FontWeight.w700,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'promotions.empty_subtitle'.tr(),
                            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.neutral500),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          }

          return CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              StradaSliverRefreshControl(
                onRefresh: () => context.read<PromotionsCubit>().loadPromotions(forceRefresh: true),
              ),

              // ── Announcement Banner ──
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: isDark ? 0.2 : 0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.25),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.local_offer_rounded, color: AppColors.primary, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'promotions.banner_title'.tr(),
                              style: AppTextStyles.labelLarge.copyWith(
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                                color: isDark ? Colors.white : AppColors.neutral900,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'promotions.banner_subtitle'.tr(),
                              style: AppTextStyles.bodySmall.copyWith(
                                color: isDark ? AppColors.neutral300 : AppColors.neutral600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Coupons & Deals Section Header ──
              if (deals.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                    child: Row(
                      children: [
                        const Icon(Icons.confirmation_number_rounded, color: AppColors.primary, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'promotions.deals_title'.tr(),
                          style: AppTextStyles.h4.copyWith(
                            fontWeight: FontWeight.w800,
                            fontSize: 16.5,
                            color: isDark ? Colors.white : AppColors.neutral900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Deals Cards ──
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) {
                        final deal = deals[i];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkCard : Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: isDark ? AppColors.darkBorder : AppColors.neutral200.withValues(alpha: 0.7),
                            ),
                            boxShadow: AppColors.softShadow(isDark),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  if (deal.badgeText.isNotEmpty)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        deal.badgeText,
                                        style: const TextStyle(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 11.5,
                                        ),
                                      ),
                                    )
                                  else
                                    const SizedBox.shrink(),
                                  if (deal.code.isNotEmpty)
                                    GestureDetector(
                                      onTap: () {
                                        HapticFeedback.lightImpact();
                                        Clipboard.setData(ClipboardData(text: deal.code));
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('promotions.coupon_copied'.tr(namedArgs: {'code': deal.code})),
                                            backgroundColor: AppColors.success,
                                            duration: const Duration(seconds: 2),
                                          ),
                                        );
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: isDark ? AppColors.darkSurface : const Color(0xFFF1F3F5),
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(
                                            color: AppColors.primary.withValues(alpha: 0.3),
                                            style: BorderStyle.solid,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              deal.code,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w800,
                                                letterSpacing: 0.8,
                                                fontSize: 12,
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            const Icon(Icons.copy_rounded, size: 12, color: AppColors.primary),
                                          ],
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                deal.title,
                                style: AppTextStyles.labelLarge.copyWith(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                ),
                              ),
                              if (deal.description.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  deal.description,
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.neutral500,
                                    height: 1.3,
                                  ),
                                ),
                              ],
                              if (deal.items.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 4,
                                  children: deal.items.map((it) {
                                    final label = it.variantTitle.isNotEmpty
                                        ? '${it.productTitle} (${it.variantTitle}) x${it.quantity}'
                                        : '${it.productTitle} x${it.quantity}';
                                    return Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: isDark ? AppColors.darkSurface : const Color(0xFFF1F3F5),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        label,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: isDark ? AppColors.neutral300 : AppColors.neutral700,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  if (deal.price > 0)
                                    Row(
                                      children: [
                                        Text(
                                          '${NumberFormatter.formatSum(deal.price.toInt())} ${'common.currency'.tr()}',
                                          style: AppTextStyles.labelLarge.copyWith(
                                            fontWeight: FontWeight.w900,
                                            fontSize: 16,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                        if (deal.oldPrice > deal.price) ...[
                                          const SizedBox(width: 8),
                                          Text(
                                            '${NumberFormatter.formatSum(deal.oldPrice.toInt())} ${'common.currency'.tr()}',
                                            style: AppTextStyles.bodySmall.copyWith(
                                              decoration: TextDecoration.lineThrough,
                                              color: AppColors.neutral400,
                                            ),
                                          ),
                                        ],
                                      ],
                                    )
                                  else
                                    const SizedBox.shrink(),
                                  if (deal.code.isNotEmpty)
                                    ElevatedButton(
                                      onPressed: () {
                                        HapticFeedback.lightImpact();
                                        final cartSubtotal = context.read<CartCubit>().state.subtotal;
                                        context.read<CheckoutCubit>().applyPromo(deal.code, cartSubtotal);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('promotions.coupon_applied'.tr(namedArgs: {'code': deal.code})),
                                            backgroundColor: AppColors.success,
                                            duration: const Duration(seconds: 2),
                                          ),
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primary,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                        minimumSize: Size.zero,
                                        elevation: 0,
                                      ),
                                      child: Text('cart.apply'.tr(), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5)),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                      childCount: deals.length,
                    ),
                  ),
                ),
              ],

              // ── Discount Products Section Header ──
              if (discountProducts.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                    child: Text(
                      'promotions.discount_products_title'.tr(),
                      style: AppTextStyles.h4.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 16.5,
                        color: isDark ? Colors.white : AppColors.neutral900,
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 14,
                      childAspectRatio: 0.68,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final product = discountProducts[index];
                        return RepaintBoundary(
                          child: BlocBuilder<CartCubit, CartState>(
                            builder: (context, cartState) {
                              final matchingItems = cartState.items.where((ci) => ci.product.slug == product.slug).toList();
                              final quantity = matchingItems.fold<int>(0, (sum, ci) => sum + ci.quantity);
                              final firstCartItem = matchingItems.firstOrNull;

                              return ProductCard(
                                product: product,
                                quantityInCart: quantity,
                                onTap: () {
                                  if (product.variants.length > 1) {
                                    ProductDetailModal.show(context, product);
                                  } else {
                                    context.push('/product/${product.slug}', extra: product);
                                  }
                                },
                                onAdd: () {
                                  if (product.variants.length > 1) {
                                    ProductDetailModal.show(context, product);
                                  } else {
                                    context.read<CartCubit>().addToCart(
                                          product,
                                          variant: product.variants.firstOrNull,
                                        );
                                  }
                                },
                                onRemove: () {
                                  if (firstCartItem != null) {
                                    context.read<CartCubit>().updateQuantity(firstCartItem, -1);
                                  }
                                },
                              );
                            },
                          ),
                        );
                      },
                      childCount: discountProducts.length,
                    ),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
