import 'package:pizza_strada/features/home/data/models/home_models.dart';
import 'package:pizza_strada/features/orders/domain/entities/order_entity.dart';

class OrderModel extends OrderEntity {
  const OrderModel({
    required super.number,
    required super.status,
    required super.total,
    required super.date,
    required List<OrderItemModel> super.products,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) => OrderModel(
    number: json['number'] as int,
    status: json['status'] as String,
    total: (json['total'] as num).toDouble(),
    date: DateTime.parse(json['date'] as String),
    products: (json['products'] as List).map((e) => OrderItemModel.fromJson(e)).toList(),
  );
}

class OrderItemModel extends OrderItemEntity {
  const OrderItemModel({
    required super.product,
    super.variant,
    required super.quantity,
    required super.price,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) => OrderItemModel(
    product: ProductModel.fromJson(json['product']),
    variant: json['variant'] != null ? VariantModel.fromJson(json['variant']) : null,
    quantity: json['quantity'] as int,
    price: (json['price'] as num).toDouble(),
  );
}
