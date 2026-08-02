import 'package:injectable/injectable.dart';
import 'package:pizza_strada/core/network/api_client.dart';
import 'package:pizza_strada/features/home/data/models/home_models.dart';

abstract class HomeRemoteDataSource {
  Future<List<CategoryModel>> getCategories();
  Future<List<ProductModel>> getProducts({String? categorySlug});
  Future<SettingsModel> getSettings();
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
  Future<List<ProductModel>> getProducts({String? categorySlug}) async {
    final response = await _client.get(
      'products',
      queryParameters: categorySlug != null ? {'category_slug': categorySlug} : null,
    );
    return (response as List).map((e) => ProductModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<SettingsModel> getSettings() async {
    final response = await _client.get('settings');
    return SettingsModel.fromJson(response as Map<String, dynamic>);
  }
}

