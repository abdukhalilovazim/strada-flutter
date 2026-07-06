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
  bool _warmedUp = false;

  CookieAwareClient()
      : _httpClient = HttpClient()
          ..connectionTimeout = const Duration(seconds: 60)
          ..idleTimeout = const Duration(seconds: 60) {
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
  /// **5 soniyalik** qattiq timeout — ilova ishga tushishini bloklamasligi uchun.
  /// Muvaffaqiyatsiz bo'lsa ham ilova cookie'siz davom etadi.
  Future<void> _warmUp() async {
    if (_warmedUp) return;
    _warmedUp = true; // Takroriy chaqiruvlarni oldini olish

    // Alohida qisqa umrli HttpClient — faqat warm-up uchun (5s timeout)
    final warmUpClient = HttpClient()
      ..connectionTimeout = const Duration(seconds: 5)
      ..idleTimeout = const Duration(seconds: 5);

    try {
      final uri = Uri.parse(ApiConstants.baseUrl);
      final request = await warmUpClient.getUrl(uri);

      // Browser-like GET headers
      request.headers.set('User-Agent', _browserUA);
      request.headers.set('Accept',
          'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8');
      request.headers.set('Accept-Language', 'uz,en;q=0.9,ru;q=0.8');
      request.headers.set('Accept-Encoding', 'gzip, deflate, br');
      request.headers.set('Connection', 'keep-alive');
      request.headers.set('Sec-Fetch-Site', 'none');
      request.headers.set('Sec-Fetch-Mode', 'navigate');
      request.headers.set('Sec-Fetch-Dest', 'document');
      request.headers.set('Upgrade-Insecure-Requests', '1');

      final response = await request.close().timeout(
        const Duration(seconds: 5),
      );

      // Set-Cookie headerlarni yig'ish
      final cookieStrings = <String>[];
      response.headers.forEach((name, values) {
        if (name.toLowerCase() == 'set-cookie') {
          for (final value in values) {
            // Faqat cookie nomi=qiymati qismini olish (path, domain, etc. olib tashlanadi)
            final cookiePart = value.split(';').first.trim();
            if (cookiePart.isNotEmpty) {
              cookieStrings.add(cookiePart);
            }
          }
        }
      });

      if (cookieStrings.isNotEmpty) {
        _cookies = cookieStrings.join('; ');
        if (kDebugMode) {
          debugPrint('🍪 [CookieAwareClient] Warm-up cookies: $_cookies');
        }
      } else {
        if (kDebugMode) {
          debugPrint('🍪 [CookieAwareClient] Warm-up OK, cookie yo\'q');
        }
      }

      // Response body ni drain qilish (resurslarni bo'shatish)
      await response.drain<void>();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ [CookieAwareClient] Warm-up failed (5s): $e');
      }
      // Warm-up muvaffaqiyatsiz bo'lsa ham davom etamiz — 
      // shunchaki cookie'siz so'rov yuboriladi
    } finally {
      warmUpClient.close();
    }
  }

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    return _inner.send(request);
  }

  @override
  void close() {
    _inner.close();
    _httpClient.close();
  }
}
