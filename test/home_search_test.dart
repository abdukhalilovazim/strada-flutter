import 'package:flutter_test/flutter_test.dart';
import 'package:pizza_strada/core/sdui/sdui.dart';
import 'package:pizza_strada/features/home/domain/entities/home_entities.dart';
import 'package:pizza_strada/features/home/domain/usecases/home_usecases.dart';
import 'package:pizza_strada/features/home/presentation/bloc/home_cubit.dart';

class FakeCategoriesUseCase implements GetCategoriesUseCase {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeSlidersUseCase implements GetSlidersUseCase {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeProductsUseCase implements GetProductsUseCase {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeSDUIPageUseCase implements GetSDUIPageUseCase {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeSDUIManifestUseCase implements GetSDUIManifestUseCase {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late HomeCubit cubit;

  final sampleProducts = [
    const ProductEntity(
      slug: 'chicken-pizza',
      title: 'Chicken Pizza',
      description: 'Mazali tovuqli pitsa',
      thumbnail: '',
      photo: '',
      price: 59000,
      variants: [],
      values: [],
    ),
    const ProductEntity(
      slug: 'beef-burger',
      title: 'Beef Burger',
      description: 'Mol go\'shti bilan burger',
      thumbnail: '',
      photo: '',
      price: 44000,
      variants: [],
      values: [],
    ),
    const ProductEntity(
      slug: 'coca-cola',
      title: 'Coca Cola 0.5L',
      description: 'Muzdek ichimlik',
      thumbnail: '',
      photo: '',
      price: 12000,
      variants: [],
      values: [],
    ),
  ];

  setUp(() {
    cubit = HomeCubit(
      FakeCategoriesUseCase(),
      FakeSlidersUseCase(),
      FakeProductsUseCase(),
      FakeSDUIPageUseCase(),
      FakeSDUIManifestUseCase(),
    );
  });

  tearDown(() {
    cubit.close();
  });

  test('Search filters products accurately and case-insensitively', () {
    final sduiPage = SDUIScreenBuilder.buildHomeScreen(
      sliders: const [],
      categories: const [],
      products: sampleProducts,
    );

    cubit.emit(HomeLoaded(
      sliders: const [],
      categories: const [],
      fullProducts: sampleProducts,
      products: sampleProducts,
      sduiPage: sduiPage,
    ));

    // 1. Search "burger"
    cubit.search('BURGER');
    expect(cubit.state, isA<HomeLoaded>());
    final state1 = cubit.state as HomeLoaded;
    expect(state1.products.length, 1);
    expect(state1.products.first.slug, 'beef-burger');

    // 2. Search description "tovuqli"
    cubit.search('tovuqli');
    final state2 = cubit.state as HomeLoaded;
    expect(state2.products.length, 1);
    expect(state2.products.first.slug, 'chicken-pizza');

    // 3. Clear search with empty string
    cubit.search('');
    final state3 = cubit.state as HomeLoaded;
    expect(state3.products.length, 3);
  });
}
