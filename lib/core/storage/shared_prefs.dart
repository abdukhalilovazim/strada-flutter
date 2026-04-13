import 'package:shared_preferences/shared_preferences.dart';

class SharedPrefs {
  static late SharedPreferences _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static Future<void> saveFcmToken(String token) =>
      _prefs.setString('fcm_token', token);

  static String? getFcmToken() =>
      _prefs.getString('fcm_token');
}
