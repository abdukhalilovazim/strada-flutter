import 'package:flutter_test/flutter_test.dart';
import 'package:pizza_strada/features/home/domain/entities/home_entities.dart';
import 'package:pizza_strada/features/home/presentation/bloc/home_cubit.dart';

void main() {
  group('Native Home State Tests', () {
    test('HomeLoaded state holds products, categories, sliders correctly', () {
      const sampleProduct = ProductEntity(
        slug: 'pepperoni',
        title: 'Pepperoni',
        price: 65000,
        thumbnail: '',
        photo: '',
        variants: [],
        values: [],
      );
      const state = HomeLoaded(
        sliders: [SliderEntity(id: 1, imageUrl: 'https://strada.uz/s1.jpg')],
        categories: [CategoryEntity(id: 1, title: 'Pizza', slug: 'pizza')],
        fullProducts: [sampleProduct],
        products: [sampleProduct],
        selectedCategory: 'pizza',
      );

      expect(state.sliders.length, 1);
      expect(state.categories.length, 1);
      expect(state.products.length, 1);
      expect(state.selectedCategory, 'pizza');
      expect(state.searchQuery, '');
    });

    test('HomeLoaded copyWith updates filters cleanly', () {
      const state = HomeLoaded(
        sliders: [],
        categories: [],
        fullProducts: [],
        products: [],
        selectedCategory: null,
      );

      final updated = state.copyWith(selectedCategory: 'drinks', searchQuery: 'cola');
      expect(updated.selectedCategory, 'drinks');
      expect(updated.searchQuery, 'cola');
    });
  });
}
