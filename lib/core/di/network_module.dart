import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:injectable/injectable.dart';
import 'package:pizza_strada/core/network/graphql_client.dart';
import 'package:pizza_strada/core/storage/secure_storage.dart';

@module
abstract class NetworkModule {
  @preResolve
  @lazySingleton
  Future<GraphQLClient> get client async {
    final token = await SecureStorage.getToken();
    return buildGraphQLClient(token: token);
  }
}
