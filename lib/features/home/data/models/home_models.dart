import 'package:pizza_strada/core/constants/api_constants.dart';
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
    super.oldPrice,
    super.badges = const [],
    super.category,
    required List<VariantModel> super.variants,
    required List<KeyValueModel> super.values,
  });

  static String _cleanImageUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    final lower = url.toLowerCase();
    if (lower.contains('logo.png') ||
        lower.contains('default.png') ||
        lower.contains('no-image') ||
        lower.contains('no_image') ||
        lower.contains('placeholder') ||
        lower.contains('images/logo')) {
      return '';
    }
    return url;
  }

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    final parsedId = int.tryParse(json['id']?.toString() ?? '0') ?? 0;
    final rawThumb = json['thumbnail'] as String? ?? json['photo'] as String? ?? '';
    final rawPhoto = json['photo'] as String? ?? json['thumbnail'] as String? ?? '';
    final cleanThumb = _cleanImageUrl(rawThumb);
    final cleanPhoto = _cleanImageUrl(rawPhoto);

    return ProductModel(
      id: parsedId,
      slug: json['slug'] as String? ?? (parsedId != 0 ? parsedId.toString() : ''),
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      thumbnail: cleanThumb,
      photo: cleanPhoto.isNotEmpty ? cleanPhoto : cleanThumb,
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0,
      oldPrice: double.tryParse(json['old_price']?.toString() ?? ''),
      badges: (json['badges'] as List? ?? []).map((b) {
        if (b is Map<String, dynamic>) {
          return ProductBadgeEntity(
            text: b['text']?.toString() ?? '',
            type: b['type']?.toString() ?? 'discount',
            bgColor: b['bg_color']?.toString(),
            textColor: b['text_color']?.toString(),
          );
        }
        return ProductBadgeEntity(text: b.toString());
      }).toList(),
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

class SliderModel extends SliderEntity {
  const SliderModel({
    required super.id,
    required super.imageUrl,
    super.link,
    super.title,
  });

  factory SliderModel.fromJson(Map<String, dynamic> json) {
    final rawImage = json['image_url'] ??
        json['image'] ??
        json['photo'] ??
        json['file'] ??
        json['path'] ??
        '';
    final imageStr = rawImage.toString().trim();

    final String fullImageUrl;
    if (imageStr.isEmpty) {
      fullImageUrl = '';
    } else if (imageStr.startsWith('http://') || imageStr.startsWith('https://')) {
      fullImageUrl = imageStr;
    } else {
      final cleanPath = imageStr.startsWith('/') ? imageStr.substring(1) : imageStr;
      fullImageUrl = '${ApiConstants.baseUrl}/$cleanPath';
    }

    return SliderModel(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      imageUrl: fullImageUrl,
      link: json['link'] as String? ?? json['url'] as String?,
      title: json['title'] as String? ?? json['name'] as String?,
    );
  }
}

class StorySlideModel extends StorySlideEntity {
  const StorySlideModel({
    required super.id,
    required super.imageUrl,
    super.title,
    super.description,
    super.buttonText,
    super.buttonUrl,
    super.durationSeconds = 5,
  });

  factory StorySlideModel.fromJson(Map<String, dynamic> json) {
    final rawImage = json['image_url'] ??
        json['image'] ??
        json['photo'] ??
        json['file'] ??
        json['path'] ??
        '';
    final imageStr = rawImage.toString().trim();

    final String fullImageUrl;
    if (imageStr.isEmpty) {
      fullImageUrl = '';
    } else if (imageStr.startsWith('http://') || imageStr.startsWith('https://')) {
      fullImageUrl = imageStr;
    } else {
      final cleanPath = imageStr.startsWith('/') ? imageStr.substring(1) : imageStr;
      fullImageUrl = '${ApiConstants.baseUrl}/$cleanPath';
    }

    return StorySlideModel(
      id: int.tryParse(json['id']?.toString() ?? '1') ?? 1,
      imageUrl: fullImageUrl,
      title: json['title'] as String?,
      description: json['description'] as String?,
      buttonText: json['button_text'] as String? ?? json['button'] as String?,
      buttonUrl: json['button_url'] as String?,
      durationSeconds: int.tryParse(json['duration_seconds']?.toString() ?? '5') ?? 5,
    );
  }
}

class StoryModel extends StoryEntity {
  const StoryModel({
    required super.id,
    required super.title,
    required super.previewImage,
    required super.slides,
    super.isViewed = false,
  });

  factory StoryModel.fromJson(Map<String, dynamic> json) {
    final rawThumb = json['thumbnail'] ??
        json['preview_image'] ??
        json['image_url'] ??
        json['image'] ??
        '';
    final thumbStr = rawThumb.toString().trim();

    final String fullThumbUrl;
    if (thumbStr.isEmpty) {
      fullThumbUrl = '';
    } else if (thumbStr.startsWith('http://') || thumbStr.startsWith('https://')) {
      fullThumbUrl = thumbStr;
    } else {
      final cleanPath = thumbStr.startsWith('/') ? thumbStr.substring(1) : thumbStr;
      fullThumbUrl = '${ApiConstants.baseUrl}/$cleanPath';
    }

    final rawSlides = json['slides'] as List<dynamic>? ?? [];
    final slides = rawSlides
        .map((s) => StorySlideModel.fromJson(s as Map<String, dynamic>))
        .toList();

    // If no slides array provided, create a single slide from the root item
    if (slides.isEmpty && fullThumbUrl.isNotEmpty) {
      slides.add(
        StorySlideModel(
          id: int.tryParse(json['id']?.toString() ?? '1') ?? 1,
          imageUrl: fullThumbUrl,
          title: json['title'] as String?,
          description: json['description'] as String?,
          buttonText: json['button_text'] as String? ?? json['button'] as String?,
          buttonUrl: json['button_url'] as String?,
        ),
      );
    }

    return StoryModel(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      title: json['title'] as String? ?? json['name'] as String? ?? 'Strada',
      previewImage: fullThumbUrl,
      slides: slides,
      isViewed: json['is_viewed'] == true,
    );
  }
}
