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
import 'package:pizza_strada/core/widgets/pizza_image_placeholder.dart';
import 'package:pizza_strada/features/cart/domain/entities/cart_item_entity.dart';
import 'package:pizza_strada/features/cart/presentation/bloc/cart_cubit.dart';
import 'package:pizza_strada/features/home/domain/entities/home_entities.dart';
import 'package:pizza_strada/features/home/presentation/bloc/home_cubit.dart';

/// 🍕 Modal popup for product detail & variant selection.
/// Built strictly conforming to ui-ux-design tokens.
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
    return VariantLocalizationHelper.localizeMainTitle(raw);
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _onBuyNow(BuildContext context) {
    HapticFeedback.mediumImpact();
    context.read<CartCubit>().addMultipleToCart([
      CartItemEntity(
        product: widget.product,
        variant: _selectedVariant,
        quantity: _quantity,
      ),
    ]);
    Navigator.of(context).pop();
    context.push('/checkout');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final displayVariants = widget.product.variants
        .where((v) => VariantLocalizationHelper.localize(v.title).isNotEmpty)
        .toList();
    final hasVariants = displayVariants.length > 1;
    final categoryName = widget.product.category?.title ?? 'PITSA';

    final selectedSubtitle = _selectedVariant != null
        ? _getVariantSubtitle(_selectedVariant!)
        : null;

    final hasValidImage = widget.product.hasValidImage;
    final imageUrl = widget.product.validImageUrl;

    return Dialog(
      backgroundColor: isDark ? AppColors.darkCard : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
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
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: hasValidImage
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
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Kategoriya teg
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          categoryName.toUpperCase(),
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w800,
                            fontSize: 11,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Mahsulot nomi
                      Text(
                        widget.product.title,
                        style: AppTextStyles.h2.copyWith(
                          fontWeight: FontWeight.w800,
                          fontSize: 22,
                          color: isDark ? Colors.white : AppColors.neutral900,
                        ),
                      ),

                      // Tavsif (Description)
                      Builder(
                        builder: (ctx) {
                          final desc = (widget.product.description != null &&
                                  widget.product.description!.trim().isNotEmpty)
                              ? widget.product.description!.trim()
                              : () {
                                  try {
                                    final homeState = ctx.read<HomeCubit>().state;
                                    if (homeState is HomeLoaded) {
                                      return homeState.fullProducts
                                          .firstWhere((p) => p.slug == widget.product.slug)
                                          .description
                                          ?.trim();
                                    }
                                  } catch (_) {}
                                  return null;
                                }();

                          if (desc == null || desc.isEmpty) {
                            return const SizedBox.shrink();
                          }

                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              desc,
                              style: AppTextStyles.bodyMedium.copyWith(
                                fontSize: 13.5,
                                height: 1.45,
                                color: isDark
                                    ? AppColors.neutral400
                                    : AppColors.neutral600,
                              ),
                            ),
                          );
                        },
                      ),

                      // ── 3. Variantlar (O'lchamlar tanlash) ──
                      if (hasVariants) ...[
                        const SizedBox(height: 18),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'product.choose'.tr(),
                              style: AppTextStyles.labelMedium.copyWith(
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? Colors.white
                                    : AppColors.neutral900,
                              ),
                            ),
                            if (selectedSubtitle != null)
                              Text(
                                selectedSubtitle,
                                style: AppTextStyles.labelSmall.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
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
                                : AppColors.neutral100,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDark
                                  ? AppColors.darkBorder
                                  : AppColors.neutral200.withValues(alpha: 0.7),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: displayVariants.map((v) {
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
                                              ? AppColors.darkCard
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
                                          style: AppTextStyles.labelMedium.copyWith(
                                            fontSize: 13,
                                            fontWeight: isSelected
                                                ? FontWeight.w800
                                                : FontWeight.w600,
                                            color: isSelected
                                                ? AppColors.primary
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
                                            style: AppTextStyles.bodySmall.copyWith(
                                              fontSize: 11,
                                              fontWeight: isSelected
                                                  ? FontWeight.w700
                                                  : FontWeight.w500,
                                              color: isSelected
                                                  ? AppColors.primary
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
                            ? AppColors.darkBorder
                            : AppColors.neutral200.withValues(alpha: 0.8),
                      ),

                      // ── 4. Narx va Miqdor (Stepper) qatori ──
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Narx
                          Text(
                            '${NumberFormatter.formatSum(_currentPrice * _quantity)} ${'common.currency'.tr()}',
                            style: AppTextStyles.priceLarge.copyWith(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                            ),
                          ),

                          // Miqdor Stepper
                          Container(
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.neutral800
                                  : AppColors.neutral100,
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
                                    style: AppTextStyles.labelLarge.copyWith(
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
                      const SizedBox(height: 18),

                      // ── 5. Amallar tugmalari ("Добавить в корзину" & "Купить сейчас") ──
                      Row(
                        children: [
                          // 1. "Добавить в корзину"
                          Expanded(
                            child: SizedBox(
                              height: 50,
                              child: OutlinedButton(
                                onPressed: () => _onAddToCart(context),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.primary,
                                  side: const BorderSide(
                                    color: AppColors.primary,
                                    width: 1.5,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8),
                                ),
                                child: Text(
                                  'product.add_to_cart_full'.tr(),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.labelMedium.copyWith(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),

                          // 2. "Купить сейчас"
                          Expanded(
                            child: SizedBox(
                              height: 50,
                              child: ElevatedButton(
                                onPressed: () => _onBuyNow(context),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8),
                                ),
                                child: Text(
                                  'product.buy_now'.tr(),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.labelMedium.copyWith(
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
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.neutral800.withValues(alpha: 0.9)
                        : Colors.white.withValues(alpha: 0.9),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.close_rounded,
                    size: 20,
                    color: isDark ? Colors.white : AppColors.neutral700,
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
