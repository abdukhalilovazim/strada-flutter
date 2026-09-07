import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:pizza_strada/core/theme/app_colors.dart';
import 'package:pizza_strada/core/theme/app_text_styles.dart';
import 'package:pizza_strada/core/utils/number_formatter.dart';
import 'package:pizza_strada/features/home/domain/entities/home_entities.dart';

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
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Rasm bloki ──
              Expanded(
                flex: 5,
                child: Stack(
                  children: [
                    // Rasm
                    Container(
                      width: double.infinity,
                      color: isDark
                          ? AppColors.neutral800
                          : const Color(0xFFF8F9FA),
                      child: CachedNetworkImage(
                        imageUrl: product.thumbnail.isNotEmpty
                            ? product.thumbnail
                            : product.photo,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          color: isDark
                              ? AppColors.neutral800
                              : const Color(0xFFF8F9FA),
                        ),
                        errorWidget: (_, __, ___) => Center(
                          child: Icon(
                            Icons.image_not_supported_outlined,
                            color: AppColors.neutral400,
                            size: 32,
                          ),
                        ),
                      ),
                    ),

                    // Eski narx badge (chegirma bo'lsa)
                    if (product.oldPrice != null &&
                        product.oldPrice! > product.price)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
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

                    // Floating qo'shish tugmasi / stepper (pastki-o'ng)
                    Positioned(
                      right: 8,
                      bottom: 8,
                      child: quantityInCart == 0
                          ? _AddButton(onTap: onAdd)
                          : _InlineQuantityStepper(
                              quantity: quantityInCart,
                              onDecrement: onRemove,
                              onIncrement: onAdd,
                            ),
                    ),
                  ],
                ),
              ),

              // ── Matn bloki ──
              Expanded(
                flex: 3,
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
                          height: 1.3,
                        ),
                      ),

                      // Narx
                      Text(
                        '${NumberFormatter.formatSum(product.price)} ${'common.currency'.tr()}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Floating qizil circle `+` tugmasi (savat bo'sh bo'lsa)
class _AddButton extends StatelessWidget {
  final VoidCallback? onTap;

  const _AddButton({this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: const BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Color(0x33D32F2F),
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: const Icon(
          Icons.add_rounded,
          color: Colors.white,
          size: 22,
        ),
      ),
    );
  }
}

/// Floating pill stepper `- N +` (savat bo'sh bo'lmasa)
class _InlineQuantityStepper extends StatelessWidget {
  final int quantity;
  final VoidCallback? onDecrement;
  final VoidCallback? onIncrement;

  const _InlineQuantityStepper({
    required this.quantity,
    this.onDecrement,
    this.onIncrement,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(999),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33D32F2F),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Minus tugma
          GestureDetector(
            onTap: onDecrement,
            child: Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              child: Icon(
                quantity <= 1
                    ? Icons.delete_outline_rounded
                    : Icons.remove_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
          // Miqdor
          SizedBox(
            width: 24,
            child: Text(
              '$quantity',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          // Plus tugma
          GestureDetector(
            onTap: onIncrement,
            child: Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              child: const Icon(
                Icons.add_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
        ],
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
  void initState() {
    super.initState();
    if (widget.product.variants.isNotEmpty) {
      selectedVariant = widget.product.variants.first;
    }
  }

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
          SafeArea(
            top: false,
            child: SizedBox(
              height: 50,
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
          ),
        ],
      ),
    );
  }
}
