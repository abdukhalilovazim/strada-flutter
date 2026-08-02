import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:pizza_strada/core/constants/api_constants.dart';
import 'package:pizza_strada/core/constants/app_constants.dart';
import 'package:pizza_strada/core/network/cookie_aware_client.dart';
import 'package:pizza_strada/core/storage/secure_storage.dart';
import 'package:pizza_strada/core/utils/device_info_helper.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic errors;

  ApiException(this.message, {this.statusCode, this.errors});

  @override
  String toString() => message;
}

class ApiClient {
  final http.Client _client;

  ApiClient({http.Client? client}) : _client = client ?? CookieAwareClient();

  Future<Map<String, String>> _buildHeaders({bool isMutation = false, dynamic body}) async {
    final token = await SecureStorage.getToken();
    final context = AppConstants.navigatorKey.currentContext;
    final lang = (context != null && context.mounted)
        ? (EasyLocalization.of(context)?.locale.languageCode ?? 'uz')
        : 'uz';

    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
      'language': lang,
      'device-id': _sanitizeHeader(DeviceInfoHelper.deviceId),
      'device-name': _sanitizeHeader(DeviceInfoHelper.deviceName),
      'device': Platform.isIOS ? 'ios' : 'android',
      'app-version-code': _sanitizeHeader(DeviceInfoHelper.appVersionCode),
    };

    if (isMutation) {
      final randomStr = _randomStr(16);
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final bodyStr = body != null ? jsonEncode(body) : '';
      final payload = '$bodyStr$randomStr$timestamp';
      final sign = Hmac(sha256, utf8.encode(ApiConstants.hmacSecret))
          .convert(utf8.encode(payload))
          .toString();

      headers['Header-Random-Str'] = randomStr;
      headers['Header-Timestamp'] = timestamp;
      headers['Header-Sign'] = sign;
    }

    return headers;
  }

  Uri _buildUri(String path, [Map<String, dynamic>? queryParameters]) {
    final cleanPath = path.startsWith('/') ? path : '/$path';
    final urlStr = '${ApiConstants.apiBaseUrl}$cleanPath';
    final uri = Uri.parse(urlStr);
    if (queryParameters == null || queryParameters.isEmpty) {
      return uri;
    }
    final stringParams = <String, String>{};
    queryParameters.forEach((key, value) {
      if (value != null) {
        stringParams[key] = value.toString();
      }
    });
    return uri.replace(queryParameters: stringParams);
  }

  Future<dynamic> get(String path, {Map<String, dynamic>? queryParameters}) async {
    final uri = _buildUri(path, queryParameters);
    final headers = await _buildHeaders(isMutation: false);
    _logRequest('GET', uri, headers);

    final response = await _client.get(uri, headers: headers);
    return _processResponse('GET', uri.toString(), response);
  }

  Future<dynamic> post(String path, {dynamic body}) async {
    final uri = _buildUri(path);
    final headers = await _buildHeaders(isMutation: true, body: body);
    final jsonBody = body != null ? jsonEncode(body) : null;
    _logRequest('POST', uri, headers, body: jsonBody);

    final response = await _client.post(uri, headers: headers, body: jsonBody);
    return _processResponse('POST', uri.toString(), response);
  }

  Future<dynamic> put(String path, {dynamic body}) async {
    final uri = _buildUri(path);
    final headers = await _buildHeaders(isMutation: true, body: body);
    final jsonBody = body != null ? jsonEncode(body) : null;
    _logRequest('PUT', uri, headers, body: jsonBody);

    final response = await _client.put(uri, headers: headers, body: jsonBody);
    return _processResponse('PUT', uri.toString(), response);
  }

  Future<dynamic> delete(String path, {dynamic body}) async {
    final uri = _buildUri(path);
    final headers = await _buildHeaders(isMutation: true, body: body);
    final jsonBody = body != null ? jsonEncode(body) : null;
    _logRequest('DELETE', uri, headers, body: jsonBody);

    final response = await _client.delete(uri, headers: headers, body: jsonBody);
    return _processResponse('DELETE', uri.toString(), response);
  }

  dynamic _processResponse(String method, String url, http.Response response) {
    if (kDebugMode) {
      debugPrint('┌──────────────────────────────────────────────────────────────────');
      debugPrint('│ 📥 [REST RESPONSE] [$method $url] Status: ${response.statusCode}');
      final bodyStr = response.body.length > 1000 ? "${response.body.substring(0, 1000)}..." : response.body;
      debugPrint('│ Body: $bodyStr');
      debugPrint('└──────────────────────────────────────────────────────────────────');
    }

    dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } catch (_) {
      throw ApiException(
        'Serverdan noto\'g\'ri formatda javob keldi (HTTP ${response.statusCode})',
        statusCode: response.statusCode,
      );
    }

    if (decoded is Map<String, dynamic>) {
      final bool success = decoded['success'] == true;
      final String? message = decoded['message'] as String?;
      final errors = decoded['errors'];

      if (!success && response.statusCode >= 400) {
        final errMsg = message ?? _extractFirstErrorMessage(errors) ?? 'Server xatosi (${response.statusCode})';
        throw ApiException(errMsg, statusCode: response.statusCode, errors: errors);
      }

      if (decoded.containsKey('data')) {
        return decoded['data'];
      }
      return decoded;
    }

    return decoded;
  }

  String? _extractFirstErrorMessage(dynamic errors) {
    if (errors is Map<String, dynamic>) {
      for (final key in errors.keys) {
        final val = errors[key];
        if (val is List && val.isNotEmpty) {
          return val.first.toString();
        } else if (val is String) {
          return val;
        }
      }
    } else if (errors is String) {
      return errors;
    }
    return null;
  }

  void _logRequest(String method, Uri uri, Map<String, String> headers, {String? body}) {
    if (kDebugMode) {
      debugPrint('┌──────────────────────────────────────────────────────────────────');
      debugPrint('│ 🚀 [REST REQUEST] [$method] ${uri.toString()}');
      if (body != null) {
        debugPrint('│ Body: $body');
      }
      debugPrint('└──────────────────────────────────────────────────────────────────');
    }
  }

  String _randomStr(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rng = Random.secure();
    return List.generate(length, (_) => chars[rng.nextInt(chars.length)]).join();
  }

  String _sanitizeHeader(String value) {
    return value.replaceAll(RegExp(r'[^\x20-\x7E]'), '').trim();
  }
}
