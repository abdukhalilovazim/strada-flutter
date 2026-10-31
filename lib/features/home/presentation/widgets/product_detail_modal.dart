import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pizza_strada/core/theme/app_colors.dart';
import 'package:pizza_strada/core/theme/app_text_styles.dart';
import 'package:pizza_strada/core/utils/number_formatter.dart';
import 'package:pizza_strada/core/widgets/pizza_image_placeholder.dart';
import 'package:pizza_strada/features/cart/domain/entities/cart_item_entity.dart';
import 'package:pizza_strada/features/cart/presentation/bloc/cart_cubit.dart';
import 'package:pizza_strada/features/home/domain/entities/home_entities.dart';

/// Modal popup for product detail & variant selection.
///
/// Matches the Strada Pizza UI dialog with image on top,
/// category tag, title, description, variant segmented selector,
/// price stepper, and action buttons ("Добавить в корзину" & "Купить сейчас").
class ProductDetailModal extends StatefulWidget {
  final ProductEntity product;

  const ProductDetailModal({super.key, required this.product});

  static Future<void> show(BuildContext context, ProductEntity product) {
    return showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (ctx) => ProductDetailModal(product: product),
    );
  }

  @override
  State<ProductDetailModal> createState() => _ProductDetailModalState();
}

class _ProductDetailModalState extends State<ProductDetailModal> {
  VariantEntity? _selectedVariant;
  int _quantity = 1;

  @override
  void initState() {
    super.initState();
    if (widget.product.variants.isNotEmpty) {
      _selectedVariant = widget.product.variants.first;
    }
  }

  double get _currentPrice {
    return _selectedVariant?.price ?? widget.product.price;
  }

  String _getVariantTitle(String raw) {
    if (raw.contains('(')) {
      return raw.split('(').first.trim();
    }
    return raw;
  }

  String? _getVariantSubtitle(VariantEntity variant) {
    final raw = variant.title;
    if (raw.contains('(') && raw.contains(')')) {
      final start = raw.indexOf('(') + 1;
      final end = raw.indexOf(')');
      return raw.substring(start, end).trim();
    }
    return null;
  }

