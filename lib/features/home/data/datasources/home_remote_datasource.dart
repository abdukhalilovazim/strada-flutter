import 'package:injectable/injectable.dart';
import 'package:pizza_strada/core/network/api_client.dart';
import 'package:pizza_strada/features/home/data/models/home_models.dart';

abstract class HomeRemoteDataSource {
  Future<List<CategoryModel>> getCategories();
  Future<List<ProductModel>> getProducts({int? categoryId, String? categorySlug});
  Future<SettingsModel> getSettings();
  Future<List<SliderModel>> getSliders();
  Future<List<StoryModel>> getStories();
}

@LazySingleton(as: HomeRemoteDataSource)
class HomeRemoteDataSourceImpl implements HomeRemoteDataSource {
  final ApiClient _client;

  HomeRemoteDataSourceImpl(this._client);

  @override
  Future<List<CategoryModel>> getCategories() async {
    final response = await _client.get('categories');
    return (response as List).map((e) => CategoryModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<List<ProductModel>> getProducts({int? categoryId, String? categorySlug}) async {
    final Map<String, dynamic> params = {};
    if (categoryId != null && categoryId > 0) {
      params['category_id'] = categoryId;
    } else if (categorySlug != null) {
      params['category_slug'] = categorySlug;
    }

    final response = await _client.get(
      'products',
      queryParameters: params.isNotEmpty ? params : null,
    );
    return (response as List).map((e) => ProductModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<SettingsModel> getSettings() async {
    final response = await _client.get('settings');
    return SettingsModel.fromJson(response as Map<String, dynamic>);
  }

  @override
  Future<List<SliderModel>> getSliders() async {
    try {
      final response = await _client.get('sliders');
      final List items;
      if (response is List) {
        items = response;
      } else if (response is Map<String, dynamic> && response['sliders'] is List) {
        items = response['sliders'] as List;
      } else if (response is Map<String, dynamic> && response['data'] is List) {
        items = response['data'] as List;
      } else {
        items = const [];
      }
      return items
          .whereType<Map<String, dynamic>>()
          .map(SliderModel.fromJson)
          .where((s) => s.imageUrl.isNotEmpty)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<List<StoryModel>> getStories() async {
    try {
      final response = await _client.get('stories');
      final List items;
      if (response is List) {
        items = response;
      } else if (response is Map<String, dynamic> && response['data'] is List) {
        items = response['data'] as List;
      } else if (response is Map<String, dynamic> && response['stories'] is List) {
        items = response['stories'] as List;
      } else {
        items = const [];
      }

      final stories = items
          .whereType<Map<String, dynamic>>()
          .map(StoryModel.fromJson)
          .where((s) => s.previewImage.isNotEmpty)
          .toList();

      if (stories.isNotEmpty) return stories;
    } catch (_) {
      // Fallback below
    }

    // Defensive fallback: If /stories endpoint fails or is not yet deployed,
    // convert /sliders to stories so real images are displayed instantly.
    try {
      final sliders = await getSliders();
      if (sliders.isNotEmpty) {
        final List<String> defaultTitles = [
          'Yangi pitsalar 🍕',
          'Aksiya 2+1 🎁',
          'Kombolar 🔥',
          'Tezkor yetkazish ⚡',
        ];
        return sliders.asMap().entries.map((entry) {
          final index = entry.key;
          final slider = entry.value;
          final title = (slider.title != null && slider.title!.isNotEmpty)
              ? slider.title!
              : (index < defaultTitles.length ? defaultTitles[index] : 'Strada Pizza');

          return StoryModel(
            id: slider.id > 0 ? slider.id : (index + 1),
            title: title,
            previewImage: slider.imageUrl,
            slides: [
              StorySlideModel(
                id: slider.id > 0 ? slider.id : (index + 1),
                imageUrl: slider.imageUrl,
                title: title,
                description: 'Strada Pizza eng issiq va mazali pitsalari bilan sizni xursand qiladi!',
                buttonText: 'Buyurtma berish',
                buttonUrl: slider.link ?? '/home',
              ),
            ],
          );
        }).toList();
      }
    } catch (_) {}

    return const [];
  }
}

