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

    // ⚡ 2. Staged API Sequence: Fetch primary SDUI layout first to prevent server 500 stampedes
    final sduiResult = await _getSDUIPageUseCase(slug: 'home');

    await sduiResult.fold(
      (failure) async {
        // Fallback: If SDUI endpoint fails, sequentially fetch domain data step-by-step
        if (kDebugMode) {
          debugPrint('⚠️ [HomeCubit] SDUI fetch failed (${failure.messageKey}). Falling back to sequential domain queries.');
        }

        final categoriesCol = await _getCategoriesUseCase();
        final productsCol = await _getProductsUseCase();
        final slidersCol = await _getSlidersUseCase();
        final settingsCol = await _getSettingsUseCase();

        final categories = categoriesCol.getOrElse(() => const []);
        final products = productsCol.getOrElse(() => const []);
        final sliders = slidersCol.getOrElse(() => const []);
        final settings = settingsCol.fold((_) => null, (s) => s);

        final defaultSlug = categories.isNotEmpty ? categories.first.slug : null;
        final initialProducts = defaultSlug != null
            ? products.where((p) => p.category?.slug == defaultSlug).toList()
            : products;

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
      (serverSduiPage) async {
        // ⚡ 3. Extract items directly from SDUI layout (eliminates 4 redundant HTTP calls)
        final categories = _extractCategoriesFromSDUI(serverSduiPage);
        final fullProducts = _extractProductsFromSDUI(serverSduiPage);
        final sliders = _extractSlidersFromSDUI(serverSduiPage);

        final defaultSlug = categories.isNotEmpty ? categories.first.slug : null;
        final initialProducts = defaultSlug != null
            ? fullProducts.where((p) => p.category?.slug == defaultSlug).toList()
            : fullProducts;

        // Background non-blocking settings query
        SettingsEntity? settings;
        try {
          final settingsCol = await _getSettingsUseCase();
          settings = settingsCol.fold((_) => null, (s) => s);
        } catch (_) {}

        final String? oldVersionUuid = cachedPage?.versionUuid ??
            ((state is HomeLoaded) ? (state as HomeLoaded).currentVersionUuid : null);
        final String newVersionUuid = serverSduiPage.versionUuid;

        final bool isVersionMismatch = forceRefresh ||
            oldVersionUuid == null ||
            oldVersionUuid != newVersionUuid ||
            cachedPage == null;

        if (kDebugMode) {
          debugPrint('📡 [SDUI Sync] oldVersionUuid: "$oldVersionUuid", newVersionUuid: "$newVersionUuid" (isMismatch: $isVersionMismatch)');
        }

        // Always save fresh layout to persistent cache
        _cacheManager.savePage(serverSduiPage);

        // Transition to the new UI structure
        emit(HomeLoaded(
          sliders: sliders,
          categories: categories,
          fullProducts: fullProducts,
          products: initialProducts,
          settings: settings,
          selectedCategory: defaultSlug,
          sduiPage: serverSduiPage,
          currentVersionUuid: newVersionUuid,
          isUpdatingUI: false,
        ));
      },
    );
  }

  List<CategoryEntity> _extractCategoriesFromSDUI(SDUIPageModel page) {
    for (final section in page.sections) {
      if (section.type == 'horizontal_category_bar') {
        return section.items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final slug = item.properties['slug']?.toString() ?? item.id;
          final title = item.properties['title']?.toString() ?? slug;
          return CategoryEntity(
            id: index + 1,
            title: title,
            slug: slug,
          );
        }).toList();
      }
    }
    return const [];
  }

  List<ProductEntity> _extractProductsFromSDUI(SDUIPageModel page) {
    for (final section in page.sections) {
      if (section.type == 'product_grid') {
        return section.items.map((item) {
          final props = item.properties;
          final catMap = props['category'] as Map<String, dynamic>?;
          final variantsList = props['variants'] as List<dynamic>?;

          final thumb = props['thumbnail']?.toString() ?? props['photo']?.toString() ?? '';
          final photo = props['photo']?.toString() ?? props['thumbnail']?.toString() ?? '';

          return ProductEntity(
            slug: props['slug']?.toString() ?? item.id,
            title: props['title']?.toString() ?? '',
            description: props['description']?.toString(),
            thumbnail: thumb,
            photo: photo.isNotEmpty ? photo : thumb,
            price: (props['price'] as num?)?.toDouble() ?? 0.0,
            category: catMap != null
                ? CategoryEntity(
                    id: 0,
                    slug: catMap['slug']?.toString() ?? '',
                    title: catMap['title']?.toString() ?? '',
                  )
                : null,
            variants: variantsList
                    ?.map((v) => VariantEntity(
                          id: (v['id'] as num?)?.toInt() ?? 0,
                          title: v['title']?.toString() ?? '',
                          price: (v['price'] as num?)?.toDouble() ?? 0.0,
                        ))
                    .toList() ??
                const [],
            values: const [],
          );
        }).toList();
      }
    }
    return const [];
  }

  List<SliderEntity> _extractSlidersFromSDUI(SDUIPageModel page) {
    for (final section in page.sections) {
      if (section.type == 'carousel_slider') {
        return section.items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return SliderEntity(
            id: index + 1,
            imageUrl: item.properties['image_url']?.toString() ?? item.properties['image']?.toString() ?? '',
            link: item.action?.target,
            title: item.properties['caption']?.toString(),
          );
        }).toList();
      }
    }
    return const [];
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
