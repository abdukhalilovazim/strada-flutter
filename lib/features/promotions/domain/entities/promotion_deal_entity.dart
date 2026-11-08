import 'package:equatable/equatable.dart';
import 'package:pizza_strada/features/home/domain/entities/home_entities.dart';

class PromotionDealItemEntity extends Equatable {
  final String productTitle;
  final String variantTitle;
  final int quantity;

  const PromotionDealItemEntity({
    required this.productTitle,
    this.variantTitle = '',
    this.quantity = 1,
  });

  factory PromotionDealItemEntity.fromJson(Map<String, dynamic> json) {
    return PromotionDealItemEntity(
      productTitle: json['product_title']?.toString() ?? '',
      variantTitle: json['variant_title']?.toString() ?? '',
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
    );
  }

  @override
  List<Object?> get props => [productTitle, variantTitle, quantity];
}

class PromotionDealEntity extends Equatable {
  final int id;
  final String code;
  final String slug;
  final String title;
  final String description;
  final double price;
  final double oldPrice;
  final String badgeText;
  final String imageUrl;
  final int? perUserLimit;
  final List<PromotionDealItemEntity> items;

  const PromotionDealEntity({
    required this.id,
    required this.code,
    required this.slug,
    required this.title,
    required this.description,
    required this.price,
    required this.oldPrice,
    required this.badgeText,
    this.imageUrl = '',
    this.perUserLimit,
    this.items = const [],
  });

  factory PromotionDealEntity.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? [];
    return PromotionDealEntity(
      id: (json['id'] as num?)?.toInt() ?? 0,
      code: json['code']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      oldPrice: (json['old_price'] as num?)?.toDouble() ?? 0.0,
      badgeText: json['badge_text']?.toString() ?? '',
      imageUrl: json['image_url']?.toString() ?? json['image']?.toString() ?? '',
      perUserLimit: (json['per_user_limit'] as num?)?.toInt(),
      items: rawItems
          .whereType<Map<String, dynamic>>()
          .map((i) => PromotionDealItemEntity.fromJson(i))
          .toList(),
    );
  }

  ProductEntity toProductEntity() {
    return ProductEntity(
      id: 900000 + id,
      slug: slug.isNotEmpty ? slug : 'coupon-$id',
      title: title,
      description: description,
      thumbnail: imageUrl,
      photo: imageUrl,
      price: price,
      oldPrice: oldPrice > price ? oldPrice : null,
      variants: const [],
      values: const [],
      badges: [
        if (badgeText.isNotEmpty)
          ProductBadgeEntity(text: badgeText, type: 'promo'),
      ],
    );
  }

  @override
  List<Object?> get props => [
        id,
        code,
        slug,
        title,
        description,
        price,
        oldPrice,
        badgeText,
        imageUrl,
        perUserLimit,
        items,
      ];
}

