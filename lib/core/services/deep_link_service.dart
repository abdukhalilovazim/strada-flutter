import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:pizza_strada/core/router/app_router.dart';
import 'package:pizza_strada/core/services/analytics_service.dart';

/// Deep Link Service handling both cold-start links and background stream links.
/// Supports custom schemes (`pizzastrada://`, `strada://`) and Universal/App Links (`https://pizzastrada.uz`).
class DeepLinkService {
  static final DeepLinkService instance = DeepLinkService._();
  DeepLinkService._();

  late final AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;
  bool _isInitialized = false;

  /// Initialize deep link listener
  Future<void> init() async {
    if (_isInitialized) return;
    _appLinks = AppLinks();

    // 1. Handle link from cold start (app was terminated and opened via link)
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        debugPrint('🔗 [DeepLink] Initial URI caught: $initialUri');
        _handleDeepLink(initialUri, isColdStart: true);
      }
    } catch (e) {
      debugPrint('⚠️ [DeepLink] Failed to get initial link: $e');
    }

    // 2. Listen to incoming links while app is running (foreground or background)
    _linkSubscription = _appLinks.uriLinkStream.listen(
      (uri) {
        debugPrint('🔗 [DeepLink] Incoming URI received: $uri');
        _handleDeepLink(uri, isColdStart: false);
      },
      onError: (err) {
        debugPrint('⚠️ [DeepLink] Stream error: $err');
      },
    );

    _isInitialized = true;
    debugPrint('✅ [DeepLinkService] Initialized and listening for links');
  }

  /// Parse URI and navigate using appRouter
  void _handleDeepLink(Uri uri, {required bool isColdStart}) {
    final rawUrl = uri.toString();
    AnalyticsService.instance.logAppOpen(rawUrl);
    AnalyticsService.instance.logEvent('deep_link_received', {
      'url': rawUrl,
      'is_cold_start': isColdStart,
    });

    final targetPath = parseUriToRoute(uri);
    if (targetPath != null) {
      debugPrint('🚀 [DeepLink] Navigating to target route: $targetPath');
      // If cold start, allow initial router setup to finish before redirecting
      if (isColdStart) {
        Future.delayed(const Duration(milliseconds: 300), () {
          appRouter.go(targetPath);
        });
      } else {
        appRouter.go(targetPath);
      }
    } else {
      debugPrint('⚠️ [DeepLink] Unknown or unsupported URI format: $uri');
    }
  }

  /// Maps custom URI scheme or HTTPS URL to GoRouter route path
  String? parseUriToRoute(Uri uri) {
    String path = uri.path;

    // Handle custom scheme: pizzastrada://product/peperoni or pizzastrada://cart
    // In some cases with custom schemes, host becomes first segment: uri.host = "product", uri.path = "/peperoni"
    if (uri.scheme == 'pizzastrada' || uri.scheme == 'strada') {
      if (uri.host.isNotEmpty && !uri.host.contains('.')) {
        path = '/${uri.host}${uri.path}';
      }
    }

    // Normalize path
    if (!path.startsWith('/')) {
      path = '/$path';
    }

    // Strip trailing slash if present (except root '/')
    if (path.length > 1 && path.endsWith('/')) {
      path = path.substring(0, path.length - 1);
    }

    final segments = path.split('/').where((s) => s.isNotEmpty).toList();

    if (segments.isEmpty) {
      return '/home';
    }

    final first = segments[0].toLowerCase();

    // 1. Product details: /product/:slug or /products/:slug
    if ((first == 'product' || first == 'products') && segments.length > 1) {
      final slug = segments[1];
      return '/product/$slug';
    }

    // 2. Order details: /order/:id or /orders/:id
    if (first == 'order' && segments.length > 1) {
      final id = segments[1];
      return '/order/$id';
    }

    // 3. Cart: /cart
    if (first == 'cart') {
      return '/cart';
    }

    // 4. Checkout: /checkout
    if (first == 'checkout') {
      return '/checkout';
    }

    // 5. Orders: /orders
    if (first == 'orders') {
      return '/orders';
    }

    // 6. Profile: /profile
    if (first == 'profile') {
      return '/profile';
    }

    // 7. Home: /home
    if (first == 'home') {
      return '/home';
    }

    return null;
  }

  /// Dispose listener
  void dispose() {
    _linkSubscription?.cancel();
    _linkSubscription = null;
    _isInitialized = false;
  }
}
