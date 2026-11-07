import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:pizza_strada/features/home/domain/entities/home_entities.dart';
import 'package:pizza_strada/features/home/domain/usecases/home_usecases.dart';

abstract class HomeState extends Equatable {
  const HomeState();
  @override
  List<Object?> get props => [];
}

class HomeInitial extends HomeState {}
class HomeLoading extends HomeState {}

class HomeLoaded extends HomeState {
  final List<SliderEntity> sliders;
  final List<CategoryEntity> categories;
  final List<ProductEntity> fullProducts;
  final List<ProductEntity> products;
  final SettingsEntity? settings;
  final String? selectedCategory;
  final String searchQuery;

  const HomeLoaded({
    required this.sliders,
    required this.categories,
    required this.fullProducts,
    required this.products,
    this.settings,
    this.selectedCategory,
    this.searchQuery = '',
  });

  HomeLoaded copyWith({
    List<SliderEntity>? sliders,
    List<CategoryEntity>? categories,
    List<ProductEntity>? fullProducts,
    List<ProductEntity>? products,
    SettingsEntity? settings,
    String? selectedCategory,
    String? searchQuery,
  }) {
    return HomeLoaded(
      sliders: sliders ?? this.sliders,
      categories: categories ?? this.categories,
      fullProducts: fullProducts ?? this.fullProducts,
      products: products ?? this.products,
      settings: settings ?? this.settings,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  @override
  List<Object?> get props => [
        sliders,
        categories,
        fullProducts,
        products,
        settings,
        selectedCategory,
        searchQuery,
      ];
}

class HomeFailure extends HomeState {
  final String message;
  const HomeFailure(this.message);
  @override
  List<Object?> get props => [message];
}

@injectable
class HomeCubit extends Cubit<HomeState> {
  final GetCategoriesUseCase _getCategoriesUseCase;
  final GetSlidersUseCase _getSlidersUseCase;
  final GetProductsUseCase _getProductsUseCase;

  HomeCubit(
    this._getCategoriesUseCase,
    this._getSlidersUseCase,
    this._getProductsUseCase,
  ) : super(HomeInitial());

  Future<void> init({bool forceRefresh = false}) async {
    if (state is! HomeLoaded) {
      emit(HomeLoading());
    }

    try {
      final categoriesResult = await _getCategoriesUseCase();
      final productsResult = await _getProductsUseCase();
      final slidersResult = await _getSlidersUseCase();

      final categories = categoriesResult.getOrElse(() => const []);
      final products = productsResult.getOrElse(() => const []);
      final sliders = slidersResult.getOrElse(() => const []);

      if (categories.isEmpty && products.isEmpty) {
        emit(const HomeFailure('Katalog ma\'lumotlarini yuklab bo\'lmadi'));
        return;
      }

      final defaultSlug = categories.isNotEmpty ? categories.first.slug : null;
      final initialProducts = defaultSlug != null
          ? products.where((p) => p.category?.slug == defaultSlug).toList()
          : products;

      emit(HomeLoaded(
        sliders: sliders,
        categories: categories,
        fullProducts: products,
        products: initialProducts,
        selectedCategory: defaultSlug,
      ));
    } catch (e) {
      emit(HomeFailure(e.toString()));
    }
  }

  void search(String query) {
    final currentState = state;
    if (currentState is! HomeLoaded) return;

    final trimmed = query.trim();
    final lower = trimmed.toLowerCase();

    List<ProductEntity> filtered;
    if (lower.isEmpty) {
      if (currentState.selectedCategory != null && currentState.selectedCategory != 'all') {
        filtered = currentState.fullProducts
            .where((p) => p.category?.slug == currentState.selectedCategory)
            .toList();
      } else {
        filtered = currentState.fullProducts;
      }
    } else {
      filtered = currentState.fullProducts.where((p) {
        final matchTitle = p.title.toLowerCase().contains(lower);
        final matchDesc = p.description?.toLowerCase().contains(lower) ?? false;
        return matchTitle || matchDesc;
      }).toList();
    }

    emit(currentState.copyWith(
      searchQuery: trimmed,
      products: filtered,
    ));
  }

  Future<void> selectCategory(String? slug) async {
    final currentState = state;
    if (currentState is! HomeLoaded) return;

    String? nextCategorySlug = slug;
    List<ProductEntity> filteredProducts;

    if (slug == null || slug.isEmpty || slug == 'all' || currentState.selectedCategory == slug) {
      nextCategorySlug = null;
      filteredProducts = currentState.fullProducts;
    } else {
      filteredProducts = currentState.fullProducts
          .where((p) => p.category?.slug == slug)
          .toList();
    }

    if (currentState.searchQuery.isNotEmpty) {
      final lower = currentState.searchQuery.toLowerCase();
      filteredProducts = filteredProducts.where((p) {
        final matchTitle = p.title.toLowerCase().contains(lower);
        final matchDesc = p.description?.toLowerCase().contains(lower) ?? false;
        return matchTitle || matchDesc;
      }).toList();
    }

    emit(currentState.copyWith(
      products: filteredProducts,
      selectedCategory: nextCategorySlug,
    ));
  }
}
