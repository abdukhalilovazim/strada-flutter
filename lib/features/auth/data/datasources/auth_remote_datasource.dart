import 'package:injectable/injectable.dart';
import 'package:pizza_strada/core/network/api_client.dart';
import 'package:pizza_strada/features/auth/data/models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<bool> login({required String fullName, required String phone, bool forceSms = false});
  Future<Map<String, dynamic>> loginWithChannel({required String fullName, required String phone, bool forceSms = false});
  Future<UserModel> confirmOtp({required String phone, required String code});
  Future<UserModel> getMe();
  Future<UserModel> updateProfile({required String fullName, String? birthdate});
  Future<Map<String, dynamic>> telegramStart();
  Future<Map<String, dynamic>> telegramCheck({required String ticket});
}

@LazySingleton(as: AuthRemoteDataSource)
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final ApiClient _client;

  AuthRemoteDataSourceImpl(this._client);

  @override
  Future<bool> login({required String fullName, required String phone, bool forceSms = false}) async {
    final res = await loginWithChannel(fullName: fullName, phone: phone, forceSms: forceSms);
    return res['sent'] == true || res['success'] == true;
  }

  @override
  Future<Map<String, dynamic>> loginWithChannel({
    required String fullName,
    required String phone,
    bool forceSms = false,
  }) async {
    final response = await _client.post(
      'auth/login',
      body: {
        'full_name': fullName,
        'phone': phone,
        'force_sms': forceSms,
        'channel_supported': true,
      },
    );
    if (response is Map<String, dynamic>) {
      return response;
    }
    return {'sent': true, 'channel': 'sms'};
  }

  @override
  Future<UserModel> confirmOtp({required String phone, required String code}) async {
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

  @override
  Future<Map<String, dynamic>> telegramStart() async {
    final response = await _client.post('auth/telegram-start');
    if (response is Map<String, dynamic>) {
      return response;
    }
    return {};
  }

  @override
  Future<Map<String, dynamic>> telegramCheck({required String ticket}) async {
    final response = await _client.post(
      'auth/telegram-check',
      body: {'ticket': ticket},
    );
    if (response is Map<String, dynamic>) {
      return response;
    }
    return {};
  }
}

