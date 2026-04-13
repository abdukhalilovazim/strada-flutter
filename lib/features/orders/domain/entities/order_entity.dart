import 'package:pizza_strada/features/home/domain/entities/home_entities.dart';

class OrderEntity {
  final int number;
  final String status;
  final double total;
  final DateTime date;
  final List<OrderItemEntity> products;

  const OrderEntity({
    required this.number,
    required this.status,
    required this.total,
    required this.date,
    required this.products,
  });
}

class OrderItemEntity {
  final ProductEntity product;
  final VariantEntity? variant;
  final int quantity;
  final double price;

  const OrderItemEntity({
    required this.product,
    this.variant,
    required this.quantity,
    required this.price,
  });
}
