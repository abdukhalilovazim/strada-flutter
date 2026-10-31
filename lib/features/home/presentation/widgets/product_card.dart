import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:pizza_strada/core/theme/app_colors.dart';
import 'package:pizza_strada/core/theme/app_text_styles.dart';
import 'package:pizza_strada/core/utils/number_formatter.dart';
import 'package:pizza_strada/core/widgets/pizza_image_placeholder.dart';
import 'package:pizza_strada/features/home/domain/entities/home_entities.dart';
import 'package:shimmer/shimmer.dart';

/// Uzum Tezkor uslubidagi mahsulot kartochkasi.
///
/// - Rasm yuqorida to'liq (AspectRatio 1:1, cover).
/// - Nom va narx pastda.
/// - `quantityInCart == 0`: pastki-o'ng burchakda floating qizil circle `+` tugma.
/// - `quantityInCart > 0`: floating pill `- N +` stepper qizil rangda.
class ProductCard extends StatelessWidget {
  final ProductEntity product;
  final int quantityInCart;

  /// Mahsulot kartasiga tegish (detail/variant sheet)
  final VoidCallback? onTap;

  /// Savatga qo'shish (`+` bosish)
  final VoidCallback? onAdd;

  /// Miqdorni kamaytirish (`-` bosish)
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark ? AppColors.neutral800 : AppColors.neutral200.withValues(alpha: 0.7),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── 1. Rasm bloki ──
              Expanded(
                flex: 5,
                child: Stack(
                  children: [
                    Container(
                      width: double.infinity,
                      height: double.infinity,
                      color: isDark ? AppColors.neutral800 : const Color(0xFFF8F9FA),
                      child: (product.thumbnail.isNotEmpty || product.photo.isNotEmpty)
                          ? CachedNetworkImage(
                              imageUrl: product.thumbnail.isNotEmpty
                                  ? product.thumbnail
                                  : product.photo,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => Stack(
                                fit: StackFit.expand,
                                children: [
                                  const Opacity(
                                    opacity: 0.35,
                                    child: PizzaImagePlaceholder(fit: BoxFit.cover),
                                  ),
                                  Shimmer.fromColors(
                                    baseColor: isDark
                                        ? AppColors.neutral800.withValues(alpha: 0.3)
                                        : Colors.white.withValues(alpha: 0.2),
                                    highlightColor: isDark
                                        ? AppColors.neutral700.withValues(alpha: 0.5)
                                        : Colors.white.withValues(alpha: 0.6),
                                    child: Container(
                                      color: isDark ? AppColors.neutral800 : Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                              errorWidget: (_, __, ___) => const PizzaImagePlaceholder(
                                fit: BoxFit.cover,
                              ),
                            )
                          : const PizzaImagePlaceholder(
                              fit: BoxFit.cover,
                            ),
                    ),

                    // Eski narx badge (chegirma bo'lsa)
                    if (product.oldPrice != null && product.oldPrice! > product.price)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.error,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${NumberFormatter.formatSum(product.oldPrice!)} ${'common.currency'.tr()}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.lineThrough,
                              decorationColor: Colors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // ── 2. Ma'lumot va Tugma bloki ──
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Mahsulot nomi
                    Text(
                      product.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.labelMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : AppColors.neutral900,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Narxi
                    Text(
                      '${NumberFormatter.formatSum(product.price)} ${'common.currency'.tr()}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.labelMedium.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // "Открыть" yoki Savat stepper tugmasi
                    SizedBox(
                      width: double.infinity,
                      height: 36,
                      child: quantityInCart == 0
                          ? Material(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(12),
                              child: InkWell(
                                onTap: onTap,
                                borderRadius: BorderRadius.circular(12),
                                child: Center(
                                  child: Text(
                                    'product.open_btn'.tr(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            )
                          : Container(
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove_rounded, color: Colors.white, size: 18),
                                    onPressed: onRemove,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(minWidth: 36),
                                  ),
                                  Text(
                                    '$quantityInCart',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add_rounded, color: Colors.white, size: 18),
                                    onPressed: onAdd,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(minWidth: 36),
                                  ),
                                ],
                              ),
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
