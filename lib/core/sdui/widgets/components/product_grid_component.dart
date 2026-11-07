import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../features/cart/presentation/bloc/cart_cubit.dart';
import '../../../../features/home/domain/entities/home_entities.dart';
import '../../../../features/home/presentation/widgets/product_card.dart';
import '../../../../features/home/presentation/widgets/product_detail_modal.dart';
import '../../models/component_model.dart';
import '../../models/section_model.dart';
import '../../registry/action_dispatcher.dart';

class SDUIProductGridComponent extends StatelessWidget {
  final SDUISectionModel section;
  final SDUIActionHandler onAction;

  const SDUIProductGridComponent({
    super.key,
    required this.section,
    required this.onAction,
  });

  static String _cleanImageUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    final lower = url.toLowerCase();
    if (lower.contains('logo.png') ||
        lower.contains('default.png') ||
        lower.contains('no-image') ||
        lower.contains('no_image') ||
        lower.contains('placeholder') ||
        lower.contains('images/logo')) {
      return '';
    }
    return url;
  }

  ProductEntity _parseProduct(SDUIComponentModel item) {
    final props = item.properties;
    final catMap = props['category'] as Map<String, dynamic>?;

    final rawThumb = props['thumbnail']?.toString() ?? props['photo']?.toString() ?? '';
    final rawPhoto = props['photo']?.toString() ?? props['thumbnail']?.toString() ?? '';
    final cleanThumb = _cleanImageUrl(rawThumb);
    final cleanPhoto = _cleanImageUrl(rawPhoto);

    final rawBadges = props['badges'] as List<dynamic>?;
    final badgesList = rawBadges?.map((b) {
      if (b is Map<String, dynamic>) {
        return ProductBadgeEntity(
          text: b['text']?.toString() ?? '',
          type: b['type']?.toString() ?? 'discount',
          bgColor: b['bg_color']?.toString(),
          textColor: b['text_color']?.toString(),
        );
      }
      return ProductBadgeEntity(text: b.toString());
    }).toList() ?? const [];

    return ProductEntity(
      id: (props['id'] as num?)?.toInt() ?? 0,
      slug: props['slug']?.toString() ?? item.id,
      title: props['title']?.toString() ?? '',
      description: props['description']?.toString(),
      thumbnail: cleanThumb,
      photo: cleanPhoto.isNotEmpty ? cleanPhoto : cleanThumb,
      price: (props['price'] as num?)?.toDouble() ?? 0.0,
      oldPrice: (props['old_price'] as num?)?.toDouble(),
      badges: badgesList,
      category: catMap != null
          ? CategoryEntity(
              slug: catMap['slug']?.toString() ?? '',
              title: catMap['title']?.toString() ?? '',
            )
          : null,
      variants: (props['variants'] as List<dynamic>?)
              ?.map((v) => VariantEntity(
                    id: (v['id'] as num?)?.toInt() ?? 0,
                    title: v['title']?.toString() ?? '',
                    price: (v['price'] as num?)?.toDouble() ?? 0.0,
                  ))
              .toList() ??
          const [],
      values: const [],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (section.items.isEmpty) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
          child: Center(
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
                    child: Icon(
                      Icons.search_off_rounded,
                      size: 32,
                      color: AppColors.neutral400,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'home.search_empty'.tr(),
                  style: AppTextStyles.h4.copyWith(
                    color: isDark ? Colors.white : AppColors.neutral800,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  'home.search_empty_desc'.tr(),
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.neutral500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    final columns = (section.properties['columns'] as num?)?.toInt() ?? 2;
    final childAspectRatio = (section.properties['child_aspect_ratio'] as num?)?.toDouble() ?? 0.68;
    final spacing = (section.properties['spacing'] as num?)?.toDouble() ?? 16.0;
    final bottomPadding = (section.properties['bottom_padding'] as num?)?.toDouble() ?? 100.0;

    return SliverPadding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, bottomPadding),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          mainAxisSpacing: spacing,
          crossAxisSpacing: spacing,
          childAspectRatio: childAspectRatio,
        ),
        delegate: SliverChildBuilderDelegate(
          (ctx, i) {
            final item = section.items[i];
            final product = _parseProduct(item);

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
                      if (product.variants.length > 1) {
                        ProductDetailModal.show(context, product);
                      } else {
                        context.push('/product/${product.slug}', extra: product);
                      }
                    },
                    onAdd: () {
                      if (product.variants.length > 1) {
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
          childCount: section.items.length,
        ),
      ),
    );
  }
}
