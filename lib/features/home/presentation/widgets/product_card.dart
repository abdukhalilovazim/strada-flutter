import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pizza_strada/core/theme/app_colors.dart';
import 'package:pizza_strada/core/theme/app_text_styles.dart';
import 'package:pizza_strada/core/utils/number_formatter.dart';
import 'package:pizza_strada/core/widgets/pizza_image_placeholder.dart';
import 'package:pizza_strada/features/home/domain/entities/home_entities.dart';
import 'package:shimmer/shimmer.dart';

/// 🍕 Modern Premium Artisan Pizza Card for Strada
/// Benchmarked against Dodo Pizza and Apple Bento style:
/// - Soft ambient dual-layer shadow with rounded corners (20px)
/// - Appetizing 1:1 pizza photography with smooth rounded header
/// - Crisp discount tag with soft red glow
/// - Bold, clear typography with ingredient previews
/// - Thumb-friendly 1-tap tactile CTA buttons and active stepper
class ProductCard extends StatelessWidget {
  final ProductEntity product;
  final int quantityInCart;
  final VoidCallback? onTap;
  final VoidCallback? onAdd;
  final VoidCallback? onRemove;

  const ProductCard({
    super.key,
    required this.product,
    this.quantityInCart = 0,
    this.onTap,
    this.onAdd,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasVariants = product.variants.length > 1;
    final hasDiscount = product.oldPrice != null && product.oldPrice! > product.price;

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
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── 1. Hero Image Section ──
              Expanded(
                flex: 6,
                child: Stack(
                  children: [
                    // Pizza Photo
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(19)),
                      child: Container(
                        width: double.infinity,
                        height: double.infinity,
                        color: isDark ? AppColors.neutral800 : const Color(0xFFF8F9FA),
                        child: product.hasValidImage
                            ? CachedNetworkImage(
                                imageUrl: product.validImageUrl,
                                fit: BoxFit.cover,
                                placeholder: (_, __) => Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    const Opacity(
                                      opacity: 0.25,
                                      child: PizzaImagePlaceholder(fit: BoxFit.cover),
                                    ),
                                    Shimmer.fromColors(
                                      baseColor: isDark
                                          ? AppColors.neutral800
                                          : AppColors.neutral100,
                                      highlightColor: isDark
                                          ? AppColors.neutral700
                                          : Colors.white,
                                      child: Container(color: Colors.white),
                                    ),
                                  ],
                                ),
                                errorWidget: (_, __, ___) => const PizzaImagePlaceholder(
                                  fit: BoxFit.cover,
                                ),
                              )
                            : const PizzaImagePlaceholder(fit: BoxFit.cover),
                      ),
                    ),

                    // Discount Pill (Top Left)
                    if (hasDiscount)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.error,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.error.withValues(alpha: 0.3),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            '${NumberFormatter.formatSum(product.oldPrice!)} ${'common.currency'.tr()}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              decoration: TextDecoration.lineThrough,
                              decorationColor: Colors.white,
                            ),
                          ),
                        ),
                      ),

                    // Multiple variants tag (Bottom Left)
                    if (hasVariants)
                      Positioned(
                        bottom: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.65),
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: Text(
                            'product.variants_count'.tr(namedArgs: {'count': product.variants.length.toString()}),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // ── 2. Information & Actions Section ──
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Title
                    Text(
                      product.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.h4.copyWith(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : AppColors.neutral900,
                      ),
                    ),
                    const SizedBox(height: 3),

                    // Ingredients / Short description
                    if (product.description != null && product.description!.isNotEmpty)
                      Text(
                        product.description!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodySmall.copyWith(
                          fontSize: 11.5,
                          color: AppColors.neutral500,
                        ),
                      )
                    else
                      const SizedBox(height: 14),

                    const SizedBox(height: 8),

                    // Price & Action Button Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Price
                        Expanded(
                          child: Text(
                            '${NumberFormatter.formatSum(product.price)} ${'common.currency'.tr()}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.priceMedium.copyWith(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : AppColors.neutral900,
                            ),
                          ),
                        ),

                        // Action Button or Stepper
                        if (quantityInCart == 0)
                          // Single Tap Add / Select
                          hasVariants
                              ? Material(
                                  color: AppColors.primaryLight,
                                  borderRadius: BorderRadius.circular(10),
                                  child: InkWell(
                                    onTap: () {
                                      HapticFeedback.lightImpact();
                                      onTap?.call();
                                    },
                                    borderRadius: BorderRadius.circular(10),
                                    child: Container(
                                      height: 34,
                                      padding: const EdgeInsets.symmetric(horizontal: 11),
                                      alignment: Alignment.center,
                                      child: Text(
                                        'product.open_btn'.tr(),
                                        style: AppTextStyles.labelSmall.copyWith(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                              : Material(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(10),
                                  elevation: 2,
                                  shadowColor: AppColors.primary.withValues(alpha: 0.35),
                                  child: InkWell(
                                    onTap: () {
                                      HapticFeedback.lightImpact();
                                      (onAdd ?? onTap)?.call();
                                    },
                                    borderRadius: BorderRadius.circular(10),
                                    child: const SizedBox(
                                      width: 34,
                                      height: 34,
                                      child: Icon(
                                        Icons.add_rounded,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                )
                        else
                          // Active Stepper in Cart
                          Container(
                            height: 34,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.32),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    HapticFeedback.lightImpact();
                                    onRemove?.call();
                                  },
                                  behavior: HitTestBehavior.opaque,
                                  child: Container(
                                    width: 28,
                                    height: 34,
                                    alignment: Alignment.center,
                                    child: const Icon(
                                      Icons.remove_rounded,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 3),
                                  child: Text(
                                    '$quantityInCart',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    HapticFeedback.lightImpact();
                                    (onAdd ?? onTap)?.call();
                                  },
                                  behavior: HitTestBehavior.opaque,
                                  child: Container(
                                    width: 28,
                                    height: 34,
                                    alignment: Alignment.center,
                                    child: const Icon(
                                      Icons.add_rounded,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
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
