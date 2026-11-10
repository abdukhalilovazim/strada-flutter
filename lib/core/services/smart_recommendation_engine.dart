import 'package:flutter/foundation.dart';
import 'package:pizza_strada/core/di/injection.dart';
import 'package:pizza_strada/core/network/api_client.dart';
import 'package:pizza_strada/features/home/data/models/home_models.dart';
import 'package:pizza_strada/features/home/domain/entities/home_entities.dart';

/// 📦 Result of server-driven recommendation evaluation.
/// Zero client-side logic. All titles and candidates are 100% evaluated by backend.
class RecommendationMatch {
  final String title;
  final List<ProductEntity> products;

  const RecommendationMatch({
    required this.title,
    required this.products,
  });

  bool get isEmpty => products.isEmpty;
  bool get isNotEmpty => products.isNotEmpty;
}

/// 🧠 Smart Recommendation Engine (100% Backend-Driven)
/// Mobil tomonda hech qanday qattiq filtr yoki murakkab mantiq yo'q.
/// Barcha filtrlar, istisnolar, nisbatlar (masalan: 1 pitsaga 2 sous) va sarlavhalar
/// 100% backend (`/api/v1/recommendations`) orqali boshqariladi.
class SmartRecommendationEngine {
  static RecommendationMatch? _cachedMatch;
  static String? _lastItemsSignature;
  static bool _isLoading = false;

  /// Cached match for instant UI render
  static RecommendationMatch? get currentMatch => _cachedMatch;

  /// Fetches recommendations from backend for the given cart items.
  static Future<RecommendationMatch> fetch({
    List<Map<String, dynamic>>? items,
    List<int>? productIds,
    bool forceRefresh = false,
  }) async {
    // Items formatiga keltiramiz
    final normalizedItems = items ??
        (productIds ?? [])
            .map((id) => {'product_id': id, 'quantity': 1})
            .toList();

    if (normalizedItems.isEmpty) {
      _cachedMatch = null;
      _lastItemsSignature = null;
      return const RecommendationMatch(title: '', products: []);
    }

    // Savat holati imzosini hisoblaymiz (ID va Quantity o'zgarganda yangilanadi)
    final signature = normalizedItems
        .map((e) => '${e['product_id']}:${e['quantity']}')
        .join('|');

    // Cache check: Agar tovarlar va ularning soni o'zgarmagan bo'lsa -> keshdan darhol qaytarish
    if (!forceRefresh && _lastItemsSignature == signature) {
      return _cachedMatch ?? const RecommendationMatch(title: '', products: []);
    }

    if (_isLoading) {
      return _cachedMatch ?? const RecommendationMatch(title: '', products: []);
    }

    _isLoading = true;
    try {
      final client = getIt<ApiClient>();
      final response = await client.post('recommendations', body: {
        'items': normalizedItems,
      });

      if (response is Map<String, dynamic> && response['data'] is Map<String, dynamic>) {
        final data = response['data'] as Map<String, dynamic>;
        final title = data['title']?.toString() ?? '';
        final rawProducts = data['products'] as List? ?? [];

        final products = rawProducts
            .whereType<Map<String, dynamic>>()
            .map((e) => ProductModel.fromJson(e))
            .toList();

        _lastItemsSignature = signature;
        _cachedMatch = RecommendationMatch(title: title, products: products);
        return _cachedMatch!;
      } else {
        _lastItemsSignature = signature;
        _cachedMatch = const RecommendationMatch(title: '', products: []);
        return _cachedMatch!;
      }
    } catch (e) {
      debugPrint('Recommendations backend fetch error: $e');
      return _cachedMatch ?? const RecommendationMatch(title: '', products: []);
    } finally {
      _isLoading = false;
    }
  }

  /// Clears cache when cart is cleared.
  static void clear() {
    _cachedMatch = null;
    _lastItemsSignature = null;
  }

  /// Legacy helper for SDUI cross-sell components
  static RecommendationMatch resolve({
    dynamic cartItems,
    dynamic allProducts,
    String? localeCode,
  }) {
    return _cachedMatch ?? const RecommendationMatch(title: '', products: []);
  }
}
