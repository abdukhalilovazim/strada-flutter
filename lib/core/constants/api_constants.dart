import 'package:flutter/foundation.dart';

class ApiConstants {
  static const _prodBase = 'https://pizzastrada.uz';
  static const _devBase  = 'https://food.khalilovdev.uz';

  static const _base = kReleaseMode ? _prodBase : _devBase;

  static const commonEndpoint = '$_base/graphql/common';
  static const orderEndpoint  = '$_base/graphql/order';

  // HMAC-SHA256 secret key
  static const hmacSecret = 'aB3Dk9Qx2Mf7LZ0pR8eHY4aS6VtWnCJmP5B1Kx9Z';
}
