import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConstants {
  static final _prodBase = dotenv.get('PROD_BASE_URL', fallback: 'https://pizzastrada.uz');
  static final _devBase  = dotenv.get('DEV_BASE_URL', fallback: 'https://food.khalilovdev.uz');

  static String get _base => kReleaseMode ? _prodBase : _devBase;

  // AGENTS.md ga muvofiq schema path segment orqali beriladi
  static String get commonEndpoint => '$_base/graphql/common';
  static String get orderEndpoint  => '$_base/graphql/order';

  // HMAC-SHA256 secret key
  static String get hmacSecret => dotenv.get(
    'HMAC_SECRET',
    fallback: 'aB3Dk9Qx2Mf7LZ0pR8eHY4aS6VtWnCJmP5B1Kx9Z',
  );
}
