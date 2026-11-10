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
/// Barcha filtrlar, istisnolar va sarlavhalar backend (`/api/v1/recommendations`) orqali boshqariladi.
class SmartRecommendationEngine {
  static RecommendationMatch? _cachedMatch;
  static List<int>? _lastProductIds;
  static bool _isLoading = false;

  /// Cached match for instant UI render
  static RecommendationMatch? get currentMatch => _cachedMatch;

  /// Fetches recommendations from backend for the given cart product IDs.
  static Future<RecommendationMatch> fetch({
    required List<int> productIds,
    bool forceRefresh = false,
  }) async {
    if (productIds.isEmpty) {
      _cachedMatch = null;
      _lastProductIds = null;
      return const RecommendationMatch(title: '', products: []);
    }

    // Cache check: If product IDs haven't changed, return cached match
    if (!forceRefresh && _lastProductIds != null && _listEquals(_lastProductIds!, productIds)) {
      return _cachedMatch ?? const RecommendationMatch(title: '', products: []);
    }

    if (_isLoading) {
      return _cachedMatch ?? const RecommendationMatch(title: '', products: []);
    }

    _isLoading = true;
    try {
      final client = getIt<ApiClient>();
      final response = await client.post('recommendations', body: {
        'product_ids': productIds,
      });

      if (response is Map<String, dynamic> && response['data'] is Map<String, dynamic>) {
        final data = response['data'] as Map<String, dynamic>;
        final title = data['title']?.toString() ?? '';
        final rawProducts = data['products'] as List? ?? [];

        final products = rawProducts
            .whereType<Map<String, dynamic>>()
            .map((e) => ProductModel.fromJson(e))
            .toList();

        _lastProductIds = List<int>.from(productIds);
        _cachedMatch = RecommendationMatch(title: title, products: products);
        return _cachedMatch!;
      } else {
        _lastProductIds = List<int>.from(productIds);
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

  static bool _listEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  /// Clears cache when cart is cleared.
  static void clear() {
    _cachedMatch = null;
    _lastProductIds = null;
  }
}
