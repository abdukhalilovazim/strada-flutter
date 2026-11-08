class OrderEntity {
  final int id;
  final int status;
  final String statusText;
  final String? address;
  final String? comment;
  final String? paymentUrl;
  final String? type;
  final String? branch;
  final double? latitude;
  final double? longitude;
  final String? paymentMethodText;
  final String? paymentMethod;
  final String? phone;
  final String? estimatedTime;
  final double subtotalPrice;
  final double discountAmount;
  final double deliveryPrice;
  final double totalPrice;
  final List<OrderItemEntity> products;
  final List<OrderDetailItemEntity> details;
  final List<OrderDetailItemEntity> priceDetails;
  final int? itemsCount;
  final String? createdAt;
  final bool canReorder;
  final String? reorderMessage;

  const OrderEntity({
    required this.id,
    required this.status,
    required this.statusText,
    this.address,
    this.comment,
    this.paymentUrl,
    this.type,
    this.branch,
    this.latitude,
    this.longitude,
    this.paymentMethodText,
    this.paymentMethod,
    this.phone,
    this.estimatedTime,
    required this.subtotalPrice,
    required this.discountAmount,
    required this.deliveryPrice,
    required this.totalPrice,
    required this.products,
    this.details = const [],
    this.priceDetails = const [],
    this.itemsCount,
    this.createdAt,
    this.canReorder = false,
    this.reorderMessage,
  });
}

/// 📋 Backend tomonidan to'liq boshqariladigan Key-Value qatori
class OrderDetailItemEntity {
  final String key;
  final String value;
  final bool bold;
  final String? mapUrl;
  final double? latitude;
  final double? longitude;
  final String? phone;
  final bool isDiscount;

  const OrderDetailItemEntity({
    required this.key,
    required this.value,
    this.bold = false,
    this.mapUrl,
    this.latitude,
    this.longitude,
    this.phone,
    this.isDiscount = false,
  });

  factory OrderDetailItemEntity.fromJson(Map<String, dynamic> json) {
    return OrderDetailItemEntity(
      key: json['key']?.toString() ?? '',
      value: json['value']?.toString() ?? '',
      bold: json['bold'] == true || json['bold'] == 1 || json['bold'] == 'true',
      mapUrl: json['map_url']?.toString(),
      latitude: (json['latitude'] as num?)?.toDouble() ??
          double.tryParse(json['latitude']?.toString() ?? ''),
      longitude: (json['longitude'] as num?)?.toDouble() ??
          double.tryParse(json['longitude']?.toString() ?? ''),
      phone: json['phone']?.toString(),
      isDiscount: json['is_discount'] == true,
    );
  }
}

class OrderItemEntity {
  final int productId;
  final String slug;
  final String title;
  final String image;
  final int? variantId;
  final String? variantName;
  final int quantity;
  final double price;
  final double totalAmount;

  const OrderItemEntity({
    this.productId = 0,
    required this.slug,
    required this.title,
    required this.image,
    this.variantId,
    this.variantName,
    required this.quantity,
    required this.price,
    required this.totalAmount,
  });
}
