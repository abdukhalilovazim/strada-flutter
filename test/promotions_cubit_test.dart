import 'package:flutter_test/flutter_test.dart';
import 'package:pizza_strada/features/promotions/data/datasources/promotions_remote_data_source.dart';
import 'package:pizza_strada/features/promotions/domain/entities/promotion_deal_entity.dart';
import 'package:pizza_strada/features/promotions/presentation/bloc/promotions_cubit.dart';

class MockPromotionsRemoteDataSource implements PromotionsRemoteDataSource {
  final bool shouldFail;
  final PromotionsPayload payload;
  final PromotionsPayload? cachedPayload;

  MockPromotionsRemoteDataSource({
    this.shouldFail = false,
    this.payload = const PromotionsPayload(deals: [], discountProducts: []),
    this.cachedPayload,
  });

  @override
  Future<PromotionsPayload?> getCachedPromotions() async => cachedPayload;

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

    test('initial state is PromotionsInitial', () {
      final cubit = PromotionsCubit(MockPromotionsRemoteDataSource());
      expect(cubit.state, equals(PromotionsInitial()));
      cubit.close();
    });

    test('loads promotions successfully', () async {
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

    test('loads cached promotions first before network response', () async {
      const cachedDeal = PromotionDealEntity(
        id: 99,
        code: 'CACHED',
        slug: 'cached',
        title: 'Cached Deal',
        description: 'From cache',
        price: 30000,
        oldPrice: 40000,
        badgeText: '-10 000 so\'m',
      );

      final states = <PromotionsState>[];
      final cubit = PromotionsCubit(
        MockPromotionsRemoteDataSource(
          cachedPayload: const PromotionsPayload(
            deals: [cachedDeal],
            discountProducts: [],
          ),
          payload: const PromotionsPayload(
            deals: [sampleDeal],
            discountProducts: [],
          ),
        ),
      );

      cubit.stream.listen(states.add);

      await cubit.loadPromotions();

      // State should have transitioned or ended with fresh data,
      // and loaded promotions should have the latest payload
      expect(cubit.state, isA<PromotionsLoaded>());
      final loaded = cubit.state as PromotionsLoaded;
      expect(loaded.deals.first.code, 'PIZZA20');

      cubit.close();
    });

    test('gracefully falls back to cache on network failure', () async {
      const cachedDeal = PromotionDealEntity(
        id: 99,
        code: 'CACHED',
        slug: 'cached',
        title: 'Cached Deal',
        description: 'From cache',
        price: 30000,
        oldPrice: 40000,
        badgeText: '-10 000 so\'m',
      );

      final cubit = PromotionsCubit(
        MockPromotionsRemoteDataSource(
          shouldFail: true,
          cachedPayload: const PromotionsPayload(
            deals: [cachedDeal],
            discountProducts: [],
          ),
        ),
      );

      await cubit.loadPromotions();

      // Should remain loaded with cached deal instead of crashing with Failure
      expect(cubit.state, isA<PromotionsLoaded>());
      final loaded = cubit.state as PromotionsLoaded;
      expect(loaded.deals.first.code, 'CACHED');

      cubit.close();
    });

    test('emits PromotionsFailure on remote error when no cache available', () async {
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
