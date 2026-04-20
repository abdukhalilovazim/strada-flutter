import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:pizza_strada/features/cart/domain/entities/cart_item_entity.dart';
import 'package:pizza_strada/features/home/domain/entities/home_entities.dart';

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
        item.product.slug == product.slug && item.variant?.id == variant?.id);

    if (index != -1) {
      items[index] = items[index].copyWith(quantity: items[index].quantity + 1);
    } else {
      items.add(CartItemEntity(product: product, variant: variant));
    }
    emit(CartState(items: items));
  }

  void removeFromCart(CartItemEntity item) {
    final items = List<CartItemEntity>.from(state.items);
    items.removeWhere((i) => i.product.slug == item.product.slug && i.variant?.id == item.variant?.id);
    emit(CartState(items: items));
  }

  void updateQuantity(CartItemEntity item, int delta) {
    final items = List<CartItemEntity>.from(state.items);
    final index = items.indexWhere((i) =>
        i.product.slug == item.product.slug && i.variant?.id == item.variant?.id);

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

  void clear() {
    emit(const CartState(items: []));
  }
}
