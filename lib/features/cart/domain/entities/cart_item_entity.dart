import 'package:equatable/equatable.dart';
import 'package:pizza_strada/features/home/domain/entities/home_entities.dart';
import 'package:pizza_strada/features/sets/data/models/set_detail_model.dart';

class CartItemEntity extends Equatable {
  final ProductEntity product;
  final VariantEntity? variant;
  final int quantity;
  final bool isCoupon;
  final int? couponId;
  final bool isSet;
  final int? setId;
  final List<SetSelectionItem>? setSelections;

  const CartItemEntity({
    required this.product,
    this.variant,
    this.quantity = 1,
    this.isCoupon = false,
    this.couponId,
    this.isSet = false,
    this.setId,
    this.setSelections,
  });

  double get unitPrice => variant?.price ?? product.price;
  double get totalPrice => unitPrice * quantity;

  CartItemEntity copyWith({
    ProductEntity? product,
    VariantEntity? variant,
    int? quantity,
    bool? isCoupon,
    int? couponId,
    bool? isSet,
    int? setId,
    List<SetSelectionItem>? setSelections,
  }) {
    return CartItemEntity(
      product: product ?? this.product,
      variant: variant ?? this.variant,
      quantity: quantity ?? this.quantity,
      isCoupon: isCoupon ?? this.isCoupon,
      couponId: couponId ?? this.couponId,
      isSet: isSet ?? this.isSet,
      setId: setId ?? this.setId,
      setSelections: setSelections ?? this.setSelections,
    );
  }

  @override
  List<Object?> get props => [
        product,
        variant,
        quantity,
        isCoupon,
        couponId,
        isSet,
        setId,
        setSelections,
      ];
}
