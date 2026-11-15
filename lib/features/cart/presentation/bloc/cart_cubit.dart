import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:pizza_strada/core/services/smart_recommendation_engine.dart';
import 'package:pizza_strada/features/cart/domain/entities/cart_item_entity.dart';
import 'package:pizza_strada/features/home/domain/entities/home_entities.dart';
import 'package:pizza_strada/features/promotions/domain/entities/promotion_deal_entity.dart';
import 'package:pizza_strada/features/sets/data/models/set_detail_model.dart';

class CartState extends Equatable {
  final List<CartItemEntity> items;

  const CartState({required this.items});

  double get subtotal => items.fold(0, (sum, item) => sum + item.totalPrice);
  int get totalQuantity => items.fold(0, (sum, item) => sum + item.quantity);

  @override
  List<Object?> get props => [items];
}

@lazySingleton
class CartCubit extends Cubit<CartState> {
  CartCubit() : super(const CartState(items: []));

  void addToCart(ProductEntity product, {VariantEntity? variant}) {
    final items = List<CartItemEntity>.from(state.items);
    final index = items.indexWhere((item) =>
        !item.isCoupon && item.product.slug == product.slug && item.variant?.id == variant?.id);

    if (index != -1) {
      items[index] = items[index].copyWith(quantity: items[index].quantity + 1);
    } else {
      items.add(CartItemEntity(product: product, variant: variant));
    }
    emit(CartState(items: items));
  }

  void addCouponToCart(PromotionDealEntity deal) {
    final items = List<CartItemEntity>.from(state.items);
    final index = items.indexWhere((item) =>
        item.isCoupon && item.couponId == deal.id);

    if (index != -1) {
      items[index] = items[index].copyWith(quantity: items[index].quantity + 1);
    } else {
      items.add(CartItemEntity(
        product: deal.toProductEntity(),
        quantity: 1,
        isCoupon: true,
        couponId: deal.id,
      ));
    }
    emit(CartState(items: items));
  }

  void addSetToCart(SetDetailModel set, List<SetSelectionItem> selections, {int quantity = 1}) {
    final items = List<CartItemEntity>.from(state.items);
    items.add(CartItemEntity(
      product: ProductEntity(
        id: 999999 + set.id,
        slug: set.slug,
        title: set.title,
        description: set.description,
        thumbnail: set.imageUrl,
        photo: set.imageUrl,
        price: set.price,
        variants: const [],
        values: const [],
        isSet: true,
      ),
      quantity: quantity,
      isSet: true,
      setId: set.id,
      setSelections: selections,
    ));
    emit(CartState(items: items));
  }

  void removeFromCart(CartItemEntity item) {
    final items = List<CartItemEntity>.from(state.items);
    items.removeWhere((i) {
      if (item.isSet) {
        return i.isSet && i.setId == item.setId && i.setSelections == item.setSelections;
      }
      if (item.isCoupon) {
        return i.isCoupon && i.couponId == item.couponId;
      }
      return !i.isCoupon && !i.isSet && i.product.slug == item.product.slug && i.variant?.id == item.variant?.id;
    });
    emit(CartState(items: items));
  }

  void updateQuantity(CartItemEntity item, int delta) {
    final items = List<CartItemEntity>.from(state.items);
    final index = items.indexWhere((i) {
      if (item.isSet) {
        return i.isSet && i.setId == item.setId && i.setSelections == item.setSelections;
      }
      if (item.isCoupon) {
        return i.isCoupon && i.couponId == item.couponId;
      }
      return !i.isCoupon && !i.isSet && i.product.slug == item.product.slug && i.variant?.id == item.variant?.id;
    });

    if (index != -1) {
      final newQuantity = items[index].quantity + delta;
      if (newQuantity <= 0) {
        items.removeAt(index);
      } else {
        items[index] = items[index].copyWith(quantity: newQuantity);
      }
      emit(CartState(items: items));
    }
  }

