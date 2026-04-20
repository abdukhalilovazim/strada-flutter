import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

class YandexMapKeyManager {
  static const _channel = MethodChannel('uz.pizzastrada.app/yandex_map');
  static const _keyIndexPref = 'yandex_map_key_index';

  /// Initializes the map with the currently selected key.
  static Future<void> init() async {
    final keys = _getKeys();
    if (keys.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    int index = prefs.getInt(_keyIndexPref) ?? 0;

    // Safety check for index out of bounds
    if (index >= keys.length) {
      index = 0;
      await prefs.setInt(_keyIndexPref, 0);
    }

    final key = keys[index];
    try {
      await _channel.invokeMethod('initMap', {'apiKey': key});
    } on PlatformException catch (e) {
      print('Failed to initialize Yandex Map: ${e.message}');
    }
  }

  /// Switches to the next available key and saves the index.
  /// Note: Effect will take place after app restart.
  static Future<void> switchToNextKey() async {
    final keys = _getKeys();
    if (keys.length <= 1) return;

    final prefs = await SharedPreferences.getInstance();
    int currentIndex = prefs.getInt(_keyIndexPref) ?? 0;
    int nextIndex = (currentIndex + 1) % keys.length;

    await prefs.setInt(_keyIndexPref, nextIndex);
  }

  static List<String> _getKeys() {
    final keysStr = dotenv.get('YANDEX_MAP_KEYS', fallback: '');
    if (keysStr.isEmpty) return [];
    return keysStr.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
  }
  
  static Future<String> getCurrentKey() async {
    final keys = _getKeys();
    if (keys.isEmpty) return '';
    final prefs = await SharedPreferences.getInstance();
    final index = prefs.getInt(_keyIndexPref) ?? 0;
    return keys[index < keys.length ? index : 0];
  }
}
