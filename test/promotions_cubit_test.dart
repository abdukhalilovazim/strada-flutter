import 'package:flutter_test/flutter_test.dart';
import 'package:pizza_strada/features/promotions/data/datasources/promotions_remote_data_source.dart';
import 'package:pizza_strada/features/promotions/domain/entities/promotion_deal_entity.dart';
import 'package:pizza_strada/features/promotions/presentation/bloc/promotions_cubit.dart';

class MockPromotionsRemoteDataSource implements PromotionsRemoteDataSource {
  final bool shouldFail;
  final PromotionsPayload payload;

  MockPromotionsRemoteDataSource({
    this.shouldFail = false,
    this.payload = const PromotionsPayload(deals: [], discountProducts: []),
  });

  @override
  Future<PromotionsPayload> getPromotions() async {
    if (shouldFail) {
      throw Exception('Server error loading promotions');
    }
    return payload;
  }
}

void main() {
  group('PromotionsCubit Tests', () {
    test('initial state is PromotionsInitial', () {
      final cubit = PromotionsCubit(MockPromotionsRemoteDataSource());
      expect(cubit.state, equals(PromotionsInitial()));
      cubit.close();
    });

    test('loads promotions successfully', () async {
      const sampleDeal = PromotionDealEntity(
        id: 1,
        code: 'PIZZA20',
        slug: 'pizza20',
        title: '20% off',
        description: 'Special coupon',
        price: 50000,
        oldPrice: 62500,
        badgeText: '-12 500 so\'m',
      );

      final cubit = PromotionsCubit(
        MockPromotionsRemoteDataSource(
          payload: const PromotionsPayload(
            deals: [sampleDeal],
            discountProducts: [],
          ),
        ),
      );

      await cubit.loadPromotions();

      expect(cubit.state, isA<PromotionsLoaded>());
      final loaded = cubit.state as PromotionsLoaded;
      expect(loaded.deals.length, 1);
      expect(loaded.deals.first.code, 'PIZZA20');
      expect(loaded.discountProducts, isEmpty);

      cubit.close();
    });

    test('emits PromotionsFailure on remote error', () async {
      final cubit = PromotionsCubit(
        MockPromotionsRemoteDataSource(shouldFail: true),
      );

      await cubit.loadPromotions();

      expect(cubit.state, isA<PromotionsFailure>());
      final failure = cubit.state as PromotionsFailure;
      expect(failure.message, contains('Server error loading promotions'));

      cubit.close();
    });
  });
}

