import 'package:equatable/equatable.dart';
import 'package:pizza_strada/features/home/domain/entities/home_entities.dart';

class CartItemEntity extends Equatable {
  final ProductEntity product;
  final VariantEntity? variant;
  final int quantity;

  const CartItemEntity({
    required this.product,
    this.variant,
    this.quantity = 1,
  });

  double get totalPrice => (variant?.price ?? product.price) * quantity;

  CartItemEntity copyWith({
    ProductEntity? product,
    VariantEntity? variant,
    int? quantity,
  }) {
    return CartItemEntity(
      product: product ?? this.product,
      variant: variant ?? this.variant,
      quantity: quantity ?? this.quantity,
    );
  }

  @override
  List<Object?> get props => [product, variant, quantity];
}
