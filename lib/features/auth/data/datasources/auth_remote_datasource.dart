import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:injectable/injectable.dart';
import 'package:pizza_strada/features/auth/data/models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<bool> login({required String fullName, required String phone});
  Future<UserModel> confirmOtp({required String phone, required int code});
  Future<UserModel> getMe();
  Future<UserModel> updateProfile({required String fullName, String? birthdate});
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

    return UserModel.fromJson(result.data?['confirmOtp'] as Map<String, dynamic>);
  }

  @override
  Future<UserModel> getMe() async {
    const String query = r'''
      query Me {
        me {
          id
          full_name
          phone
          token
          birthdate
        }
      }
    ''';

    final options = QueryOptions(
      document: gql(query),
      fetchPolicy: FetchPolicy.networkOnly,
      operationName: 'Me',
    );

    final result = await _client.query(options);

    if (result.hasException) {
      throw result.exception!;
    }

    return UserModel.fromJson(result.data?['me'] as Map<String, dynamic>);
  }

  @override
  Future<UserModel> updateProfile({required String fullName, String? birthdate}) async {
    const String mutation = r'''
      mutation UpdateProfile($full_name: String!, $birthdate: String) {
        updateProfile(full_name: $full_name, birthdate: $birthdate) {
          id
          full_name
          phone
          token
          birthdate
        }
      }
    ''';

    final options = MutationOptions(
      document: gql(mutation),
      variables: {
        'full_name': fullName,
        if (birthdate != null) 'birthdate': birthdate,
      },
      operationName: 'UpdateProfile',
    );

    final result = await _client.mutate(options);

    if (result.hasException) {
      throw result.exception!;
    }

    return UserModel.fromJson(result.data?['updateProfile'] as Map<String, dynamic>);
  }
}
