import 'dart:convert';
import 'package:easy_localization/easy_localization.dart';
import 'package:pizza_strada/core/constants/app_constants.dart';
import 'package:pizza_strada/core/network/api_client.dart';
import 'package:pizza_strada/core/storage/shared_prefs.dart';
import 'package:pizza_strada/features/home/data/models/home_models.dart';
import 'package:pizza_strada/features/home/domain/entities/home_entities.dart';
import '../../domain/entities/promotion_deal_entity.dart';

class PromotionsPayload {
  final List<PromotionDealEntity> deals;
  final List<ProductEntity> discountProducts;

  const PromotionsPayload({
    required this.deals,
    required this.discountProducts,
  });
}

abstract class PromotionsRemoteDataSource {
  Future<PromotionsPayload> getPromotions();
  Future<PromotionsPayload?> getCachedPromotions();
}

class PromotionsRemoteDataSourceImpl implements PromotionsRemoteDataSource {
  final ApiClient _client;

  PromotionsRemoteDataSourceImpl([ApiClient? client]) : _client = client ?? ApiClient();

  String _getCacheKey() {
    final context = AppConstants.navigatorKey.currentContext;
    final lang = (context != null && context.mounted)
        ? (EasyLocalization.of(context)?.locale.languageCode ?? 'ru')
        : 'uz';
    return 'cached_promotions_$lang';
  }

  PromotionsPayload _parsePayload(dynamic data) {
    List<PromotionDealEntity> deals = [];
    List<ProductEntity> discountProducts = [];

    if (data is Map<String, dynamic>) {
      final rawDeals = data['deals'] as List<dynamic>? ?? [];
      deals = rawDeals
          .whereType<Map<String, dynamic>>()
          .map((d) => PromotionDealEntity.fromJson(d))
          .toList();

      final rawProducts = data['discount_products'] as List<dynamic>? ?? [];
      discountProducts = rawProducts
          .whereType<Map<String, dynamic>>()
          .map((p) => ProductModel.fromJson(p))
          .toList();
    } else if (data is List) {
      deals = data
          .whereType<Map<String, dynamic>>()
          .map((d) => PromotionDealEntity.fromJson(d))
          .toList();
    }

    return PromotionsPayload(
      deals: deals,
      discountProducts: discountProducts,
    );
  }

  @override
  Future<PromotionsPayload?> getCachedPromotions() async {
    try {
      final key = _getCacheKey();
      final cachedJsonStr = SharedPrefs.getString(key);
      if (cachedJsonStr != null && cachedJsonStr.isNotEmpty) {
        final decoded = jsonDecode(cachedJsonStr);
        final dynamic data = (decoded is Map<String, dynamic> && decoded.containsKey('data'))
            ? decoded['data']
            : decoded;
        return _parsePayload(data);
      }
    } catch (_) {}
    return null;
  }

  @override
  Future<PromotionsPayload> getPromotions() async {
    final response = await _client.get('promotions');

    try {
      final key = _getCacheKey();
      await SharedPrefs.setString(key, jsonEncode(response));
    } catch (_) {}

    final dynamic data = (response is Map<String, dynamic> && response.containsKey('data'))
        ? response['data']
        : response;

    return _parsePayload(data);
  }
}
