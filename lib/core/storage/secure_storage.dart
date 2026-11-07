import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/saved_address_model.dart';
import '../network/api_client.dart';

class SecureStorage {
  static const _storage = FlutterSecureStorage();
  static const _tokenKey = 'access_token';
  static const _userNameKey = 'user_name';
  static const _userPhoneKey = 'user_phone';
  static const _savedAddressesKey = 'saved_addresses_v1';
  static const _branchesKey = 'cached_branches_v1';
  static const _branchesTimestampKey = 'cached_branches_ts_v1';

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

  static Future<void> deleteUserInfo() async {
    await _storage.delete(key: _userNameKey);
    await _storage.delete(key: _userPhoneKey);
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
      final trimmed = current.take(15).toList();
      await _storage.write(
        key: _savedAddressesKey,
        value: jsonEncode(trimmed.map((e) => e.toJson()).toList()),
      );
    } catch (_) {}
  }

  static Future<void> saveAllAddresses(List<SavedAddressModel> list) async {
    try {
      final trimmed = list.take(15).toList();
      await _storage.write(
        key: _savedAddressesKey,
        value: jsonEncode(trimmed.map((e) => e.toJson()).toList()),
      );
    } catch (_) {}
  }

  static Future<void> deleteAddress(String id) async {
    try {
      final current = await getSavedAddresses();
      current.removeWhere((a) => a.id == id);
      await saveAllAddresses(current);
    } catch (_) {}
  }

  /// 🏢 Filiallarni mobil qurilmada bir necha soatga keshlab saqlash
  static Future<List<Map<String, dynamic>>?> getCachedBranches({
    Duration ttl = const Duration(hours: 12),
  }) async {
    try {
      final tsStr = await _storage.read(key: _branchesTimestampKey);
      if (tsStr == null) return null;
      final savedTime = DateTime.tryParse(tsStr);
      if (savedTime == null || DateTime.now().difference(savedTime) > ttl) {
        return null; // Muddati tugagan
      }
      final jsonStr = await _storage.read(key: _branchesKey);
      if (jsonStr == null || jsonStr.isEmpty) return null;
      final list = jsonDecode(jsonStr) as List;
      return list.map((e) => e as Map<String, dynamic>).toList();
    } catch (_) {
      return null;
    }
  }

  static Future<void> cacheBranches(List<dynamic> branches) async {
    try {
      await _storage.write(
        key: _branchesKey,
        value: jsonEncode(branches),
      );
      await _storage.write(
        key: _branchesTimestampKey,
        value: DateTime.now().toIso8601String(),
      );
    } catch (_) {}
  }

  /// Filiallarni keshdan olish yoki kerak bo'lsa serverdan yuklash
  static Future<List<Map<String, dynamic>>> getOrFetchBranches() async {
    final cached = await getCachedBranches();
    if (cached != null && cached.isNotEmpty) {
      return cached;
    }
    try {
      final response = await ApiClient().get('branches');
      List? rawList;
      if (response is List) {
        rawList = response;
      } else if (response is Map && response['data'] is List) {
        rawList = response['data'] as List;
      }
      if (rawList != null && rawList.isNotEmpty) {
        final list = rawList.map((e) => e as Map<String, dynamic>).toList();
        await cacheBranches(list);
        return list;
      }
    } catch (_) {}

    // Tarmoq xatosi bo'lsa, eskirgan bo'lsa ham keshdagini qaytarish
    final stale = await getCachedBranches(ttl: const Duration(days: 30));
    return stale ?? [];
  }

  static Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
