import 'package:pizza_strada/features/home/domain/entities/home_entities.dart';

class CategoryModel extends CategoryEntity {
  const CategoryModel({required super.slug, required super.title});

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      slug: json['slug'] as String? ?? '',
      title: json['title'] as String? ?? '',
    );
  }
}

class SliderModel extends SliderEntity {
  const SliderModel({required super.image, super.caption, super.button, super.buttonUrl});

  factory SliderModel.fromJson(Map<String, dynamic> json) {
    return SliderModel(
      image: json['image'] as String? ?? '',
      caption: json['caption'] as String?,
      button: json['button'] as String?,
      buttonUrl: json['button_url'] as String?,
    );
  }
}

class VariantModel extends VariantEntity {
  const VariantModel({required super.id, required super.title, required super.price});

  factory VariantModel.fromJson(Map<String, dynamic> json) {
    return VariantModel(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      title: json['title'] as String? ?? '',
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0,
    );
  }
}

class KeyValueModel extends KeyValueEntity {
  const KeyValueModel({required super.key, required super.value});

  factory KeyValueModel.fromJson(Map<String, dynamic> json) {
    return KeyValueModel(
      key: json['key'] as String? ?? '',
      value: json['value'] as String? ?? '',
    );
  }
}

class ProductModel extends ProductEntity {
  const ProductModel({
    required super.slug,
    required super.title,
    super.description,
    required super.thumbnail,
    required super.photo,
    required super.price,
    super.category,
    required List<VariantModel> super.variants,
    required List<KeyValueModel> super.values,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      slug: json['slug'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      thumbnail: json['thumbnail'] as String? ?? '',
      photo: json['photo'] as String? ?? '',
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0,
      category: json['category'] != null ? CategoryModel.fromJson(json['category'] as Map<String, dynamic>) : null,
      variants: (json['variants'] as List? ?? []).map((e) => VariantModel.fromJson(e as Map<String, dynamic>)).toList(),
      values: (json['values'] as List? ?? []).map((e) => KeyValueModel.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}

class SettingsModel extends SettingsEntity {
  const SettingsModel({
    required super.discount,
    required super.canOrder,
    required super.supportPhone,
    required List<PaymentMethodModel> super.paymentMethods,
  });

  factory SettingsModel.fromJson(Map<String, dynamic> json) {
    return SettingsModel(
      discount: json['discount'] as int? ?? 0,
      canOrder: json['can_order'] as bool? ?? true,
      supportPhone: json['support_phone'] as String? ?? '',
      paymentMethods: (json['payment_methods'] as List? ?? [])
          .map((e) => PaymentMethodModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class PaymentMethodModel extends PaymentMethodEntity {
  const PaymentMethodModel({required super.key, required super.value});

  factory PaymentMethodModel.fromJson(Map<String, dynamic> json) {
    return PaymentMethodModel(
      key: json['key'] as String? ?? '',
      value: json['value'] as String? ?? '',
    );
  }
}
