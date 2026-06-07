import 'package:pizza_strada/features/orders/domain/entities/order_entity.dart';

class OrderModel extends OrderEntity {
  const OrderModel({
    required super.id,
    required super.status,
    required super.statusText,
    super.address,
    super.comment,
    super.paymentUrl,
    super.type,
    super.branch,
    super.latitude,
    super.longitude,
    super.paymentMethodText,
    super.paymentMethod,
    required super.subtotalPrice,
    required super.discountAmount,
    required super.deliveryPrice,
    required super.totalPrice,
    required List<OrderItemModel> super.products,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    final rawStatus = json['status'];
    int statusInt = 0;
    String statusTextStr = '';

    if (rawStatus is int) {
      statusInt = rawStatus;
    } else if (rawStatus is String) {
      statusTextStr = rawStatus;
      // Map common string values to integer status for UI coloring/actions
      final lower = rawStatus.toLowerCase();
      if (lower.contains('tugat') || lower.contains('complet') || lower.contains('done') || lower.contains('yopildi') || lower.contains('success')) {
        statusInt = 6;
      } else if (lower.contains('rad') || lower.contains('reject') || lower.contains('cancel') || lower.contains('bekor')) {
        statusInt = 1;
      } else if (lower.contains('yo\'l') || lower.contains('yol') || lower.contains('sent') || lower.contains('progress') || lower.contains('tayyorlan') || lower.contains('accept') || lower.contains('prepar')) {
        statusInt = 4;
      } else {
        statusInt = 0;
      }
    }

    if (json['status_text'] is String && (json['status_text'] as String).isNotEmpty) {
      statusTextStr = json['status_text'] as String;
    } else {
      switch (statusInt) {
        case 6:
          statusTextStr = 'orders.status_completed';
          break;
        case 1:
          statusTextStr = 'orders.status_rejected';
          break;
        default:
          statusTextStr = 'orders.status_pending';
          break;
      }
    }

    return OrderModel(
      id: int.tryParse(json['order_id']?.toString() ?? '0') ?? 0,
      status: statusInt,
      statusText: statusTextStr,
      address: json['address'] as String?,
      comment: json['comment'] as String?,
      paymentUrl: json['payment_url'] as String?,
      type: json['type'] as String?,
      branch: json['branch'] as String?,
      latitude: double.tryParse(json['latitude']?.toString() ?? ''),
      longitude: double.tryParse(json['longitude']?.toString() ?? ''),
      paymentMethodText: json['payment_method_text'] as String?,
      paymentMethod: json['payment_method']?.toString(),
      subtotalPrice: double.tryParse(json['subtotal_price']?.toString() ?? '0') ?? 0.0,
      discountAmount: double.tryParse(json['discount_amount']?.toString() ?? '0') ?? 0.0,
      deliveryPrice: double.tryParse(json['delivery_price']?.toString() ?? '0') ?? 0.0,
      totalPrice: double.tryParse(json['total_price']?.toString() ?? '0') ?? 0.0,
      products: (json['products'] as List? ?? []).map((e) => OrderItemModel.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}

class OrderItemModel extends OrderItemEntity {
  const OrderItemModel({
    required super.slug,
    required super.title,
    required super.image,
    super.variantName,
    required super.quantity,
    required super.price,
    required super.totalAmount,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) => OrderItemModel(
        slug: json['slug'] as String? ?? '',
        title: json['title'] as String? ?? '',
        image: json['image'] as String? ?? '',
        variantName: json['variant'] as String?,
        quantity: json['quantity'] as int? ?? 1,
        price: double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,
        totalAmount: double.tryParse(json['total_amount']?.toString() ?? '0') ?? 0.0,
      );
}
