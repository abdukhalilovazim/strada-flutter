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

  HomeLoaded copyWith({
    List<SliderEntity>? sliders,
    List<CategoryEntity>? categories,
    List<ProductEntity>? fullProducts,
    List<ProductEntity>? products,
    SettingsEntity? settings,
    String? selectedCategory,
    SDUIPageModel? sduiPage,
  }) {
    return HomeLoaded(
      sliders: sliders ?? this.sliders,
      categories: categories ?? this.categories,
      fullProducts: fullProducts ?? this.fullProducts,
      products: products ?? this.products,
      settings: settings ?? this.settings,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      sduiPage: sduiPage ?? this.sduiPage,
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
  final GetSDUIPageUseCase _getSDUIPageUseCase;
  final SDUICacheManager _cacheManager = SDUICacheManager();

  HomeCubit(
    this._getCategoriesUseCase,
    this._getSlidersUseCase,
    this._getProductsUseCase,
    this._getSettingsUseCase,
    this._getSDUIPageUseCase,
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

    // 1. Fetch backend SDUI page and raw domain data concurrently
    final sduiResultFuture = _getSDUIPageUseCase(slug: 'home');
    final slidersColFuture = _getSlidersUseCase();
    final categoriesColFuture = _getCategoriesUseCase();
    final productsColFuture = _getProductsUseCase();
    final settingsColFuture = _getSettingsUseCase();

    final sduiResult = await sduiResultFuture;
    final slidersCol = await slidersColFuture;
    final categoriesCol = await categoriesColFuture;
    final productsCol = await productsColFuture;
    final settingsCol = await settingsColFuture;

    final sliders = slidersCol.getOrElse(() => const []);
    final categories = categoriesCol.getOrElse(() => const []);
    final products = productsCol.getOrElse(() => const []);
    final settings = settingsCol.fold((_) => null, (s) => s);

    final defaultSlug = categories.isNotEmpty ? categories.first.slug : null;
    final initialProducts = defaultSlug != null
        ? products.where((p) => p.category?.slug == defaultSlug).toList()
        : products;

    sduiResult.fold(
      (failure) {
        // Fallback: If server SDUI endpoint is unreachable, compile layout locally!
        if (categories.isEmpty && products.isEmpty) {
          if (state is! HomeLoaded) emit(HomeFailure(failure.messageKey));
          return;
        }

        final localSduiPage = SDUIScreenBuilder.buildHomeScreen(
          sliders: sliders,
          categories: categories,
          products: initialProducts,
          settings: settings,
          selectedCategorySlug: defaultSlug,
        );

        _cacheManager.savePage(localSduiPage);

        emit(HomeLoaded(
          sliders: sliders,
          categories: categories,
          fullProducts: products,
          products: initialProducts,
          settings: settings,
          selectedCategory: defaultSlug,
          sduiPage: localSduiPage,
        ));
      },
      (serverSduiPage) {
        // Success: Use server-driven layout directly!
        _cacheManager.savePage(serverSduiPage);

        emit(HomeLoaded(
          sliders: sliders,
          categories: categories,
          fullProducts: products,
          products: initialProducts,
          settings: settings,
          selectedCategory: defaultSlug,
          sduiPage: serverSduiPage,
        ));
      },
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

      // 1. Instant local optimistic update for sub-16ms tactile responsiveness
      final optimisticSDUIPage = SDUIScreenBuilder.buildHomeScreen(
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
        sduiPage: optimisticSDUIPage,
      ));

      // 2. Fetch server-driven layout for the selected category in background
      final serverResult = await _getSDUIPageUseCase(
        slug: 'home',
        categorySlug: nextCategorySlug,
      );

      serverResult.fold(
        (_) => null, // If failed, optimistic local layout is already active
        (serverPage) {
          if (state is HomeLoaded && (state as HomeLoaded).selectedCategory == nextCategorySlug) {
            emit((state as HomeLoaded).copyWith(sduiPage: serverPage));
          }
        },
      );
    }
  }
}
