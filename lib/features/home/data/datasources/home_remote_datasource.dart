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
      } else if (response is Map && response['data'] is List) {
        items = response['data'] as List;
      } else if (response is Map && response['stories'] is List) {
        items = response['stories'] as List;
      } else {
        items = const [];
      }

      final stories = <StoryModel>[];
      for (final item in items) {
        if (item is Map) {
          try {
            final model = StoryModel.fromJson(Map<String, dynamic>.from(item));
            if (model.previewImage.isNotEmpty || model.slides.isNotEmpty) {
              stories.add(model);
            }
          } catch (e) {
            // Log but don't break the entire list
          }
        }
      }

      return stories;
    } catch (_) {
      return const [];
    }
  }
}

