import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pizza_strada/core/theme/app_colors.dart';
import 'package:pizza_strada/core/theme/app_text_styles.dart';
import 'package:pizza_strada/core/utils/number_formatter.dart';
import 'package:pizza_strada/core/utils/variant_localization_helper.dart';
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
    final hasVariants = product.variants.where((v) => VariantLocalizationHelper.localize(v.title).isNotEmpty).length > 1;
    final discountVal = product.discountAmount;
    final hasDiscount = discountVal != null;

    final effectiveBadges = <ProductBadgeEntity>[
      ...product.badges,
      if (product.badges.isEmpty && hasDiscount)
        ProductBadgeEntity(
          text: '-${NumberFormatter.formatSum(discountVal.toInt())} ${'common.currency'.tr()}',
          type: 'discount',
          bgColor: '#16A34A',
          textColor: '#FFFFFF',
        ),
    ];

    Color parseHex(String? hex, Color fallback) {
      if (hex == null || hex.isEmpty) return fallback;
      final clean = hex.replaceAll('#', '');
      if (clean.length == 6) {
        return Color(int.parse('0xFF$clean'));
      }
      return fallback;
    }

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

                    // Dynamic Badges (Top Left: -12 000 sum, Yangi, Ommabop, etc.)
                    if (effectiveBadges.isNotEmpty)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Wrap(
                          direction: Axis.vertical,
                          spacing: 4,
                          children: effectiveBadges.map((b) {
                            final bg = parseHex(b.bgColor, const Color(0xFF16A34A));
                            final fg = parseHex(b.textColor, Colors.white);

                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color: bg,
                                borderRadius: BorderRadius.circular(7),
                                boxShadow: [
                                  BoxShadow(
                                    color: bg.withValues(alpha: 0.35),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1.5),
                                  ),
                                ],
                              ),
                              child: Text(
                                b.text,
                                style: TextStyle(
                                  color: fg,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.2,
                                ),
                              ),
                            );
                          }).toList(),
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

                    // Floating circular Add Button / Stepper (Bottom Right of Photo - EVOS style)
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: quantityInCart == 0
                          ? Material(
                              color: isDark ? AppColors.darkCard : Colors.white,
                              shape: const CircleBorder(),
                              elevation: 3,
                              shadowColor: Colors.black.withValues(alpha: 0.2),
                              child: InkWell(
                                customBorder: const CircleBorder(),
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                  (hasVariants ? onTap : (onAdd ?? onTap))?.call();
                                },
                                child: Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
                                      width: 1,
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: Icon(
                                    Icons.add_rounded,
                                    size: 20,
                                    color: isDark ? Colors.white : AppColors.neutral900,
                                  ),
                                ),
                              ),
                            )
                          : Container(
                              height: 32,
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(alpha: 0.4),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
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
                                    child: const Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                                      child: Icon(Icons.remove_rounded, size: 16, color: Colors.white),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 4),
                                    child: Text(
                                      '$quantityInCart',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      HapticFeedback.lightImpact();
                                      onAdd?.call();
                                    },
                                    child: const Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                                      child: Icon(Icons.add_rounded, size: 16, color: Colors.white),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ),
                  ],
                ),
              ),

              // ── 2. Information & Actions Section ──
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Price Row with Old Price (EVOS / Yandex Eats style)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '${NumberFormatter.formatSum(product.price)} ${'common.currency'.tr()}',
                          style: AppTextStyles.priceMedium.copyWith(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            color: hasDiscount ? AppColors.primary : (isDark ? Colors.white : AppColors.neutral900),
                          ),
                        ),
                        if (hasDiscount) ...[
                          const SizedBox(width: 6),
                          Text(
                            NumberFormatter.formatSum(product.oldPrice!),
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                              color: AppColors.neutral400,
                              decoration: TextDecoration.lineThrough,
                              decorationColor: AppColors.neutral400,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),

                    // Title
                    Text(
                      product.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.h4.copyWith(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : AppColors.neutral900,
                      ),
                    ),
                    const SizedBox(height: 2),

                    // Ingredients / Short description
                    if (product.description != null && product.description!.isNotEmpty)
                      Text(
                        product.description!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodySmall.copyWith(
                          fontSize: 11,
                          color: AppColors.neutral500,
                        ),
                      )
                    else
                      const SizedBox(height: 14),
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
