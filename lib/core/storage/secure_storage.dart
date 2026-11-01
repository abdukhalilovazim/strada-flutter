import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/saved_address_model.dart';

class SecureStorage {
  static const _storage = FlutterSecureStorage();
  static const _tokenKey = 'access_token';
  static const _userNameKey = 'user_name';
  static const _userPhoneKey = 'user_phone';
  static const _savedAddressesKey = 'saved_addresses_v1';

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

  static Future<List<SavedAddressModel>> getSavedAddresses() async {
    try {
      final jsonStr = await _storage.read(key: _savedAddressesKey);
      if (jsonStr == null || jsonStr.isEmpty) return [];
      final list = jsonDecode(jsonStr) as List;
      return list
          .map((item) => SavedAddressModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveAddress(SavedAddressModel address) async {
    try {
      final current = await getSavedAddresses();
      current.removeWhere((a) =>
          a.address == address.address ||
          (a.lat == address.lat && a.lng == address.lng));
      current.insert(0, address);
      final trimmed = current.take(10).toList();
      await _storage.write(
        key: _savedAddressesKey,
        value: jsonEncode(trimmed.map((e) => e.toJson()).toList()),
      );
    } catch (_) {}
  }

  static Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
