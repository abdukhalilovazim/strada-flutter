import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:pizza_strada/core/sdui/sdui.dart';
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
  final SDUIPageModel sduiPage;

  const HomeLoaded({
    required this.sliders,
    required this.categories,
    required this.fullProducts,
    required this.products,
    required this.sduiPage,
    this.settings,
    this.selectedCategory,
  });

  @override
  List<Object?> get props => [
        sliders,
        categories,
        fullProducts,
        products,
        settings,
        selectedCategory,
        sduiPage,
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
  final GetSettingsUseCase _getSettingsUseCase;
  final SDUICacheManager _cacheManager = SDUICacheManager();

  HomeCubit(
    this._getCategoriesUseCase,
    this._getSlidersUseCase,
    this._getProductsUseCase,
    this._getSettingsUseCase,
  ) : super(HomeInitial());

  Future<void> init() async {
    // ⚡ Stale-While-Revalidate (SWR): Check offline cache first for 0ms paint
    final cachedPage = await _cacheManager.getCachedPage('home_feed');
    if (cachedPage != null && state is! HomeLoaded) {
      emit(HomeLoaded(
        sliders: const [],
        categories: const [],
        fullProducts: const [],
        products: const [],
        sduiPage: cachedPage,
      ));
    } else if (state is! HomeLoaded) {
      emit(HomeLoading());
    }

    final slidersCol = await _getSlidersUseCase();
    final categoriesCol = await _getCategoriesUseCase();
    final productsCol = await _getProductsUseCase();
    final settingsCol = await _getSettingsUseCase();

    slidersCol.fold(
      (f) {
        if (state is! HomeLoaded) emit(HomeFailure(f.messageKey));
      },
      (sliders) => categoriesCol.fold(
        (f) {
          if (state is! HomeLoaded) emit(HomeFailure(f.messageKey));
        },
        (categories) => productsCol.fold(
          (f) {
            if (state is! HomeLoaded) emit(HomeFailure(f.messageKey));
          },
          (products) => settingsCol.fold(
            (f) {
              if (state is! HomeLoaded) emit(HomeFailure(f.messageKey));
            },
            (settings) {
              final defaultSlug = categories.isNotEmpty ? categories.first.slug : null;

              // Filter products by default active category
              final initialProducts = defaultSlug != null
                  ? products.where((p) => p.category?.slug == defaultSlug).toList()
                  : products;

              // Compile declarative SDUI page schema
              final sduiPage = SDUIScreenBuilder.buildHomeScreen(
                sliders: sliders,
                categories: categories,
                products: initialProducts,
                settings: settings,
                selectedCategorySlug: defaultSlug,
              );

              // Persist locally for instant offline launches
              _cacheManager.savePage(sduiPage);

              emit(HomeLoaded(
                sliders: sliders,
                categories: categories,
                fullProducts: products,
                products: initialProducts,
                settings: settings,
                selectedCategory: defaultSlug,
                sduiPage: sduiPage,
              ));
            },
          ),
        ),
      ),
    );
  }

  Future<void> selectCategory(String slug) async {
    final currentState = state;
    if (currentState is HomeLoaded) {
      String? nextCategorySlug = slug;
      List<ProductEntity> filteredProducts;

      if (currentState.selectedCategory == slug) {
        // Toggle unselect -> show all products
        nextCategorySlug = null;
        filteredProducts = currentState.fullProducts;
      } else {
        filteredProducts = currentState.fullProducts
            .where((p) => p.category?.slug == slug)
            .toList();
      }

      // Rebuild dynamic SDUI layout with filtered items
      final updatedSDUIPage = SDUIScreenBuilder.buildHomeScreen(
        sliders: currentState.sliders,
        categories: currentState.categories,
        products: filteredProducts,
        settings: currentState.settings,
        selectedCategorySlug: nextCategorySlug,
      );

      emit(HomeLoaded(
        sliders: currentState.sliders,
        categories: currentState.categories,
        fullProducts: currentState.fullProducts,
        products: filteredProducts,
        settings: currentState.settings,
        selectedCategory: nextCategorySlug,
        sduiPage: updatedSDUIPage,
      ));
    }
  }
}
