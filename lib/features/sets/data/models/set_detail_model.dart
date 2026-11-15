import 'package:equatable/equatable.dart';

class SetGroupItemModel extends Equatable {
  final int id;
  final int productId;
  final int? productVariantId;
  final String productTitle;
  final String variantTitle;
  final String imageUrl;
  final bool isFixed;

  const SetGroupItemModel({
    required this.id,
    required this.productId,
    this.productVariantId,
    required this.productTitle,
    this.variantTitle = '',
    this.imageUrl = '',
    this.isFixed = false,
  });

  /// Check whether two items represent the exact same selectable item
  bool isSame(SetGroupItemModel other) {
    if (productVariantId != null &&
        other.productVariantId != null &&
        productVariantId != 0 &&
        other.productVariantId != 0) {
      return productVariantId == other.productVariantId;
    }
    if (productId != 0 && other.productId != 0) {
      return productId == other.productId;
    }
    return id == other.id;
  }

  factory SetGroupItemModel.fromJson(Map<String, dynamic> json) {
    return SetGroupItemModel(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      productId: int.tryParse(json['product_id']?.toString() ?? '0') ?? 0,
      productVariantId: int.tryParse(json['product_variant_id']?.toString() ?? ''),
      productTitle: json['product_title']?.toString() ?? '',
      variantTitle: json['variant_title']?.toString() ?? '',
      imageUrl: json['image_url']?.toString() ?? '',
      isFixed: json['is_fixed'] == true || json['is_fixed'] == 1 || json['is_fixed'] == '1',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'product_id': productId,
        'product_variant_id': productVariantId,
        'product_title': productTitle,
        'variant_title': variantTitle,
        'image_url': imageUrl,
        'is_fixed': isFixed,
      };

  @override
  List<Object?> get props => [
        id,
        productId,
        productVariantId,
        productTitle,
        variantTitle,
        imageUrl,
        isFixed,
      ];
}

class SetGroupModel extends Equatable {
  final int id;
  final String title;
  final String selectionType; // 'SINGLE_CHOICE', 'MULTIPLE_CHOICE', 'FIXED'
  final int minSelections;
  final int maxSelections;
  final List<SetGroupItemModel> items;

  const SetGroupModel({
    required this.id,
    required this.title,
    this.selectionType = 'SINGLE_CHOICE',
    this.minSelections = 1,
    this.maxSelections = 1,
    this.items = const [],
  });

  factory SetGroupModel.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? [];
    return SetGroupModel(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      title: json['title']?.toString() ?? '',
      selectionType: json['selection_type']?.toString() ?? 'SINGLE_CHOICE',
      minSelections: int.tryParse(json['min_selections']?.toString() ?? '1') ?? 1,
      maxSelections: int.tryParse(json['max_selections']?.toString() ?? '1') ?? 1,
      items: rawItems
          .whereType<Map<String, dynamic>>()
          .map((i) => SetGroupItemModel.fromJson(i))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'selection_type': selectionType,
        'min_selections': minSelections,
        'max_selections': maxSelections,
        'items': items.map((i) => i.toJson()).toList(),
      };

  @override
  List<Object?> get props => [
        id,
        title,
        selectionType,
        minSelections,
        maxSelections,
        items,
      ];
}

class SetDetailModel extends Equatable {
  final int id;
  final String slug;
  final String title;
  final String description;
  final double price;
  final String imageUrl;
  final List<SetGroupModel> groups;

  const SetDetailModel({
    required this.id,
    required this.slug,
    required this.title,
    this.description = '',
    required this.price,
    this.imageUrl = '',
    this.groups = const [],
  });

  /// Setning haqiqiy fotosurati bormi yoki yo'qligini tekshirish
  bool get hasRealImage {
    if (imageUrl.isEmpty) return false;
    final lower = imageUrl.toLowerCase();
    if (lower.contains('logo.png') ||
        lower.contains('placeholder') ||
        lower.contains('no-image') ||
        lower.contains('no_image') ||
        lower.contains('default.png') ||
        lower.contains('images/logo')) {
      return false;
    }
    return true;
  }

  factory SetDetailModel.fromJson(Map<String, dynamic> json) {
    final rawGroups = json['groups'] as List<dynamic>? ?? [];
    return SetDetailModel(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      slug: json['slug']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,
      imageUrl: json['image_url']?.toString() ?? '',
      groups: rawGroups
          .whereType<Map<String, dynamic>>()
          .map((g) => SetGroupModel.fromJson(g))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'slug': slug,
        'title': title,
        'description': description,
        'price': price,
        'image_url': imageUrl,
        'groups': groups.map((g) => g.toJson()).toList(),
      };

  @override
  List<Object?> get props => [id, slug, title, description, price, imageUrl, groups];
}

/// Savatga qo'shiladigan tanlov
class SetSelectionItem extends Equatable {
  final int setGroupId;
  final int productVariantId;
  final String productTitle;
  final String variantTitle;

  const SetSelectionItem({
    required this.setGroupId,
    required this.productVariantId,
    required this.productTitle,
    this.variantTitle = '',
  });

  factory SetSelectionItem.fromJson(Map<String, dynamic> json) => SetSelectionItem(
        setGroupId: int.tryParse(json['set_group_id']?.toString() ?? '0') ?? 0,
        productVariantId: int.tryParse(json['product_variant_id']?.toString() ?? '0') ?? 0,
        productTitle: json['product_title']?.toString() ?? '',
        variantTitle: json['variant_title']?.toString() ?? '',
      );

  Map<String, dynamic> toJson() => {
        'set_group_id': setGroupId,
        'product_variant_id': productVariantId,
        'product_title': productTitle,
        'variant_title': variantTitle,
      };

  @override
  List<Object?> get props => [setGroupId, productVariantId, productTitle, variantTitle];
}

