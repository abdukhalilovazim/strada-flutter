import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConstants {
  static final _prodBase = dotenv.get('PROD_BASE_URL', fallback: 'https://pizzastrada.uz');
  static final _devBase  = dotenv.get('DEV_BASE_URL', fallback: 'https://food.khalilovdev.uz');
  static final _environment = dotenv.get('ENVIRONMENT', fallback: 'dev');

  // .env dagi ENVIRONMENT o'zgaruvchisiga qarab (prod yoki dev) bazaviy URL tanlanadi
  static String get _base => _environment == 'prod' ? _prodBase : _devBase;

  /// Bazaviy URL — Origin/Referer headerlar uchun
  static String get baseUrl => _base;

  /// REST API v1 bazaviy URL
  static String get apiBaseUrl => '$_base/api/v1';

  // HMAC-SHA256 secret key
  static String get hmacSecret => dotenv.get(
    'HMAC_SECRET',
    fallback: 'aB3Dk9Qx2Mf7LZ0pR8eHY4aS6VtWnCJmP5B1Kx9Z',
  );
}
