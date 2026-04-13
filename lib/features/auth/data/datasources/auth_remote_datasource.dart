import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:injectable/injectable.dart';
import 'package:pizza_strada/features/auth/data/models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<bool> login({required String fullName, required String phone});
  Future<UserModel> confirmOtp({required String phone, required int code});
}

@LazySingleton(as: AuthRemoteDataSource)
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final GraphQLClient _client;

  AuthRemoteDataSourceImpl(this._client);

  @override
  Future<bool> login({required String fullName, required String phone}) async {
    const String mutation = r'''
      mutation login($full_name: String!, $phone: String!) {
        login(full_name: $full_name, phone: $phone)
      }
    ''';

    final options = MutationOptions(
      document: gql(mutation),
      variables: {
        'full_name': fullName,
        'phone': phone,
      },
    );

    final result = await _client.mutate(options);

    if (result.hasException) {
      throw result.exception!;
    }

    return result.data?['login'] ?? false;
  }

  @override
  Future<UserModel> confirmOtp({required String phone, required int code}) async {
    const String mutation = r'''
      mutation confirmOtp($phone: String!, $code: Int!) {
        confirmOtp(phone: $phone, code: $code) {
          id
          full_name
          phone
          token
        }
      }
    ''';

    final options = MutationOptions(
      document: gql(mutation),
      variables: {
        'phone': phone,
        'code': code,
      },
      operationName: 'confirmOtp', // Used by SplitLink
    );

    final result = await _client.mutate(options);

    if (result.hasException) {
      throw result.exception!;
    }

    return UserModel.fromJson(result.data?['confirmOtp']);
  }
}
