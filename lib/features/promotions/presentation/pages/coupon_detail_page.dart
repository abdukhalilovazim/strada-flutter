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
import 'package:pizza_strada/features/cart/presentation/bloc/cart_cubit.dart';
import 'package:pizza_strada/features/cart/presentation/bloc/checkout/checkout_cubit.dart';
import '../../domain/entities/promotion_deal_entity.dart';

class CouponDetailPage extends StatelessWidget {
  final PromotionDealEntity deal;

  const CouponDetailPage({super.key, required this.deal});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasSavings = deal.oldPrice > deal.price && deal.price > 0;
    final savings = hasSavings ? (deal.oldPrice - deal.price) : 0.0;
    final discountPercent = hasSavings ? (((deal.oldPrice - deal.price) / deal.oldPrice) * 100).round() : 0;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'promotions.deal_detail_title'.tr(),
          style: AppTextStyles.h3.copyWith(
            color: Theme.of(context).textTheme.headlineMedium?.color,
          ),
        ),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: isDark ? Colors.white : AppColors.neutral900,
            size: 20,
          ),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Square Image (1:1 Aspect Ratio) ──
            if (deal.imageUrl.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: AspectRatio(
                  aspectRatio: 1.0,
                  child: CachedNetworkImage(
                    imageUrl: deal.imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: isDark ? AppColors.darkSurface : AppColors.neutral100,
                      child: const Center(
                        child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: isDark ? AppColors.darkSurface : AppColors.neutral100,
                      child: const Center(
                        child: Icon(Icons.confirmation_number_outlined, size: 64, color: AppColors.neutral400),
                      ),
                    ),
                  ),
                ),
              )
            else
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : AppColors.neutral100,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const AspectRatio(
                  aspectRatio: 1.0,
                  child: Center(
                    child: Icon(Icons.confirmation_number_outlined, size: 72, color: AppColors.neutral400),
                  ),
                ),
              ),

            const SizedBox(height: 18),

            // ── Badges & Code Row ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (hasSavings)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.success.withValues(alpha: 0.35),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.arrow_downward_rounded, size: 14, color: AppColors.success),
                        const SizedBox(width: 4),
                        Text(
                          '-$discountPercent%',
                          style: const TextStyle(
                            color: AppColors.success,
                            fontWeight: FontWeight.w900,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  )
                else if (deal.badgeText.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      deal.badgeText,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                  )
                else
                  const SizedBox.shrink(),

                // Coupon Code copy block
                if (deal.code.isNotEmpty)
                  InkWell(
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
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkCard : const Color(0xFFF1F3F5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.4),
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            deal.code,
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1,
                              fontSize: 13,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(Icons.copy_rounded, size: 14, color: AppColors.primary),
                        ],
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 14),

            // ── Title ──
            Text(
              deal.title,
              style: AppTextStyles.h2.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 22,
                color: isDark ? Colors.white : AppColors.neutral900,
              ),
            ),

            const SizedBox(height: 12),

            // ── Price & Savings Section ──
            if (deal.price > 0) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.neutral200,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'common.price'.tr(),
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.neutral500,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              '${NumberFormatter.formatSum(deal.price.toInt())} ${'common.currency'.tr()}',
                              style: AppTextStyles.h3.copyWith(
                                fontWeight: FontWeight.w900,
                                fontSize: 20,
                                color: AppColors.primary,
                              ),
                            ),
                            if (hasSavings) ...[
                              const SizedBox(width: 10),
                              Text(
                                '${NumberFormatter.formatSum(deal.oldPrice.toInt())} ${'common.currency'.tr()}',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  decoration: TextDecoration.lineThrough,
                                  color: AppColors.neutral400,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                    if (hasSavings)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.savings_outlined, size: 16, color: AppColors.success),
                            const SizedBox(width: 4),
                            Text(
                              '${NumberFormatter.formatSum(savings.toInt())} ${'common.currency'.tr()}',
                              style: const TextStyle(
                                color: AppColors.success,
                                fontWeight: FontWeight.w800,
                                fontSize: 12.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // ── Items (Tarkibi) Section ──
            if (deal.items.isNotEmpty) ...[
              Text(
                'promotions.composition'.tr(),
                style: AppTextStyles.h4.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: isDark ? Colors.white : AppColors.neutral900,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.neutral200,
                  ),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: deal.items.length,
                  separatorBuilder: (context, index) => Divider(
                    height: 1,
                    color: isDark ? AppColors.darkBorder : AppColors.neutral100,
                  ),
                  itemBuilder: (context, index) {
                    final item = deal.items[index];
                    final cleanVariant = VariantLocalizationHelper.localize(item.variantTitle);

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Center(
                              child: Icon(Icons.local_pizza_outlined, size: 18, color: AppColors.primary),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.productTitle,
                                  style: AppTextStyles.labelMedium.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? Colors.white : AppColors.neutral900,
                                  ),
                                ),
                                if (cleanVariant.isNotEmpty)
                                  Text(
                                    cleanVariant,
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: AppColors.neutral500,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.darkSurface : const Color(0xFFF1F3F5),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '× ${item.quantity}',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                                color: isDark ? Colors.white : AppColors.neutral900,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 18),
            ],

            // ── Description ──
            if (deal.description.isNotEmpty) ...[
              Text(
                'promotions.description'.tr(),
                style: AppTextStyles.h4.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: isDark ? Colors.white : AppColors.neutral900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                deal.description,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: isDark ? AppColors.neutral300 : AppColors.neutral700,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
            ],
          ],
        ),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: deal.price > 0
                ? ElevatedButton.icon(
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      context.read<CartCubit>().addCouponToCart(deal);
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
                              context.go('/cart');
                            },
                          ),
                        ),
                      );
                      Future.delayed(const Duration(seconds: 2), () {
                        messenger.clearSnackBars();
                      });
                      context.pop();
                    },
                    icon: const Icon(Icons.shopping_bag_outlined, size: 20),
                    label: Text(
                      '${'cart.add'.tr()} — ${NumberFormatter.formatSum(deal.price.toInt())} ${'common.currency'.tr()}',
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                  )
                : ElevatedButton.icon(
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      if (deal.code.isNotEmpty) {
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
                      }
                      context.pop();
                    },
                    icon: const Icon(Icons.check_circle_outline_rounded, size: 20),
                    label: Text(
                      'cart.apply'.tr(),
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

