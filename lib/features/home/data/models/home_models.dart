import 'package:pizza_strada/features/home/domain/entities/home_entities.dart';

class CategoryModel extends CategoryEntity {
  const CategoryModel({
    super.id = 0,
    required super.slug,
    required super.title,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      slug: json['slug'] as String? ?? json['id']?.toString() ?? '',
      title: json['title'] as String? ?? '',
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
    super.id = 0,
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
    final parsedId = int.tryParse(json['id']?.toString() ?? '0') ?? 0;
    return ProductModel(
      id: parsedId,
      slug: json['slug'] as String? ?? (parsedId != 0 ? parsedId.toString() : ''),
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
    final rawCanOrder = json['can_order'];
    return SettingsModel(
      discount: int.tryParse(json['discount']?.toString() ?? '0') ?? 0,
      canOrder: rawCanOrder == true || rawCanOrder == 1 || rawCanOrder == '1',
      supportPhone: json['support_phone']?.toString() ?? '',
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
      key: json['key']?.toString() ?? '',
      value: json['value']?.toString() ?? '',
    );
  }
}
