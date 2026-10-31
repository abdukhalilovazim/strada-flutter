import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPrefs {
  static late SharedPreferences _prefs;

  static const _themeKey = 'theme_mode';

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static Future<void> saveFcmToken(String token) =>
      _prefs.setString('fcm_token', token);

  static String? getFcmToken() => _prefs.getString('fcm_token');

  /// Saves the current [ThemeMode] to SharedPreferences.
  /// Stores `'dark'` or `'light'` (default: light).
  static Future<void> saveThemeMode(ThemeMode mode) =>
      _prefs.setString(_themeKey, mode == ThemeMode.dark ? 'dark' : 'light');

  /// Returns the previously saved [ThemeMode].
  /// Defaults to [ThemeMode.light] if nothing is saved.
  static ThemeMode getThemeMode() {
    final val = _prefs.getString(_themeKey);
    return val == 'dark' ? ThemeMode.dark : ThemeMode.light;
  }

  /// Checks if an order was already rated by the customer
  static bool isOrderRated(int orderId) =>
      _prefs.getBool('order_rated_$orderId') ?? false;

  /// Marks an order as rated by the customer
  static Future<void> setOrderRated(int orderId) =>
      _prefs.setBool('order_rated_$orderId', true);
}
