import 'package:pizza_strada/features/home/domain/entities/home_entities.dart';

class CartItemEntity {
  final ProductEntity product;
  final VariantEntity? variant;
  int quantity;

  CartItemEntity({
    required this.product,
    this.variant,
    this.quantity = 1,
  });

  double get totalPrice => (variant?.price ?? product.price) * quantity;
}
