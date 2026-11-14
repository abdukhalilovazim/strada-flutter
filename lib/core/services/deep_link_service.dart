import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:pizza_strada/core/router/app_router.dart';
import 'package:pizza_strada/core/services/analytics_service.dart';
import 'package:url_launcher/url_launcher.dart';

/// Deep Link Service handling cold-start links, background stream links,
/// and in-app clicks (e.g. slider banners, push notifications, promo buttons).
/// Primary Deeplink Domain: `app.pizzastrada.uz`
/// Supports:
/// - Universal / App Links: `https://app.pizzastrada.uz/*`
/// - Custom Schemes: `strada://*`, `pizzastrada://*`
class DeepLinkService {
  static final DeepLinkService instance = DeepLinkService._();
  DeepLinkService._();

  static const String primaryDomain = 'app.pizzastrada.uz';
  static const List<String> supportedHosts = [
    'app.pizzastrada.uz',
    'pizzastrada.uz',
    'www.pizzastrada.uz',
  ];

  late final AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;
  bool _isInitialized = false;

  /// Helper to generate a full universal link URL for app.pizzastrada.uz
  static String buildUrl(String path) {
    final cleanPath = path.startsWith('/') ? path : '/$path';
    return 'https://$primaryDomain$cleanPath';
  }

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
    debugPrint('✅ [DeepLinkService] Initialized and listening for $primaryDomain');
  }

  /// Direct method to handle any string link from banners, notifications, buttons, etc.
  Future<void> handleStringLink(String rawLink) async {
    var text = rawLink.trim().replaceAll('"', '').replaceAll("'", '');
    if (text.isEmpty) return;

    debugPrint('🔗 [DeepLinkService] Handling link: $text');

    // 1. Phone call (tel:+998...)
    if (text.startsWith('tel:')) {
      final uri = Uri.tryParse(text);
      if (uri != null && await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
      return;
    }

    // 2. Normalize domain if written without https:// (e.g. app.pizzastrada.uz/product/margarita)
    if (text.startsWith('app.pizzastrada.uz') || text.startsWith('pizzastrada.uz')) {
      text = 'https://$text';
    }

    // 3. Relative route starting with / (e.g. /promotions, /product/margarita)
    if (text.startsWith('/')) {
      final targetPath = parsePathToRoute(text);
      if (targetPath != null) {
        _navigate(targetPath);
        return;
      }
    }

    // 4. Full URI (e.g. https://app.pizzastrada.uz/..., strada://...)
    final uri = Uri.tryParse(text);
    if (uri != null) {
      final targetPath = parseUriToRoute(uri);
      if (targetPath != null) {
        _navigate(targetPath);
        return;
      }

      // 5. External URL (http:// or https:// not matching app routes)
      if (uri.scheme == 'http' || uri.scheme == 'https') {
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
        return;
      }
    }
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
          _navigate(targetPath);
        });
      } else {
        _navigate(targetPath);
      }
    } else {
      debugPrint('⚠️ [DeepLink] Unknown or unsupported URI format: $uri');
    }
  }

  /// Maps custom URI scheme or HTTPS URL (app.pizzastrada.uz) to GoRouter route path
  String? parseUriToRoute(Uri uri) {
    // 1. Custom schemes: strada://... or pizzastrada://...
    if (uri.scheme == 'pizzastrada' || uri.scheme == 'strada') {
      String path = uri.path;
      if (uri.host.isNotEmpty && !uri.host.contains('.')) {
        path = '/${uri.host}${uri.path}';
      }
      return parsePathToRoute(path);
    }

    // 2. Web App Links & Universal Links: app.pizzastrada.uz (or pizzastrada.uz)
    final host = uri.host.toLowerCase();
    if (supportedHosts.contains(host)) {
      return parsePathToRoute(uri.path);
    }

    // 3. Fallback: if scheme is empty and looks like relative path
    if (uri.scheme.isEmpty && uri.path.isNotEmpty) {
      return parsePathToRoute(uri.path);
    }

    return null;
  }

  /// Parse path string (e.g. '/product/peperoni', '/promotions', '/cart')
  String? parsePathToRoute(String rawPath) {
    String path = rawPath.trim();

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

    // 5. Orders history: /orders
    if (first == 'orders') {
      return '/orders';
    }

    // 6. Profile & Edit Profile: /profile, /profile/edit
    if (first == 'profile') {
      if (segments.length > 1 && segments[1].toLowerCase() == 'edit') {
        return '/profile/edit';
      }
      return '/profile';
    }

    // 7. Promotions / Kuponlar: /promotions, /coupons
    if (first == 'promotions' || first == 'coupons' || first == 'promo') {
      return '/promotions';
    }

    // 8. Branches / Filiallar: /branches, /branch
    if (first == 'branches' || first == 'branch') {
      return '/branches';
    }

    // 9. Notifications: /notifications, /notification
    if (first == 'notifications' || first == 'notification') {
      return '/notifications';
    }

    // 10. Saved Addresses: /saved-addresses, /locations
    if (first == 'saved-addresses' || first == 'addresses' || first == 'locations') {
      return '/saved-addresses';
    }

    // 11. Home: /home
    if (first == 'home') {
      return '/home';
    }

    return null;
  }

  void _navigate(String targetPath) {
    debugPrint('🚀 [DeepLink] Navigating to: $targetPath');
    final isShellTab = targetPath == '/home' ||
        targetPath == '/promotions' ||
        targetPath == '/cart' ||
        targetPath == '/orders' ||
        targetPath == '/profile';

    if (isShellTab) {
      appRouter.go(targetPath);
    } else {
      appRouter.push(targetPath);
    }
  }

  /// Dispose listener
  void dispose() {
    _linkSubscription?.cancel();
    _linkSubscription = null;
    _isInitialized = false;
  }
}
