import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pizza_strada/core/theme/app_colors.dart';
import 'package:pizza_strada/core/theme/app_text_styles.dart';
import 'package:pizza_strada/core/utils/number_formatter.dart';
import 'package:pizza_strada/core/utils/variant_localization_helper.dart';
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
class PromotionsPage extends StatefulWidget {
  const PromotionsPage({super.key});

  @override
  State<PromotionsPage> createState() => _PromotionsPageState();
}

class _PromotionsPageState extends State<PromotionsPage> {
  @override
  void deactivate() {
    ScaffoldMessenger.maybeOf(context)?.clearSnackBars();
    super.deactivate();
  }

  @override
  void dispose() {
    ScaffoldMessenger.maybeOf(context)?.clearSnackBars();
    super.dispose();
  }

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

                // ── Deals Cards (2 per row) ──
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 14,
                      childAspectRatio: 0.68,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) => _CouponDealCard(deal: deals[i]),
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
                                  final hasMultiple = product.variants.where((v) => VariantLocalizationHelper.localize(v.title).isNotEmpty).length > 1;
                                  if (hasMultiple) {
                                    ProductDetailModal.show(context, product);
                                  } else {
                                    context.push('/product/${product.slug}', extra: product);
                                  }
                                },
                                onAdd: () {
                                  final hasMultiple = product.variants.where((v) => VariantLocalizationHelper.localize(v.title).isNotEmpty).length > 1;
                                  if (hasMultiple) {
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

/// 🎟️ 2-Column Bento Coupon Deal Card
class _CouponDealCard extends StatelessWidget {
  final PromotionDealEntity deal;

  const _CouponDealCard({required this.deal});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasSavings = deal.oldPrice > deal.price && deal.price > 0;
    final discountPercent = hasSavings
        ? (((deal.oldPrice - deal.price) / deal.oldPrice) * 100).round()
        : 0;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : const Color(0xFFF1F3F5),
          width: 1,
        ),
        boxShadow: isDark
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ]
            : [
                BoxShadow(
                  color: const Color(0xFF1E293B).withValues(alpha: 0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
                BoxShadow(
                  color: const Color(0xFF1E293B).withValues(alpha: 0.03),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            context.push('/coupon-detail', extra: deal);
          },
          borderRadius: BorderRadius.circular(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── 1. Hero Image Section (Square 1:1 style) ──
              Expanded(
                flex: 6,
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(19)),
                      child: Container(
                        width: double.infinity,
                        height: double.infinity,
                        color: isDark ? AppColors.neutral800 : const Color(0xFFF8F9FA),
                        child: deal.imageUrl.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: deal.imageUrl,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  color: isDark ? AppColors.darkSurface : AppColors.neutral100,
                                  child: const Center(
                                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                                  ),
                                ),
                                errorWidget: (context, url, error) => Container(
                                  color: isDark ? AppColors.darkSurface : AppColors.neutral100,
                                  child: const Center(
                                    child: Icon(Icons.confirmation_number_outlined, size: 40, color: AppColors.neutral400),
                                  ),
                                ),
                              )
                            : Container(
                                color: isDark ? AppColors.darkSurface : AppColors.neutral100,
                                child: const Center(
                                  child: Icon(Icons.confirmation_number_outlined, size: 40, color: AppColors.neutral400),
                                ),
                              ),
                      ),
                    ),

                    // Top-Left: Discount Badge
                    if (hasSavings)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.success,
                            borderRadius: BorderRadius.circular(7),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.success.withValues(alpha: 0.35),
                                blurRadius: 4,
                                offset: const Offset(0, 1.5),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.arrow_downward_rounded, size: 11, color: Colors.white),
                              const SizedBox(width: 2),
                              Text(
                                '-$discountPercent%',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 10.5,
                                  letterSpacing: -0.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else if (deal.badgeText.isNotEmpty)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(7),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.35),
                                blurRadius: 4,
                                offset: const Offset(0, 1.5),
                              ),
                            ],
                          ),
                          child: Text(
                            deal.badgeText,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ),

                    // Top-Right: Promo Code Pill
                    if (deal.code.isNotEmpty)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            Clipboard.setData(ClipboardData(text: deal.code));
                            final messenger = ScaffoldMessenger.of(context);
                            messenger.clearSnackBars();
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text('promotions.coupon_copied'.tr(namedArgs: {'code': deal.code})),
                                backgroundColor: AppColors.success,
                                duration: const Duration(seconds: 2),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.65),
                              borderRadius: BorderRadius.circular(7),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  deal.code,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                    fontSize: 10,
                                  ),
                                ),
                                const SizedBox(width: 3),
                                const Icon(Icons.copy_rounded, size: 10, color: Colors.white70),
                              ],
                            ),
                          ),
                        ),
                      ),

                    // Bottom-Right: Floating CTA (Add / Apply)
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Material(
                        color: AppColors.primary,
                        shape: const CircleBorder(),
                        elevation: 3,
                        shadowColor: AppColors.primary.withValues(alpha: 0.4),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: () {
                            HapticFeedback.lightImpact();
                            if (deal.price > 0) {
                              context.read<CartCubit>().addCouponToCart(deal);
                              final router = GoRouter.of(context);
                              final messenger = ScaffoldMessenger.of(context);
                              messenger.clearSnackBars();

                              final displayCode = deal.code.isNotEmpty ? deal.code : deal.title;

                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text('$displayCode ${'cart.added'.tr()}'),
                                  backgroundColor: AppColors.primary,
                                  duration: const Duration(seconds: 2),
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  action: SnackBarAction(
                                    label: 'cart.title'.tr(),
                                    textColor: Colors.white,
                                    onPressed: () {
                                      messenger.clearSnackBars();
                                      router.go('/cart');
                                    },
                                  ),
                                ),
                              );
                              Future.delayed(const Duration(seconds: 2), () {
                                messenger.clearSnackBars();
                              });
                            } else if (deal.code.isNotEmpty) {
                              final cartSubtotal = context.read<CartCubit>().state.subtotal;
                              context.read<CheckoutCubit>().applyPromo(deal.code, cartSubtotal);
                              final messenger = ScaffoldMessenger.of(context);
                              messenger.clearSnackBars();
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text('promotions.coupon_applied'.tr(namedArgs: {'code': deal.code})),
                                  backgroundColor: AppColors.success,
                                  duration: const Duration(seconds: 2),
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              );
                              Future.delayed(const Duration(seconds: 2), () {
                                messenger.clearSnackBars();
                              });
                            } else {
                              context.push('/coupon-detail', extra: deal);
                            }
                          },
                          child: Container(
                            width: 32,
                            height: 32,
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.shopping_bag_outlined,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── 2. Information Section ──
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Price Row with Old Price
                    if (deal.price > 0)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Flexible(
                            child: Text(
                              '${NumberFormatter.formatSum(deal.price.toInt())} ${'common.currency'.tr()}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.priceMedium.copyWith(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                                color: hasSavings ? AppColors.primary : (isDark ? Colors.white : AppColors.neutral900),
                              ),
                            ),
                          ),
                          if (hasSavings) ...[
                            const SizedBox(width: 5),
                            Text(
                              NumberFormatter.formatSum(deal.oldPrice.toInt()),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: AppColors.neutral400,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          ],
                        ],
                      )
                    else
                      Text(
                        deal.code.isNotEmpty ? deal.code : 'promotions.deals_title'.tr(),
                        style: AppTextStyles.labelMedium.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                    const SizedBox(height: 3),

                    // Title
                    Text(
                      deal.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.h4.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : AppColors.neutral900,
                      ),
                    ),
                    const SizedBox(height: 2),

                    // Subtitle (items count or description)
                    Text(
                      deal.items.isNotEmpty
                          ? 'orders.items_count'.tr(namedArgs: {'count': deal.items.length.toString()})
                          : (deal.description.isNotEmpty ? deal.description : 'promotions.deal_detail_title'.tr()),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodySmall.copyWith(
                        fontSize: 10.5,
                        color: AppColors.neutral500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
