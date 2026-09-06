import 'package:appmetrica_plugin/appmetrica_plugin.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Analytics & AppMetrica service for PizzaStrada.
/// Provides safe tracking of events, screens, eCommerce actions, and deep links.
class AnalyticsService {
  static final AnalyticsService instance = AnalyticsService._();
  AnalyticsService._();

  bool _isInitialized = false;

  /// Initialize AppMetrica if API key is provided in .env
  Future<void> init() async {
    try {
      final apiKey = dotenv.env['APPMETRICA_API_KEY'];
      if (apiKey != null && apiKey.isNotEmpty && apiKey != 'YOUR_APPMETRICA_API_KEY') {
        await AppMetrica.activate(AppMetricaConfig(
          apiKey,
          logs: kDebugMode,
          crashReporting: true,
          sessionsAutoTrackingEnabled: true,
          appOpenTrackingEnabled: true,
        ));
        _isInitialized = true;
        debugPrint('✅ [AnalyticsService] AppMetrica initialized successfully');
      } else {
        debugPrint('ℹ️ [AnalyticsService] APPMETRICA_API_KEY not configured, running in mock/log mode');
      }
    } catch (e, stack) {
      debugPrint('⚠️ [AnalyticsService] Failed to initialize AppMetrica: $e\n$stack');
    }
  }

  /// General event logging
  Future<void> logEvent(String name, [Map<String, Object>? parameters]) async {
    if (kDebugMode) {
      debugPrint('📊 [Analytics] Event: $name | Params: $parameters');
    }
    if (!_isInitialized) return;
    try {
      if (parameters != null && parameters.isNotEmpty) {
        await AppMetrica.reportEventWithMap(name, parameters);
      } else {
        await AppMetrica.reportEvent(name);
      }
    } catch (e) {
      debugPrint('⚠️ [Analytics] Error reporting event: $e');
    }
  }

  /// App opened via deep link or standard launch
  Future<void> logAppOpen([String? deeplink]) async {
    await logEvent('app_open', deeplink != null ? {'deeplink': deeplink} : null);
    if (_isInitialized && deeplink != null) {
      try {
        await AppMetrica.reportAppOpen(deeplink);
      } catch (_) {}
    }
  }

  /// Screen / Page view tracking
  Future<void> logScreenView(String screenName) async {
    await logEvent('screen_view', {'screen_name': screenName});
  }

  /// User profile ID association
  Future<void> setUserProfileId(String userId) async {
    if (kDebugMode) {
      debugPrint('👤 [Analytics] Set User Profile ID: $userId');
    }
    if (!_isInitialized) return;
    try {
      await AppMetrica.setUserProfileID(userId);
    } catch (_) {}
  }

  /// Product viewed
  Future<void> logProductView({
    required String id,
    required String title,
    required double price,
    String? category,
  }) async {
    await logEvent('product_view', {
      'product_id': id,
      'product_name': title,
      'price': price,
      if (category != null) 'category': category,
    });
  }

  /// Product added to cart
  Future<void> logAddToCart({
    required String id,
    required String title,
    required int quantity,
    required double price,
    String? variant,
  }) async {
    await logEvent('add_to_cart', {
      'product_id': id,
      'product_name': title,
      'quantity': quantity,
      'price': price,
      if (variant != null) 'variant': variant,
      'total': price * quantity,
    });
  }

  /// Product removed from cart
  Future<void> logRemoveFromCart({
    required String id,
    required String title,
  }) async {
    await logEvent('remove_from_cart', {
      'product_id': id,
      'product_name': title,
    });
  }

  /// Checkout started (Step 1 -> Step 2)
  Future<void> logCheckoutStarted({
    required int itemCount,
    required double totalAmount,
    required bool isDelivery,
  }) async {
    await logEvent('checkout_started', {
      'items_count': itemCount,
      'total_amount': totalAmount,
      'type': isDelivery ? 'delivery' : 'pickup',
    });
  }

  /// Order successfully placed
  Future<void> logOrderPlaced({
    required String orderId,
    required double totalAmount,
    required String paymentMethod,
    required bool isDelivery,
    int? itemsCount,
  }) async {
    await logEvent('order_placed', {
      'order_id': orderId,
      'total_amount': totalAmount,
      'payment_method': paymentMethod,
      'delivery_type': isDelivery ? 'delivery' : 'pickup',
      if (itemsCount != null) 'items_count': itemsCount,
    });
  }

  /// Promo code applied
  Future<void> logPromoApplied({
    required String code,
    required double discount,
  }) async {
    await logEvent('promo_applied', {
      'promo_code': code,
      'discount_amount': discount,
    });
  }

  /// Error tracking
  Future<void> logError(String message, [dynamic error, StackTrace? stackTrace]) async {
    if (kDebugMode) {
      debugPrint('🚨 [Analytics] Error logged: $message | $error');
    }
    if (!_isInitialized) return;
    try {
      await AppMetrica.reportError(
        message: message,
        errorDescription: AppMetricaErrorDescription(
          stackTrace ?? StackTrace.current,
          message: error?.toString() ?? message,
        ),
      );
    } catch (_) {}
  }
}

/// NavigatorObserver that automatically tracks screen views to AppMetrica
class AppAnalyticsObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _reportRoute(route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (newRoute != null) {
      _reportRoute(newRoute);
    }
  }

  void _reportRoute(Route<dynamic> route) {
    final name = route.settings.name;
    if (name != null && name.isNotEmpty) {
      AnalyticsService.instance.logScreenView(name);
    }
  }
}
