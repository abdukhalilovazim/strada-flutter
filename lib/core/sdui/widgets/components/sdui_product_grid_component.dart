import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../features/cart/presentation/bloc/cart_cubit.dart';
import '../../../../features/home/domain/entities/home_entities.dart';
import '../../../../features/home/presentation/widgets/product_card.dart';
import '../../../../features/home/presentation/widgets/product_detail_modal.dart';
import '../../models/sdui_component_model.dart';
import '../../models/sdui_section_model.dart';
import '../../registry/sdui_action_dispatcher.dart';

class SDUIProductGridComponent extends StatelessWidget {
  final SDUISectionModel section;
  final SDUIActionHandler onAction;

  const SDUIProductGridComponent({
    super.key,
    required this.section,
    required this.onAction,
  });

  ProductEntity _parseProduct(SDUIComponentModel item) {
    final props = item.properties;
    final catMap = props['category'] as Map<String, dynamic>?;

    return ProductEntity(
      slug: props['slug']?.toString() ?? item.id,
      title: props['title']?.toString() ?? '',
      description: props['description']?.toString(),
      thumbnail: props['thumbnail']?.toString() ?? props['photo']?.toString() ?? '',
      photo: props['photo']?.toString() ?? props['thumbnail']?.toString() ?? '',
      price: (props['price'] as num?)?.toDouble() ?? 0.0,
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
    if (section.items.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());

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
                      } else if (item.action != null) {
                        onAction(item.action!);
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
