import 'package:equatable/equatable.dart';
import 'package:pizza_strada/features/home/domain/entities/home_entities.dart';

class PromotionDealItemEntity extends Equatable {
  final String productTitle;
  final String variantTitle;
  final int quantity;
  final String imageUrl;

  const PromotionDealItemEntity({
    required this.productTitle,
    this.variantTitle = '',
    this.quantity = 1,
    this.imageUrl = '',
  });

  factory PromotionDealItemEntity.fromJson(Map<String, dynamic> json) {
    final rawVariant = json['variant_title']?.toString() ?? '';
    final isSize = rawVariant.trim().toLowerCase() == 'size' ||
        rawVariant.trim().toLowerCase() == "o'lcham" ||
        rawVariant.trim().toLowerCase() == 'размер';
    return PromotionDealItemEntity(
      productTitle: json['product_title']?.toString() ?? '',
      variantTitle: isSize ? '' : rawVariant,
      quantity: int.tryParse(json['quantity']?.toString() ?? '1') ?? 1,
      imageUrl: json['image_url']?.toString() ?? '',
    );
  }

  @override
  List<Object?> get props => [productTitle, variantTitle, quantity, imageUrl];
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
    final rawOldPrice = json['old_price'] ?? json['oldPrice'] ?? json['calculated_old_price'];
    return PromotionDealEntity(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      code: json['code']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,
      oldPrice: double.tryParse(rawOldPrice?.toString() ?? '0') ?? 0.0,
      badgeText: json['badge_text']?.toString() ?? '',
      imageUrl: json['image_url']?.toString() ?? json['image']?.toString() ?? '',
      perUserLimit: int.tryParse(json['per_user_limit']?.toString() ?? ''),
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

