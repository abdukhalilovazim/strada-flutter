import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:pizza_strada/core/sdui/sdui.dart';
import 'package:pizza_strada/features/home/data/models/home_models.dart';
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
  final GetSDUIPageUseCase _getSDUIPageUseCase;
  final GetSDUIManifestUseCase _getSDUIManifestUseCase;
  final SDUICacheManager _cacheManager = SDUICacheManager();

  HomeCubit(
    this._getCategoriesUseCase,
    this._getSlidersUseCase,
    this._getProductsUseCase,
    this._getSDUIPageUseCase,
    this._getSDUIManifestUseCase,
  ) : super(HomeInitial());

  Future<void> init({bool forceRefresh = false}) async {
    SDUIPageModel? cachedPage;

    // ⚡ 1. SWR 0ms Initial Paint: Load cached UI version immediately
    if (!forceRefresh) {
      cachedPage = await _cacheManager.getCachedPage('home');
      if (cachedPage != null) {
        final categories = _extractCategoriesFromSDUI(cachedPage);
        final fullProducts = _extractProductsFromSDUI(cachedPage);
        final sliders = _extractSlidersFromSDUI(cachedPage);
        final settings = _extractSettingsFromSDUI(cachedPage);

        final defaultSlug = categories.isNotEmpty ? categories.first.slug : null;
        final initialProducts = defaultSlug != null
            ? fullProducts.where((p) => p.category?.slug == defaultSlug).toList()
            : fullProducts;

        emit(HomeLoaded(
          sliders: sliders,
          categories: categories,
          fullProducts: fullProducts,
          products: initialProducts,
          settings: settings,
          selectedCategory: defaultSlug,
          sduiPage: cachedPage,
          currentVersionUuid: cachedPage.versionUuid,
          isUpdatingUI: true, // Checking for background manifest version sync
        ));
      } else if (state is! HomeLoaded) {
        emit(HomeLoading());
      }
    } else {
      if (state is HomeLoaded) {
        emit((state as HomeLoaded).copyWith(isUpdatingUI: true));
      } else {
        emit(HomeLoading());
      }
    }

    // ⚡ 2. Manifest check: Query lightweight manifest (~150 bytes) instead of downloading heavy full JSON
    String? serverVersionUuid;
    bool needsFullPageFetch = forceRefresh || cachedPage == null;

    if (!forceRefresh && cachedPage != null) {
      final manifestResult = await _getSDUIManifestUseCase();
      manifestResult.fold(
        (failure) {
          if (kDebugMode) {
            debugPrint('⚠️ [HomeCubit] Manifest check failed (${failure.messageKey}). Retaining local cache.');
          }
          needsFullPageFetch = false;
        },
        (manifest) {
          final homeData = manifest['home'];
          if (homeData is Map<String, dynamic>) {
            serverVersionUuid = homeData['version_uuid']?.toString();
          } else if (homeData is String) {
            serverVersionUuid = homeData;
          }

          if (serverVersionUuid != null && serverVersionUuid == cachedPage?.versionUuid) {
            // Version match! Zero-traffic cache hit!
            if (kDebugMode) {
              debugPrint('⚡ [SDUI Zero-Traffic] Local cache up-to-date ($serverVersionUuid). Skipping full home JSON fetch!');
            }
            needsFullPageFetch = false;
          } else {
            if (kDebugMode) {
              debugPrint('🔄 [SDUI Sync] Version mismatch (local: ${cachedPage?.versionUuid}, server: $serverVersionUuid). Fetching full layout.');
            }
            needsFullPageFetch = true;
          }
        },
      );
    }

    if (!needsFullPageFetch && cachedPage != null && state is HomeLoaded) {
      // Local cache is already up-to-date and rendered
      emit((state as HomeLoaded).copyWith(isUpdatingUI: false));
      return;
    }

    // ⚡ 3. Fetch full SDUI layout only when version changed or cache is empty
    final sduiResult = await _getSDUIPageUseCase(slug: 'home');

    await sduiResult.fold(
      (failure) async {
        if (state is HomeLoaded) {
          emit((state as HomeLoaded).copyWith(isUpdatingUI: false));
          return;
        }

        // Fallback: If SDUI endpoint fails, sequentially fetch domain data step-by-step
        if (kDebugMode) {
          debugPrint('⚠️ [HomeCubit] SDUI fetch failed (${failure.messageKey}). Falling back to sequential domain queries.');
        }

        final categoriesCol = await _getCategoriesUseCase();
        final productsCol = await _getProductsUseCase();
        final slidersCol = await _getSlidersUseCase();

        final categories = categoriesCol.getOrElse(() => const []);
        final products = productsCol.getOrElse(() => const []);
        final sliders = slidersCol.getOrElse(() => const []);

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
            settings: null,
            selectedCategorySlug: defaultSlug,
          );

          _cacheManager.savePage(localSduiPage);

          emit(HomeLoaded(
            sliders: sliders,
            categories: categories,
            fullProducts: products,
            products: initialProducts,
            settings: null,
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
            isUpdatingUI: false,
          ));
        }
      },
      (serverSduiPage) async {
        // ⚡ Extract items and settings directly from SDUI layout (eliminates 4 redundant HTTP calls)
        final categories = _extractCategoriesFromSDUI(serverSduiPage);
        final fullProducts = _extractProductsFromSDUI(serverSduiPage);
        final sliders = _extractSlidersFromSDUI(serverSduiPage);
        final settings = _extractSettingsFromSDUI(serverSduiPage);

        final defaultSlug = categories.isNotEmpty ? categories.first.slug : null;
        final initialProducts = defaultSlug != null
            ? fullProducts.where((p) => p.category?.slug == defaultSlug).toList()
            : fullProducts;

        final String newVersionUuid = serverSduiPage.versionUuid;

        if (kDebugMode) {
          debugPrint('💾 [SDUI Cache] Saved screen "home" with version UUID: $newVersionUuid');
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

  SettingsEntity? _extractSettingsFromSDUI(SDUIPageModel page) {
    final raw = page.rawSettings;
    if (raw != null) {
      try {
        return SettingsModel.fromJson(raw);
      } catch (e) {
        if (kDebugMode) {
          debugPrint('⚠️ [HomeCubit] Error parsing embedded settings: $e');
        }
      }
    }
    return null;
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

  Future<void> selectCategory(String? slug) async {
    final currentState = state;
    if (currentState is HomeLoaded) {
      String? nextCategorySlug = slug;
      List<ProductEntity> filteredProducts;

      if (slug == null || slug.isEmpty || slug == 'all' || currentState.selectedCategory == slug) {
        // Toggle unselect -> show all products
        nextCategorySlug = null;
        filteredProducts = currentState.fullProducts;
      } else {
        filteredProducts = currentState.fullProducts
            .where((p) => p.category?.slug == slug)
            .toList();
      }

      // 100% Instant local update (0ms, zero network lag): strictly preserves layout & section order
      final updatedSDUIPage = SDUIScreenBuilder.updatePageCategory(
        currentState.sduiPage,
        selectedCategorySlug: nextCategorySlug,
        filteredProducts: filteredProducts,
        categories: currentState.categories,
      );

      emit(currentState.copyWith(
        products: filteredProducts,
        selectedCategory: nextCategorySlug,
        sduiPage: updatedSDUIPage,
        isUpdatingUI: false,
      ));
    }
  }
}
