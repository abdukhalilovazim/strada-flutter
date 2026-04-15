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
  final double subtotalPrice;
  final double discountAmount;
  final double deliveryPrice;
  final double totalPrice;
  final List<OrderItemEntity> products;

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
    required this.subtotalPrice,
    required this.discountAmount,
    required this.deliveryPrice,
    required this.totalPrice,
    required this.products,
  });
}

class OrderItemEntity {
  final String slug;
  final String title;
  final String image;
  final String? variantName;
  final int quantity;
  final double price;
  final double totalAmount;

  const OrderItemEntity({
    required this.slug,
    required this.title,
    required this.image,
    this.variantName,
    required this.quantity,
    required this.price,
    required this.totalAmount,
  });
}
