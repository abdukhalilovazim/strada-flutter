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
  final bool isSlidersLoading;
  final List<CategoryEntity> categories;
  final List<ProductEntity> fullProducts;
  final List<ProductEntity> products;
  final String? selectedCategory;
  final String searchQuery;

  const HomeLoaded({
    this.sliders = const [],
    this.isSlidersLoading = false,
    required this.categories,
    required this.fullProducts,
    required this.products,
    this.selectedCategory,
    this.searchQuery = '',
  });

  HomeLoaded copyWith({
    List<SliderEntity>? sliders,
    bool? isSlidersLoading,
    List<CategoryEntity>? categories,
    List<ProductEntity>? fullProducts,
    List<ProductEntity>? products,
    String? selectedCategory,
    String? searchQuery,
  }) {
    return HomeLoaded(
      sliders: sliders ?? this.sliders,
      isSlidersLoading: isSlidersLoading ?? this.isSlidersLoading,
      categories: categories ?? this.categories,
      fullProducts: fullProducts ?? this.fullProducts,
      products: products ?? this.products,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  @override
  List<Object?> get props => [
        sliders,
        isSlidersLoading,
        categories,
        fullProducts,
        products,
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
      final categoriesFuture = _getCategoriesUseCase();
      final productsFuture = _getProductsUseCase();
      final slidersFuture = _getSlidersUseCase();

      final categoriesResult = await categoriesFuture;
      final productsResult = await productsFuture;
      final slidersResult = await slidersFuture;

      var categories = categoriesResult.getOrElse(() => const []);
      final products = productsResult.getOrElse(() => const []);
      final sliders = slidersResult.getOrElse(() => const []);

      if (categories.isEmpty && products.isEmpty) {
        emit(const HomeFailure('Katalog ma\'lumotlarini yuklab bo\'lmadi'));
        return;
      }

      // Agar Set-menyu mavjud bo'lsa, har doim 3-kategoriya o'rnida (index 2) bo'lishini ta'minlaymiz
      final setIndex = categories.indexWhere(
        (c) => c.slug == 'set-menus' || c.id == 999999,
      );
      if (setIndex != -1 && categories.length > 2) {
        final mutableCategories = List<CategoryEntity>.from(categories);
        final setCat = mutableCategories.removeAt(setIndex);
        mutableCategories.insert(2, setCat);
        categories = mutableCategories;
      }

      final defaultSlug = categories.isNotEmpty ? categories.first.slug : null;

      emit(HomeLoaded(
        sliders: sliders,
        isSlidersLoading: false,
        categories: categories,
        fullProducts: products,
        products: products,
        selectedCategory: defaultSlug,
      ));
    } catch (e) {
      emit(HomeFailure(e.toString()));
    }
  }

  Future<void> loadSliders() async {
    final currentState = state;
    if (currentState is! HomeLoaded) return;

    try {
      final slidersResult = await _getSlidersUseCase();
      final sliders = slidersResult.getOrElse(() => const []);
      final stateNow = state;
      if (stateNow is HomeLoaded) {
        emit(stateNow.copyWith(
          sliders: sliders,
          isSlidersLoading: false,
        ));
      }
    } catch (_) {
      final stateNow = state;
      if (stateNow is HomeLoaded) {
        emit(stateNow.copyWith(isSlidersLoading: false));
      }
    }
  }

  void search(String query) {
    final currentState = state;
    if (currentState is! HomeLoaded) return;

    final trimmed = query.trim();
    final lower = trimmed.toLowerCase();

    List<ProductEntity> filtered;
    if (lower.isEmpty) {
      filtered = currentState.fullProducts;
    } else {
      filtered = currentState.fullProducts.where((p) {
        final matchTitle = p.title.toLowerCase().contains(lower);
        final matchDesc = p.description?.toLowerCase().contains(lower) ?? false;
        final matchKeywords = p.searchKeywords?.toLowerCase().contains(lower) ?? false;
        final matchSlug = p.slug.toLowerCase().contains(lower);
        return matchTitle || matchDesc || matchKeywords || matchSlug;
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
    if (currentState.selectedCategory == slug) return;

    emit(currentState.copyWith(
      selectedCategory: slug,
    ));
  }
}
