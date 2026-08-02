import 'package:injectable/injectable.dart';
import 'package:pizza_strada/core/network/api_client.dart';
import 'package:pizza_strada/features/auth/data/models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<bool> login({required String fullName, required String phone});
  Future<UserModel> confirmOtp({required String phone, required int code});
  Future<UserModel> getMe();
  Future<UserModel> updateProfile({required String fullName, String? birthdate});
}

@LazySingleton(as: AuthRemoteDataSource)
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final ApiClient _client;

  AuthRemoteDataSourceImpl(this._client);

  @override
  Future<bool> login({required String fullName, required String phone}) async {
    final response = await _client.post(
      'auth/login',
      body: {
        'full_name': fullName,
        'phone': phone,
      },
    );
    return response == true || response?['success'] == true || response != null;
  }

  @override
  Future<UserModel> confirmOtp({required String phone, required int code}) async {
    final response = await _client.post(
      'auth/confirm-otp',
      body: {
        'phone': phone,
        'code': code,
      },
    );
    return UserModel.fromJson(response as Map<String, dynamic>);
  }

  @override
  Future<UserModel> getMe() async {
    final response = await _client.get('me');
    return UserModel.fromJson(response as Map<String, dynamic>);
  }

  @override
  Future<UserModel> updateProfile({required String fullName, String? birthdate}) async {
    final response = await _client.put(
      'me',
      body: {
        'full_name': fullName,
        if (birthdate != null) 'birth_date': birthdate,
      },
    );
    return UserModel.fromJson(response as Map<String, dynamic>);
  }
}