  void _onAddToCart(BuildContext context) {
    context.read<CartCubit>().addMultipleToCart([
      CartItemEntity(
        product: widget.product,
        variant: _selectedVariant,
        quantity: _quantity,
      ),
    ]);
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('product.added'.tr()),
        duration: const Duration(seconds: 2),
        backgroundColor: AppColors.secondary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _onBuyNow(BuildContext context) {
    context.read<CartCubit>().addMultipleToCart([
      CartItemEntity(
        product: widget.product,
        variant: _selectedVariant,
        quantity: _quantity,
      ),
    ]);
    Navigator.of(context).pop();
    context.push('/cart');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final hasVariants = widget.product.variants.length > 1;
    final categoryName = widget.product.category?.title ?? 'ПИЦЦА';

    final selectedSubtitle = _selectedVariant != null
        ? _getVariantSubtitle(_selectedVariant!)
        : null;

    final imageUrl = widget.product.photo.isNotEmpty
        ? widget.product.photo
        : widget.product.thumbnail;

    return Dialog(
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── 1. Rasm bloki ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: imageUrl.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: imageUrl,
                              fit: BoxFit.cover,
                              placeholder: (_, __) =>
                                  const PizzaImagePlaceholder(fit: BoxFit.cover),
                              errorWidget: (_, __, ___) =>
                                  const PizzaImagePlaceholder(fit: BoxFit.cover),
                            )
                          : const PizzaImagePlaceholder(fit: BoxFit.cover),
                    ),
                  ),
                ),

                // ── 2. Ma'lumotlar bloki ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Kategoriya teg (orange / red)
                      Text(
                        categoryName.toUpperCase(),
                        style: AppTextStyles.labelSmall.copyWith(
                          color: const Color(0xFFFF5722),
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                          letterSpacing: 0.6,
                        ),
                      ),
                      const SizedBox(height: 4),

                      // Mahsulot nomi
                      Text(
                        widget.product.title,
                        style: AppTextStyles.h2.copyWith(
                          fontWeight: FontWeight.w800,
                          fontSize: 22,
                          color: isDark ? Colors.white : AppColors.neutral900,
                        ),
                      ),

                      // Tavsif
                      if (widget.product.description != null &&
                          widget.product.description!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          widget.product.description!,
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontSize: 13,
                            height: 1.4,
                            color: isDark
                                ? AppColors.neutral400
                                : AppColors.neutral600,
                          ),
                        ),
                      ],

                      // ── 3. Variantlar (O'lchamlar tanlash) ──
                      if (hasVariants) ...[
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'product.choose'.tr(),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? Colors.white
                                    : AppColors.neutral900,
                              ),
                            ),
                            if (selectedSubtitle != null)
                              Text(
                                selectedSubtitle,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFFFF5722),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // Segmented variant selector
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.neutral900
                                : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDark
                                  ? AppColors.neutral800
                                  : AppColors.neutral200,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: widget.product.variants.map((v) {
                              final isSelected = _selectedVariant?.id == v.id;
                              final title = _getVariantTitle(v.title);
                              final subtitle = _getVariantSubtitle(v);

                              return Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() => _selectedVariant = v);
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 10, horizontal: 4),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? (isDark
                                              ? AppColors.darkSurface
                                              : Colors.white)
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: isSelected
                                          ? [
                                              BoxShadow(
                                                color: Colors.black.withValues(
                                                    alpha: isDark ? 0.3 : 0.08),
                                                blurRadius: 6,
                                                offset: const Offset(0, 2),
                                              ),
                                            ]
                                          : null,
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          title,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: isSelected
                                                ? FontWeight.w800
                                                : FontWeight.w600,
                                            color: isSelected
                                                ? const Color(0xFFFF5722)
                                                : (isDark
                                                    ? Colors.white
                                                    : AppColors.neutral800),
                                          ),
                                        ),
                                        if (subtitle != null) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            subtitle,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: isSelected
                                                  ? FontWeight.w700
                                                  : FontWeight.w400,
                                              color: isSelected
                                                  ? const Color(0xFFFF5722)
                                                  : AppColors.neutral500,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],

                      // Ajratuvchi chiziq
                      Container(
                        height: 1,
                        margin: const EdgeInsets.symmetric(vertical: 16),
                        color: isDark
                            ? AppColors.neutral800
                            : AppColors.neutral200.withValues(alpha: 0.8),
                      ),

                      // ── 4. Narx va Miqdor (Stepper) qatori ──
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Narx
                          Text(
                            '${NumberFormatter.formatSum(_currentPrice * _quantity)} ${'common.currency'.tr()}',
                            style: const TextStyle(
                              color: Color(0xFFFF3D00),
                              fontWeight: FontWeight.w900,
                              fontSize: 22,
                            ),
                          ),

                          // Miqdor Stepper
                          Container(
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.neutral800
                                  : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 4),
                            child: Row(
                              children: [
                                InkWell(
                                  onTap: _quantity > 1
                                      ? () => setState(() => _quantity--)
                                      : null,
                                  borderRadius: BorderRadius.circular(16),
                                  child: Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? AppColors.neutral700
                                          : Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.remove_rounded,
                                      size: 18,
                                      color: _quantity > 1
                                          ? (isDark
                                              ? Colors.white
                                              : AppColors.neutral800)
                                          : AppColors.neutral400,
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14),
                                  child: Text(
                                    '$_quantity',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: isDark
                                          ? Colors.white
                                          : AppColors.neutral900,
                                    ),
                                  ),
                                ),
                                InkWell(
                                  onTap: () => setState(() => _quantity++),
                                  borderRadius: BorderRadius.circular(16),
                                  child: Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? AppColors.neutral700
                                          : Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.add_rounded,
                                      size: 18,
                                      color: isDark
                                          ? Colors.white
                                          : AppColors.neutral800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // ── 5. Amallar tugmalari ("Добавить в корзину" & "Купить сейчас") ──
                      Row(
                        children: [
                          // 1. "Добавить в корзину"
                          Expanded(
                            child: SizedBox(
                              height: 48,
                              child: OutlinedButton(
                                onPressed: () => _onAddToCart(context),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFFFF3D00),
                                  side: const BorderSide(
                                    color: Color(0xFFFF3D00),
                                    width: 1.5,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8),
                                ),
                                child: Text(
                                  'product.add_to_cart_full'.tr(),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFFFF3D00),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),

                          // 2. "Купить сейчас"
                          Expanded(
                            child: SizedBox(
                              height: 48,
                              child: ElevatedButton(
                                onPressed: () => _onBuyNow(context),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFF3D00),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8),
                                ),
                                child: Text(
                                  'product.buy_now'.tr(),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
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

          // ── Yopish (X) tugmasi ──
          Positioned(
            top: 22,
            right: 22,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => Navigator.of(context).pop(),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.neutral800.withValues(alpha: 0.9)
                        : Colors.white.withValues(alpha: 0.9),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: isDark ? Colors.white : AppColors.neutral600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
