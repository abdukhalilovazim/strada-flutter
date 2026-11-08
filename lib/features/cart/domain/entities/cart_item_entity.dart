import 'package:equatable/equatable.dart';
import 'package:pizza_strada/features/home/domain/entities/home_entities.dart';

class CartItemEntity extends Equatable {
  final ProductEntity product;
  final VariantEntity? variant;
  final int quantity;
  final bool isCoupon;
  final int? couponId;

  const CartItemEntity({
    required this.product,
    this.variant,
    this.quantity = 1,
    this.isCoupon = false,
    this.couponId,
  });

  double get unitPrice => variant?.price ?? product.price;
  double get totalPrice => unitPrice * quantity;

  CartItemEntity copyWith({
    ProductEntity? product,
    VariantEntity? variant,
    int? quantity,
    bool? isCoupon,
    int? couponId,
  }) {
    return CartItemEntity(
      product: product ?? this.product,
      variant: variant ?? this.variant,
      quantity: quantity ?? this.quantity,
      isCoupon: isCoupon ?? this.isCoupon,
      couponId: couponId ?? this.couponId,
    );
  }

  @override
  List<Object?> get props => [product, variant, quantity, isCoupon, couponId];
}
