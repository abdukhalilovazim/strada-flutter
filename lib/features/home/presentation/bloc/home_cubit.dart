import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
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
  final String? currentVersionUuid;
  final bool isUpdatingUI;

  const HomeLoaded({
    required this.sliders,
    required this.categories,
    required this.fullProducts,
    required this.products,
    required this.sduiPage,
    this.settings,
    this.selectedCategory,
    this.currentVersionUuid,
    this.isUpdatingUI = false,
  });

  HomeLoaded copyWith({
    List<SliderEntity>? sliders,
    List<CategoryEntity>? categories,
    List<ProductEntity>? fullProducts,
    List<ProductEntity>? products,
    SettingsEntity? settings,
    String? selectedCategory,
    SDUIPageModel? sduiPage,
    String? currentVersionUuid,
    bool? isUpdatingUI,
  }) {
    return HomeLoaded(
      sliders: sliders ?? this.sliders,
      categories: categories ?? this.categories,
      fullProducts: fullProducts ?? this.fullProducts,
      products: products ?? this.products,
      settings: settings ?? this.settings,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      sduiPage: sduiPage ?? this.sduiPage,
      currentVersionUuid: currentVersionUuid ?? this.currentVersionUuid,
      isUpdatingUI: isUpdatingUI ?? this.isUpdatingUI,
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
        currentVersionUuid,
        isUpdatingUI,
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

  Future<void> init({bool forceRefresh = false}) async {
    SDUIPageModel? cachedPage;

    // ⚡ 1. SWR 0ms Initial Paint: Load cached UI version immediately
    if (!forceRefresh) {
      cachedPage = await _cacheManager.getCachedPage('home');
      if (cachedPage != null && state is! HomeLoaded) {
        emit(HomeLoaded(
          sliders: const [],
          categories: const [],
          fullProducts: const [],
          products: const [],
          sduiPage: cachedPage,
          currentVersionUuid: cachedPage.versionUuid,
          isUpdatingUI: true, // Checking for background version sync
        ));
      } else if (state is! HomeLoaded) {
        emit(HomeLoading());
      }
    } else {
      // Pull-to-refresh or force update: clear cached page for fresh layout
      await _cacheManager.clearPage('home');
    }

    // ⚡ 2. Concurrent Background Fetch: SDUI Page + Domain Data
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
        // Fallback: If server is unreachable and no cache exists, compile local layout
        if (state is! HomeLoaded) {
          if (categories.isEmpty && products.isEmpty) {
            emit(HomeFailure(failure.messageKey));
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
            currentVersionUuid: localSduiPage.versionUuid,
            isUpdatingUI: false,
          ));
        } else {
          // If we already have a cached loaded state, just turn off isUpdatingUI
          final currentState = state as HomeLoaded;
          emit(currentState.copyWith(
            sliders: sliders.isNotEmpty ? sliders : currentState.sliders,
            categories: categories.isNotEmpty ? categories : currentState.categories,
            fullProducts: products.isNotEmpty ? products : currentState.fullProducts,
            products: initialProducts.isNotEmpty ? initialProducts : currentState.products,
            settings: settings ?? currentState.settings,
            isUpdatingUI: false,
          ));
        }
      },
      (serverSduiPage) {
        // ⚡ 3. UI Version UUID Comparison
        final String? oldVersionUuid = (state is HomeLoaded)
            ? (state as HomeLoaded).sduiPage.versionUuid
            : cachedPage?.versionUuid;
        final String newVersionUuid = serverSduiPage.versionUuid;

        final bool isVersionMismatch = (oldVersionUuid == null || oldVersionUuid != newVersionUuid);

        if (isVersionMismatch) {
          if (kDebugMode) {
            debugPrint('🔄 [SDUI Sync] UI Version changed: "$oldVersionUuid" -> "$newVersionUuid". Applying new layout & saving to cache.');
          }

          // Save new UI version to persistent cache
          _cacheManager.savePage(serverSduiPage);

          // Transition to the new UI structure
          emit(HomeLoaded(
            sliders: sliders,
            categories: categories,
            fullProducts: products,
            products: initialProducts,
            settings: settings,
            selectedCategory: defaultSlug,
            sduiPage: serverSduiPage,
            currentVersionUuid: newVersionUuid,
            isUpdatingUI: false,
          ));
        } else {
          if (kDebugMode) {
            debugPrint('✅ [SDUI Sync] UI Version matches "$oldVersionUuid". Preserving active UI layout intact!');
          }

          // UI has NOT changed: Keep existing layout tree intact, update only raw domain data
          if (state is HomeLoaded) {
            final currentState = state as HomeLoaded;
            emit(currentState.copyWith(
              sliders: sliders,
              categories: categories,
              fullProducts: products,
              products: initialProducts,
              settings: settings,
              currentVersionUuid: newVersionUuid,
              isUpdatingUI: false,
            ));
          } else {
            emit(HomeLoaded(
              sliders: sliders,
              categories: categories,
              fullProducts: products,
              products: initialProducts,
              settings: settings,
              selectedCategory: defaultSlug,
              sduiPage: serverSduiPage,
              currentVersionUuid: newVersionUuid,
              isUpdatingUI: false,
            ));
          }
        }
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

      // 1. Instant local optimistic update: strictly preserves existing server section order!
      final optimisticSDUIPage = SDUIScreenBuilder.updatePageCategory(
        currentState.sduiPage,
        selectedCategorySlug: nextCategorySlug,
        filteredProducts: filteredProducts,
        categories: currentState.categories,
      );

      emit(HomeLoaded(
        sliders: currentState.sliders,
        categories: currentState.categories,
        fullProducts: currentState.fullProducts,
        products: filteredProducts,
        settings: currentState.settings,
        selectedCategory: nextCategorySlug,
        sduiPage: optimisticSDUIPage,
        currentVersionUuid: currentState.currentVersionUuid,
        isUpdatingUI: false,
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
