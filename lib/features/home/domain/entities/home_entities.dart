import 'package:equatable/equatable.dart';

class CategoryEntity extends Equatable {
  final int id;
  final String slug;
  final String title;

  const CategoryEntity({
    this.id = 0,
    required this.slug,
    required this.title,
  });

  @override
  List<Object?> get props => [id, slug, title];
}

class VariantEntity extends Equatable {
  final int id;
  final String title;
  final double price;

  const VariantEntity({required this.id, required this.title, required this.price});

  @override
  List<Object?> get props => [id, title, price];
}

class KeyValueEntity extends Equatable {
  final String key;
  final String value;

  const KeyValueEntity({required this.key, required this.value});

  @override
  List<Object?> get props => [key, value];
}

class ProductBadgeEntity extends Equatable {
  final String text;
  final String type; // 'discount', 'tag', 'hit', 'promo'
  final String? bgColor;
  final String? textColor;

  const ProductBadgeEntity({
    required this.text,
    this.type = 'discount',
    this.bgColor,
    this.textColor,
  });

  @override
  List<Object?> get props => [text, type, bgColor, textColor];
}

class ProductEntity extends Equatable {
  final int id;
  final String slug;
  final String title;
  final String? description;
  final String thumbnail;
  final String photo;
  final double price;
  final double? oldPrice;
  final CategoryEntity? category;
  final List<VariantEntity> variants;
  final List<KeyValueEntity> values;
  final List<ProductBadgeEntity> badges;

  const ProductEntity({
    this.id = 0,
    required this.slug,
    required this.title,
    this.description,
    required this.thumbnail,
    required this.photo,
    required this.price,
    this.oldPrice,
    this.category,
    required this.variants,
    required this.values,
    this.badges = const [],
  });

  /// Real discount saved amount (e.g. 73 000 - 61 000 = 12 000)
  double? get discountAmount {
    if (oldPrice != null && oldPrice! > price) {
      return oldPrice! - price;
    }
    return null;
  }

  /// Check whether the product has a genuine photography rather than a logo/default fallback.
  bool get hasValidImage {
    final img = thumbnail.isNotEmpty ? thumbnail : photo;
    if (img.isEmpty) return false;
    final lower = img.toLowerCase();
    if (lower.contains('logo.png') ||
        lower.contains('default.png') ||
        lower.contains('no-image') ||
        lower.contains('no_image') ||
        lower.contains('placeholder') ||
        lower.contains('images/logo')) {
      return false;
    }
    return true;
  }

  /// Clean valid image URL or empty string.
  String get validImageUrl => hasValidImage ? (thumbnail.isNotEmpty ? thumbnail : photo) : '';

  @override
  List<Object?> get props => [id, slug, title, description, thumbnail, photo, price, oldPrice, category, variants, values, badges];
}

/// Banner slider entity (Swiper Slider uchun)
class SliderEntity extends Equatable {
  final int id;
  final String imageUrl;
  final String? link;
  final String? title;

  const SliderEntity({
    required this.id,
    required this.imageUrl,
    this.link,
    this.title,
  });

  @override
  List<Object?> get props => [id, imageUrl, link, title];
}

class SettingsEntity extends Equatable {
  final int discount;
  final bool canOrder;
  final String supportPhone;
  final List<PaymentMethodEntity> paymentMethods;

  const SettingsEntity({
    required this.discount,
    required this.canOrder,
    required this.supportPhone,
    required this.paymentMethods,
  });

  @override
  List<Object?> get props => [discount, canOrder, supportPhone, paymentMethods];
}

class PaymentMethodEntity extends Equatable {
  final String key;
  final String value;

  const PaymentMethodEntity({required this.key, required this.value});

  @override
  List<Object?> get props => [key, value];
}
