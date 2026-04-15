import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:injectable/injectable.dart';
import 'package:pizza_strada/features/home/data/models/home_models.dart';

abstract class HomeRemoteDataSource {
  Future<List<CategoryModel>> getCategories();
  Future<List<SliderModel>> getSliders();
  Future<List<ProductModel>> getProducts({String? categorySlug});
  Future<SettingsModel> getSettings();
}

@LazySingleton(as: HomeRemoteDataSource)
class HomeRemoteDataSourceImpl implements HomeRemoteDataSource {
  final GraphQLClient _client;

  HomeRemoteDataSourceImpl(this._client);

  @override
  Future<List<CategoryModel>> getCategories() async {
    const String query = r'''
      query categories {
        categories {
          slug
          title
        }
      }
    ''';
    final result = await _client.query(QueryOptions(
      document: gql(query),
      fetchPolicy: FetchPolicy.networkOnly,
    ));
    if (result.hasException) throw result.exception!;
    return (result.data?['categories'] as List).map((e) => CategoryModel.fromJson(e)).toList();
  }

  @override
  Future<List<SliderModel>> getSliders() async {
    const String query = r'''
      query sliders {
        sliders {
          image
          caption
          button
          button_url
        }
      }
    ''';
    final result = await _client.query(QueryOptions(
      document: gql(query),
      fetchPolicy: FetchPolicy.networkOnly,
    ));
    if (result.hasException) throw result.exception!;
    return (result.data?['sliders'] as List).map((e) => SliderModel.fromJson(e)).toList();
  }

  @override
  Future<List<ProductModel>> getProducts({String? categorySlug}) async {
    const String query = r'''
      query products($category_slug: String) {
        products(category_slug: $category_slug) {
          slug
          title
          description
          thumbnail
          photo
          price
          category {
            slug
            title
          }
          variants {
            id
            title
            price
          }
          values {
            key
            value
          }
        }
      }
    ''';
    final result = await _client.query(QueryOptions(
      document: gql(query),
      variables: {'category_slug': categorySlug},
      fetchPolicy: FetchPolicy.networkOnly,
    ));
    if (result.hasException) throw result.exception!;
    return (result.data?['products'] as List).map((e) => ProductModel.fromJson(e)).toList();
  }

  @override
  Future<SettingsModel> getSettings() async {
    const String query = r'''
      query settings {
        settings {
          discount
          can_order
          support_phone
          payment_methods {
            key
            value
          }
        }
      }
    ''';
    final result = await _client.query(QueryOptions(
      document: gql(query),
      fetchPolicy: FetchPolicy.networkOnly,
    ));
    if (result.hasException) throw result.exception!;
    return SettingsModel.fromJson(result.data?['settings'] as Map<String, dynamic>);
  }
}
