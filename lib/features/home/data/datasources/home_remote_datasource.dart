import 'package:injectable/injectable.dart';
import 'package:pizza_strada/core/network/api_client.dart';
import 'package:pizza_strada/core/sdui/models/sdui_page_model.dart';
import 'package:pizza_strada/features/home/data/models/home_models.dart';

abstract class HomeRemoteDataSource {
  Future<List<CategoryModel>> getCategories();
  Future<List<ProductModel>> getProducts({int? categoryId, String? categorySlug});
  Future<SettingsModel> getSettings();
  Future<List<SliderModel>> getSliders();
  Future<SDUIPageModel> getSDUIPage({String slug = 'home', String? categorySlug, int? branchId});
  Future<Map<String, dynamic>> getSDUIManifest();
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
  Future<SDUIPageModel> getSDUIPage({String slug = 'home', String? categorySlug, int? branchId}) async {
    final Map<String, dynamic> params = {};
    if (categorySlug != null && categorySlug.isNotEmpty) {
      params['category'] = categorySlug;
    }
    if (branchId != null) {
      params['branch_id'] = branchId;
    }

    final response = await _client.get(
      'sdui/pages/$slug',
      queryParameters: params.isNotEmpty ? params : null,
    );
    return SDUIPageModel.fromJson(response as Map<String, dynamic>);
  }

  @override
  Future<Map<String, dynamic>> getSDUIManifest() async {
    try {
      final response = await _client.get('sdui/manifest');
      if (response is Map<String, dynamic>) {
        if (response['data'] is Map<String, dynamic>) {
          return response['data'] as Map<String, dynamic>;
        }
        return response;
      }
      return const {};
    } catch (_) {
      return const {};
    }
  }
}

