import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:injectable/injectable.dart';
import 'package:pizza_strada/core/network/graphql_client.dart';

@module
abstract class NetworkModule {
  @preResolve
  @lazySingleton
  Future<GraphQLClient> get client async {
    return buildGraphQLClient();
  }
}