  void addMultipleToCart(List<CartItemEntity> newItems) {
    final items = List<CartItemEntity>.from(state.items);
    for (final newItem in newItems) {
      final index = items.indexWhere((item) =>
          item.product.slug == newItem.product.slug && item.variant?.id == newItem.variant?.id);
      if (index != -1) {
        items[index] = items[index].copyWith(quantity: items[index].quantity + newItem.quantity);
      } else {
        items.add(newItem);
      }
    }
    emit(CartState(items: items));
  }

  void syncWithProducts(List<ProductEntity> freshProducts) {
    if (state.items.isEmpty || freshProducts.isEmpty) return;

    final productMap = <int, ProductEntity>{};
    final slugMap = <String, ProductEntity>{};
    for (final p in freshProducts) {
      if (p.id != 0) productMap[p.id] = p;
      if (p.slug.isNotEmpty) slugMap[p.slug] = p;
    }

    bool changed = false;
    final updatedItems = state.items.map((item) {
      if (item.isCoupon) return item;

      if (item.isSet) {
        final fresh = productMap[item.product.id] ?? slugMap[item.product.slug];
        if (fresh != null &&
            (item.product.title != fresh.title || item.product.description != fresh.description)) {
          changed = true;
          return item.copyWith(
            product: item.product.copyWith(
              title: fresh.title,
              description: fresh.description,
              thumbnail: fresh.thumbnail.isNotEmpty ? fresh.thumbnail : item.product.thumbnail,
              photo: fresh.photo.isNotEmpty ? fresh.photo : item.product.photo,
            ),
          );
        }
        return item;
      }

      final fresh = productMap[item.product.id] ?? slugMap[item.product.slug];
      if (fresh == null) return item;

      VariantEntity? freshVariant = item.variant;
      if (item.variant != null && fresh.variants.isNotEmpty) {
        for (final v in fresh.variants) {
          if (v.id == item.variant!.id) {
            freshVariant = v;
            break;
          }
        }
      }

      if (item.product.title != fresh.title ||
          item.product.description != fresh.description ||
          (freshVariant != null && freshVariant.title != item.variant?.title)) {
        changed = true;
        return item.copyWith(
          product: fresh,
          variant: freshVariant,
        );
      }
      return item;
    }).toList();

    if (changed) {
      emit(CartState(items: updatedItems));
    }
  }

  void clear() {
    SmartRecommendationEngine.clear();
    emit(const CartState(items: []));
  }

  void clearCart() => clear();

  void loadReorderItems(List<dynamic> rawItems) {
    clear();
    final items = <CartItemEntity>[];
    for (final raw in rawItems) {
      if (raw is! Map<String, dynamic>) continue;
      final product = ProductEntity(
        id: (raw['product_id'] as num?)?.toInt() ?? 0,
        slug: raw['slug'] as String? ?? '',
        title: raw['title'] as String? ?? '',
        thumbnail: raw['image'] as String? ?? '',
        photo: raw['image'] as String? ?? '',
        price: (raw['price'] as num?)?.toDouble() ?? 0.0,
        variants: const [],
        values: const [],
      );

      VariantEntity? variant;
      if (raw['variant_id'] != null) {
        final vTitle = raw['variant_title'] as String? ?? '';
        final isSize = vTitle.trim().toLowerCase() == 'size' ||
            vTitle.trim().toLowerCase() == "o'lcham" ||
            vTitle.trim().toLowerCase() == 'размер';
        variant = VariantEntity(
          id: (raw['variant_id'] as num).toInt(),
          title: isSize ? '' : vTitle,
          price: (raw['price'] as num?)?.toDouble() ?? 0.0,
        );
      }

      final qty = (raw['quantity'] as num?)?.toInt() ?? 1;
      items.add(CartItemEntity(
        product: product,
        variant: variant,
        quantity: qty,
      ));
    }
    emit(CartState(items: items));
  }
}
