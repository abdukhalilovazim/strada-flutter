import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:pizza_strada/core/theme/app_colors.dart';
import 'package:pizza_strada/core/theme/app_text_styles.dart';
import 'package:pizza_strada/core/utils/number_formatter.dart';
import 'package:pizza_strada/features/home/domain/entities/home_entities.dart';

/// Mahsulot kartochkasi.
/// Dizayn: Laravel mobile `product-card` stiliga mos —
/// oq fon, 16px radius, yengil soya, 1:1 rasm (contain, kulrang fon),
/// nom, narx (qizil, eski narx chizilgan), "Ochish" pill tugma.
class ProductCard extends StatelessWidget {
  final ProductEntity product;
  final int quantityInCart;
  final VoidCallback? onTap;

  const ProductCard({
    super.key,
    required this.product,
    this.quantityInCart = 0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.neutral800 : AppColors.neutral200,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.04),
            blurRadius: 6,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Rasm qismi + miqdor badge
            Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(15)),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Container(
                      color: isDark
                          ? AppColors.neutral800
                          : const Color(0xFFF8F9FA),
                      padding: const EdgeInsets.all(8),
                      child: CachedNetworkImage(
                        imageUrl: product.thumbnail.isNotEmpty
                            ? product.thumbnail
                            : product.photo,
                        fit: BoxFit.contain,
                        placeholder: (_, __) => Container(
                          color: isDark
                              ? AppColors.neutral800
                              : const Color(0xFFF8F9FA),
                        ),
                        errorWidget: (_, __, ___) => Icon(
                          Icons.image_not_supported_outlined,
                          color: AppColors.neutral400,
                          size: 32,
                        ),
                      ),
                    ),
                  ),
                ),
                // Savat badge (top-right)
                if (quantityInCart > 0)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        '$quantityInCart',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            // Kontent qismi
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Nom
                    Text(
                      product.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.labelSmall.copyWith(
                        fontWeight: FontWeight.w700,
                        color: theme.textTheme.bodyLarge?.color,
                        fontSize: 13,
                      ),
                    ),

                    const SizedBox(height: 4),

                    // Narx + tugma
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Eski narx (chizilgan)
                        if (product.oldPrice != null &&
                            product.oldPrice! > product.price) ...[
                          Text(
                            '${NumberFormatter.formatSum(product.oldPrice!)} ${'common.currency'.tr()}',
                            style: AppTextStyles.bodyExtraSmall.copyWith(
                              color: AppColors.neutral400,
                              fontSize: 11,
                              decoration: TextDecoration.lineThrough,
                              decorationColor: AppColors.neutral400,
                            ),
                          ),
                          const SizedBox(height: 2),
                        ],
                        // Joriy narx
                        Text(
                          '${NumberFormatter.formatSum(product.price)} ${'common.currency'.tr()}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // "Ochish" tugmasi — pill, to'liq kenglik
                        _buildOpenButton(context),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// "Ochish" — to'liq kenglikdagi qizil pill tugma (Laravel btn-danger rounded-pill)
  Widget _buildOpenButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 30,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          textStyle: AppTextStyles.labelSmall.copyWith(
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
          minimumSize: const Size(0, 30),
        ),
        child: Text('product.open'.tr()),
      ),
    );
  }
}

/// Variant tanlash bottom sheet — ProductDetailPage ga o'tishdan oldin variantli mahsulotlar uchun.
class VariantPickerSheet extends StatefulWidget {
  final ProductEntity product;
  final Function(VariantEntity) onPick;

  const VariantPickerSheet({
    super.key,
    required this.product,
    required this.onPick,
  });

  @override
  State<VariantPickerSheet> createState() => _VariantPickerSheetState();
}

class _VariantPickerSheetState extends State<VariantPickerSheet> {
  VariantEntity? selectedVariant;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? AppColors.neutral700 : AppColors.neutral300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Mahsulot sarlavha qatori
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: CachedNetworkImage(
                          imageUrl: widget.product.thumbnail,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(
                              color: isDark
                                  ? AppColors.neutral800
                                  : AppColors.neutral100),
                          errorWidget: (_, __, ___) =>
                              const Icon(Icons.image_not_supported_outlined),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.product.title,
                              style: AppTextStyles.h3.copyWith(
                                color:
                                    theme.textTheme.headlineMedium?.color,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${NumberFormatter.formatSum(widget.product.price)} ${'common.currency'.tr()}',
                              style: AppTextStyles.labelMedium.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (widget.product.description != null &&
                      widget.product.description!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      widget.product.description!,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: isDark
                            ? AppColors.neutral400
                            : AppColors.neutral600,
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),

                  Text(
                    'product.select_variant_title'.tr(),
                    style: AppTextStyles.labelLarge.copyWith(
                      color: theme.textTheme.bodyLarge?.color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Variantlar ro'yxati
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: widget.product.variants.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final v = widget.product.variants[index];
                      final isSelected = selectedVariant?.id == v.id;

                      return InkWell(
                        onTap: () => setState(() => selectedVariant = v),
                        borderRadius: BorderRadius.circular(16),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? (isDark
                                    ? AppColors.primary
                                        .withValues(alpha: 0.15)
                                    : AppColors.primaryLight)
                                : Colors.transparent,
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary
                                  : (isDark
                                      ? AppColors.neutral800
                                      : AppColors.neutral200),
                              width: 1.5,
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    v.title,
                                    style: AppTextStyles.labelMedium.copyWith(
                                      color: isSelected
                                          ? AppColors.primary
                                          : theme.textTheme.bodyMedium?.color,
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${NumberFormatter.formatSum(v.price)} ${'common.currency'.tr()}',
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: isSelected
                                          ? AppColors.primary
                                              .withValues(alpha: 0.8)
                                          : (isDark
                                              ? AppColors.neutral500
                                              : AppColors.neutral600),
                                    ),
                                  ),
                                ],
                              ),
                              // Radio circle
                              Container(
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors.primary
                                        : (isDark
                                            ? AppColors.neutral700
                                            : AppColors.neutral300),
                                    width: 2,
                                  ),
                                ),
                                child: isSelected
                                    ? Center(
                                        child: Container(
                                          width: 12,
                                          height: 12,
                                          decoration: const BoxDecoration(
                                            color: AppColors.primary,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      )
                                    : null,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Savatga qo'shish tugmasi
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: selectedVariant == null
                  ? null
                  : () {
                      widget.onPick(selectedVariant!);
                      Navigator.pop(context);
                    },
              child: Text(
                selectedVariant == null
                    ? 'product.select_variant'.tr()
                    : '${'cart.add'.tr()} — ${NumberFormatter.formatSum(selectedVariant!.price)} ${'common.currency'.tr()}',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
