import 'package:pizza_strada/core/network/api_client.dart';
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
}

class PromotionsRemoteDataSourceImpl implements PromotionsRemoteDataSource {
  final ApiClient _client;

  PromotionsRemoteDataSourceImpl([ApiClient? client]) : _client = client ?? ApiClient();

  @override
  Future<PromotionsPayload> getPromotions() async {
    final response = await _client.get('promotions');
    final data = response['data'];

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
}

