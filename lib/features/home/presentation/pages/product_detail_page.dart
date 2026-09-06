import 'package:easy_localization/easy_localization.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pizza_strada/core/services/analytics_service.dart';
import 'package:pizza_strada/core/theme/app_colors.dart';
import 'package:pizza_strada/core/theme/app_text_styles.dart';
import 'package:pizza_strada/core/utils/number_formatter.dart';
import 'package:pizza_strada/features/cart/presentation/bloc/cart_cubit.dart';
import 'package:pizza_strada/features/home/domain/entities/home_entities.dart';

class ProductDetailPage extends StatefulWidget {
  final String slug;
  final ProductEntity? product;

  const ProductDetailPage({super.key, required this.slug, this.product});

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  VariantEntity? _selectedVariant;
  int _quantity = 1;

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      if (widget.product!.variants.length == 1) {
        _selectedVariant = widget.product!.variants.first;
      }
      AnalyticsService.instance.logProductView(
        id: widget.product!.id.toString(),
        title: widget.product!.title,
        price: widget.product!.price,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.product == null) {
      return Scaffold(body: Center(child: Text('error.not_found'.tr())));
    }

    final product = widget.product!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasVariants = product.variants.length > 1;
    final displayPrice = _selectedVariant?.price ?? product.price;
    final totalPrice = displayPrice * _quantity;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          // ── SliverAppBar (rasm katta, tepalikda) ──
          SliverAppBar(
            expandedHeight: MediaQuery.of(context).size.width,
            pinned: true,
            backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
            surfaceTintColor: Colors.transparent,
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkSurface.withValues(alpha: 0.9)
                    : Colors.white.withValues(alpha: 0.9),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 18,
                  color: isDark ? Colors.white : AppColors.neutral900,
                ),
                onPressed: () => context.pop(),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color:
                    isDark ? AppColors.neutral800 : const Color(0xFFF8F9FA),
                padding: const EdgeInsets.all(24),
                child: CachedNetworkImage(
                  imageUrl: product.photo.isNotEmpty
                      ? product.photo
                      : product.thumbnail,
                  fit: BoxFit.contain,
                  placeholder: (_, __) => Container(
                      color: isDark
                          ? AppColors.neutral800
                          : const Color(0xFFF8F9FA)),
                  errorWidget: (_, __, ___) => Icon(
                    Icons.image_not_supported_outlined,
                    size: 64,
                    color: AppColors.neutral400,
                  ),
                ),
              ),
            ),
          ),

          // ── Kontent ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nom + narx
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          product.title,
                          style: AppTextStyles.h2.copyWith(
                            color: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.color,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (product.oldPrice != null &&
                              product.oldPrice! > displayPrice)
                            Text(
                              '${NumberFormatter.formatSum(product.oldPrice!)} ${'common.currency'.tr()}',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.neutral400,
                                decoration: TextDecoration.lineThrough,
                                decorationColor: AppColors.neutral400,
                              ),
                            ),
                          Text(
                            '${NumberFormatter.formatSum(displayPrice)} ${'common.currency'.tr()}',
                            style: AppTextStyles.h3.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  if (product.description != null &&
                      product.description!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      product.description!,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color:
                            isDark ? AppColors.neutral400 : AppColors.neutral600,
                        height: 1.6,
                      ),
                    ),
                  ],

                  // ── Variantlar ──
                  if (hasVariants) ...[
                    const SizedBox(height: 24),
                    Text(
                      'product.size'.tr(),
                      style: AppTextStyles.labelLarge.copyWith(
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: product.variants.map((v) {
                        final isSelected = _selectedVariant?.id == v.id;
                        return InkWell(
                          onTap: () =>
                              setState(() => _selectedVariant = v),
                          borderRadius: BorderRadius.circular(16),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 18, vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primary
                                  : Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primary
                                    : (isDark
                                        ? AppColors.neutral700
                                        : AppColors.neutral200),
                                width: 1.5,
                              ),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  v.title,
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: isSelected
                                        ? Colors.white
                                        : Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.color,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  '${NumberFormatter.formatSum(v.price)} ${'common.currency'.tr()}',
                                  style: AppTextStyles.bodyExtraSmall
                                      .copyWith(
                                    color: isSelected
                                        ? Colors.white.withValues(alpha: 0.8)
                                        : AppColors.neutral400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],

                  // ── Qo'shimcha ma'lumotlar ──
                  if (product.values.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Text(
                      'product.info'.tr(),
                      style: AppTextStyles.labelLarge.copyWith(
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark
                              ? AppColors.neutral800
                              : AppColors.neutral200,
                        ),
                      ),
                      child: Column(
                        children: product.values.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final kv = entry.value;
                          return Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      kv.key,
                                      style: AppTextStyles.bodyMedium
                                          .copyWith(
                                              color: AppColors.neutral500),
                                    ),
                                    Text(
                                      kv.value,
                                      style: AppTextStyles.labelSmall
                                          .copyWith(
                                        color: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.color,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (idx < product.values.length - 1)
                                Divider(
                                  height: 1,
                                  color: isDark
                                      ? AppColors.neutral800
                                      : AppColors.neutral200,
                                ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ],

                  const SizedBox(height: 100), // bottomBar uchun joy
                ],
              ),
            ),
          ),
        ],
      ),

      // ── Bottom Bar: Stepper + Savatga qo'shish ──
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          border: Border(
            top: BorderSide(
              color: isDark ? AppColors.neutral800 : AppColors.neutral200,
              width: 1,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              // Miqdor stepperi
              Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isDark ? AppColors.neutral700 : AppColors.neutral200,
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        if (_quantity > 1) {
                          setState(() => _quantity--);
                        }
                      },
                      child: Container(
                        width: 42,
                        height: 42,
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.remove_rounded,
                          size: 18,
                          color: _quantity > 1
                              ? AppColors.neutral700
                              : AppColors.neutral300,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 32,
                      child: Text(
                        '$_quantity',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.labelMedium.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => setState(() => _quantity++),
                      child: Container(
                        width: 42,
                        height: 42,
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.add_rounded,
                          size: 18,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),

              // Savatga qo'shish tugmasi
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      if (hasVariants && _selectedVariant == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('product.select_variant_error'.tr()),
                            backgroundColor: AppColors.error,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        );
                        return;
                      }
                      for (int i = 0; i < _quantity; i++) {
                        context.read<CartCubit>().addToCart(
                              product,
                              variant: _selectedVariant,
                            );
                      }
                      AnalyticsService.instance.logAddToCart(
                        id: product.id.toString(),
                        title: product.title,
                        quantity: _quantity,
                        price: displayPrice,
                        variant: _selectedVariant?.title,
                      );
                      context.pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('product.added'.tr()),
                          backgroundColor: AppColors.success,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      minimumSize: const Size(0, 48),
                    ),
                    child: Text(
                      '${'product.add_to_cart'.tr()} • ${NumberFormatter.formatSum(totalPrice)} ${'common.currency'.tr()}',
                      overflow: TextOverflow.ellipsis,
                    ),
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
