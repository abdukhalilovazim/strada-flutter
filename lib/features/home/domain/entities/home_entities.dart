import 'package:equatable/equatable.dart';

class CategoryEntity extends Equatable {
  final String slug;
  final String title;

  const CategoryEntity({required this.slug, required this.title});

  @override
  List<Object?> get props => [slug, title];
}

class SliderEntity extends Equatable {
  final String image;
  final String? caption;
  final String? button;
  final String? buttonUrl;

  const SliderEntity({required this.image, this.caption, this.button, this.buttonUrl});

  @override
  List<Object?> get props => [image, caption, button, buttonUrl];
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

class ProductEntity extends Equatable {
  final String slug;
  final String title;
  final String? description;
  final String thumbnail;
  final String photo;
  final double price;
  final CategoryEntity? category;
  final List<VariantEntity> variants;
  final List<KeyValueEntity> values;

  const ProductEntity({
    required this.slug,
    required this.title,
    this.description,
    required this.thumbnail,
    required this.photo,
    required this.price,
    this.category,
    required this.variants,
    required this.values,
  });

  @override
  List<Object?> get props => [slug, title, description, thumbnail, photo, price, category, variants, values];
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
