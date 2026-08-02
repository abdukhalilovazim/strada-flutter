import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:pizza_strada/core/constants/api_constants.dart';

/// Imunify360 bot-protection bypass uchun cookie-aware HTTP client.
///
/// Real browser xatti-harakatini emulyatsiya qiladi:
/// 1. Birinchi so'rovdan oldin base URL ga GET qiladi (warm-up)
/// 2. Serverdan olingan Set-Cookie headerlarni saqlaydi
/// 3. Barcha keyingi so'rovlarga cookie qo'shadi
///
/// Bu Imunify360 ning "IP flagging" muammosini hal qiladi —
/// chunki real browser ham avval saytga kiradi, keyin API chaqiradi.
class CookieAwareClient extends http.BaseClient {
  final HttpClient _httpClient;
  late final IOClient _inner;
  String? _cookies;
  Future<void>? _warmUpFuture;

  CookieAwareClient()
      : _httpClient = HttpClient()
          ..connectionTimeout = const Duration(seconds: 60)
          ..idleTimeout = const Duration(seconds: 60)
          ..badCertificateCallback =
              ((X509Certificate cert, String host, int port) => true) {
    _inner = IOClient(_httpClient);
  }

  /// Browser User-Agent — iOS yoki Android platformaga qarab
  static String get _browserUA => Platform.isIOS
      ? 'Mozilla/5.0 (iPhone; CPU iPhone OS 17_5_1 like Mac OS X) '
          'AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.5 '
          'Mobile/15E148 Safari/604.1'
      : 'Mozilla/5.0 (Linux; Android 14; Pixel 8 Pro '
          'Build/UQ1A.240205.002) AppleWebKit/537.36 (KHTML, like Gecko) '
          'Chrome/125.0.6422.113 Mobile Safari/537.36';

  /// Base URL ga GET qilib Imunify360 cookie olish (warm-up).
  ///
  /// Real browser saytga kirganda ham avval HTML sahifani yuklab,
  /// Set-Cookie headerlarni oladi. Shundan keyin API so'rovlar
  /// shu cookie bilan yuboriladi va WAF blokmaydi.
  ///
  /// **30 soniyalik** timeout — ilova ishga tushishini bloklamasligi uchun.
  /// Muvaffaqiyatsiz bo'lsa ham ilova cookie'siz davom etadi.
  Future<void> _warmUp() {
    return _warmUpFuture ??= _doWarmUp();
  }

  Future<void> _doWarmUp() async {
    final warmUpClient = HttpClient()
      ..connectionTimeout = const Duration(seconds: 30)
      ..idleTimeout = const Duration(seconds: 30)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;

    final cookieMap = <String, String>{};

    Future<void> fetchCookies(String urlStr, {int maxRedirects = 5}) async {
      if (maxRedirects <= 0) return;
      try {
        final uri = Uri.parse(urlStr);
        final request = await warmUpClient.getUrl(uri);
        request.followRedirects = false; // Redirect cookie'larini yo'qotmaslik uchun!

        request.headers.set('User-Agent', _browserUA);
        request.headers.set(
          'Accept',
          'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
        );
        request.headers.set('Accept-Language', 'uz,en;q=0.9,ru;q=0.8');
        request.headers.set('Accept-Encoding', 'gzip, deflate, br');
        request.headers.set('Connection', 'keep-alive');
        request.headers.set('Sec-Fetch-Site', 'none');
        request.headers.set('Sec-Fetch-Mode', 'navigate');
        request.headers.set('Sec-Fetch-Dest', 'document');
        request.headers.set('Upgrade-Insecure-Requests', '1');

        if (cookieMap.isNotEmpty) {
          final cookieHeader =
              cookieMap.entries.map((e) => '${e.key}=${e.value}').join('; ');
          request.headers.set('Cookie', cookieHeader);
        }

        final response = await request.close().timeout(
          const Duration(seconds: 30),
        );

        response.headers.forEach((name, values) {
          if (name.toLowerCase() == 'set-cookie') {
            for (final value in values) {
              final cookiePart = value.split(';').first.trim();
              if (cookiePart.isNotEmpty) {
                final parts = cookiePart.split('=');
                if (parts.length >= 2) {
                  cookieMap[parts[0].trim()] =
                      parts.sublist(1).join('=').trim();
                }
              }
            }
          }
        });

        final location = response.headers.value('location');
        await response.drain<void>();

        if (response.statusCode >= 300 &&
            response.statusCode < 400 &&
            location != null) {
          final nextUri = uri.resolve(location);
          await fetchCookies(nextUri.toString(),
              maxRedirects: maxRedirects - 1);
        }
      } catch (_) {}
    }

    try {
      await fetchCookies(ApiConstants.baseUrl);
      await fetchCookies(ApiConstants.commonEndpoint);

      if (cookieMap.isNotEmpty) {
        _cookies =
            cookieMap.entries.map((e) => '${e.key}=${e.value}').join('; ');
        if (kDebugMode) {
          debugPrint('🍪 [CookieAwareClient] Warm-up cookies: $_cookies');
        }
      } else {
        if (kDebugMode) {
          debugPrint('🍪 [CookieAwareClient] Warm-up OK, cookie yo\'q');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ [CookieAwareClient] Warm-up failed: $e');
      }
    } finally {
      warmUpClient.close();
    }
  }

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    // Birinchi so'rovdan oldin warm-up
    await _warmUp();

    // Standard browser & CORS headerlarini o'rnatish
    request.headers['Origin'] ??= ApiConstants.baseUrl;
    request.headers['Referer'] ??= '${ApiConstants.baseUrl}/';
    request.headers['Accept'] ??= 'application/json, text/plain, */*';

    if (!request.headers.containsKey('user-agent') &&
        !request.headers.containsKey('User-Agent')) {
      request.headers['User-Agent'] = _browserUA;
    }

    // Olingan cookie'larni so'rovga qo'shish
    if (_cookies != null && _cookies!.isNotEmpty) {
      final existing = request.headers['Cookie'] ?? request.headers['cookie'];
      if (existing != null && existing.isNotEmpty) {
        request.headers['Cookie'] = '$existing; $_cookies';
      } else {
        request.headers['Cookie'] = _cookies!;
      }
    }

    // 60 soniyalik explicit timeout — gql_http_link stream default'ini override qilish
    return _inner.send(request).timeout(
      const Duration(seconds: 60),
      onTimeout: () => throw TimeoutException(
        'Server 60 soniya ichida javob bermadi',
        const Duration(seconds: 60),
      ),
    );
  }

  @override
  void close() {
    _inner.close();
    _httpClient.close();
  }
}
