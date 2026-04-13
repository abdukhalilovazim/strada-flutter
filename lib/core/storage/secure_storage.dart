import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  static const _storage = FlutterSecureStorage();
  static const _tokenKey = 'access_token';
  static const _userNameKey = 'user_name';
  static const _userPhoneKey = 'user_phone';

  static Future<void> saveToken(String token) =>
      _storage.write(key: _tokenKey, value: token);

  static Future<String?> getToken() =>
      _storage.read(key: _tokenKey);

  static Future<void> deleteToken() =>
      _storage.delete(key: _tokenKey);

  static Future<void> saveUserInfo({required String name, required String phone}) async {
    await _storage.write(key: _userNameKey, value: name);
    await _storage.write(key: _userPhoneKey, value: phone);
  }

  static Future<String?> getUserName() => _storage.read(key: _userNameKey);
  static Future<String?> getUserPhone() => _storage.read(key: _userPhoneKey);

  static Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
