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

class HomeUpdatingUI extends HomeState {
  final bool isSuccess;
  final String title;
  final String? subtitle;

  const HomeUpdatingUI({
    this.isSuccess = false,
    this.title = 'UI yangilanmoqda...',
    this.subtitle,
  });

  @override
  List<Object?> get props => [isSuccess, title, subtitle];
}

class HomeLoaded extends HomeState {
  final List<SliderEntity> sliders;
  final List<CategoryEntity> categories;
  final List<ProductEntity> fullProducts;
  final List<ProductEntity> products;
  final SettingsEntity? settings;
  final String? selectedCategory;
  final String searchQuery;
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
    this.searchQuery = '',
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
    String? searchQuery,
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
      searchQuery: searchQuery ?? this.searchQuery,
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
        searchQuery,
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
    // ⚡ 1. Peek local cached page and version
    final localCachedPage = await _cacheManager.getCachedPage('home');
    final localVersionUuid = localCachedPage?.versionUuid;

    // ⚡ 2. Check server version in lightweight manifest (~150 bytes) FIRST
    String? serverVersionUuid;
    bool hasManifestError = false;

    try {
      final manifestResult = await _getSDUIManifestUseCase();
      manifestResult.fold(
        (failure) {
          hasManifestError = true;
          if (kDebugMode) {
            debugPrint('⚠️ [HomeCubit] Manifest check failed (${failure.messageKey}).');
          }
        },
        (manifest) {
          final homeData = manifest['home'];
          if (homeData is Map<String, dynamic>) {
            serverVersionUuid = homeData['version_uuid']?.toString();
          } else if (homeData is String) {
            serverVersionUuid = homeData;
          }
        },
      );
    } catch (_) {
      hasManifestError = true;
    }

    // ⚡ 3. Check if versions match:
    final isVersionMatch = !forceRefresh &&
        localCachedPage != null &&
        (serverVersionUuid != null && serverVersionUuid == localVersionUuid);

    if (isVersionMatch || (hasManifestError && localCachedPage != null)) {
      // 🚀 ZERO-TRAFFIC CACHE HIT!
      // Versions match! Do NOT call full page API! Open UI immediately.
      if (kDebugMode) {
        debugPrint('⚡ [SDUI Zero-Traffic] Home versions match ($localVersionUuid). Skipping API! Instant load.');
      }
      _renderLoadedPage(localCachedPage);
      return;
    }

    // ⚡ 4. Version MISMATCH or cache empty:
    // User requirement:
    // "versiyalar bir xil bo'lmasa full screenda ui updated deb loader chiqsin va updated deb success icon chiqsin va ui ochilsin"
    if (kDebugMode) {
      debugPrint('🔄 [SDUI Sync] Home version mismatch (local: $localVersionUuid, server: $serverVersionUuid). Updating UI.');
    }

    emit(const HomeUpdatingUI(isSuccess: false));

    // Call full page API
    final sduiResult = await _getSDUIPageUseCase(slug: 'home');

    await sduiResult.fold(
      (failure) async {
        if (localCachedPage != null) {
          _renderLoadedPage(localCachedPage);
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
      },
      (serverSduiPage) async {
        final normalizedPage = _normalizeHomeLayout(serverSduiPage);

        // ⚡ Extract items and settings directly from SDUI layout (eliminates 4 redundant HTTP calls)
        final categories = _extractCategoriesFromSDUI(normalizedPage);
        final fullProducts = _extractProductsFromSDUI(normalizedPage);
        final sliders = _extractSlidersFromSDUI(normalizedPage);
        final settings = _extractSettingsFromSDUI(normalizedPage);

        final defaultSlug = categories.isNotEmpty ? categories.first.slug : null;
        final initialProducts = defaultSlug != null
            ? fullProducts.where((p) => p.category?.slug == defaultSlug).toList()
            : fullProducts;

        final String newVersionUuid = normalizedPage.versionUuid;

        if (kDebugMode) {
          debugPrint('💾 [SDUI Cache] Saved screen "home" with version UUID: $newVersionUuid');
        }

        // Always save fresh layout to persistent cache
        _cacheManager.savePage(normalizedPage);

        // Show success icon & text "UI yangilandi!"
        emit(const HomeUpdatingUI(isSuccess: true));

        // Wait brief moment for user to see success state
        await Future.delayed(const Duration(milliseconds: 700));

        // Transition to the new UI structure
        emit(HomeLoaded(
          sliders: sliders,
          categories: categories,
          fullProducts: fullProducts,
          products: initialProducts,
          settings: settings,
          selectedCategory: defaultSlug,
          sduiPage: normalizedPage,
          currentVersionUuid: newVersionUuid,
          isUpdatingUI: false,
        ));
      },
    );
  }

  void _renderLoadedPage(SDUIPageModel page) {
    final normalized = _normalizeHomeLayout(page);
    final categories = _extractCategoriesFromSDUI(normalized);
    final fullProducts = _extractProductsFromSDUI(normalized);
    final sliders = _extractSlidersFromSDUI(normalized);
    final settings = _extractSettingsFromSDUI(normalized);

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
      sduiPage: normalized,
      currentVersionUuid: normalized.versionUuid,
      isUpdatingUI: false,
    ));
  }

  SDUIPageModel _normalizeHomeLayout(SDUIPageModel page) {
    final sections = List<SDUISectionModel>.from(page.sections);

    // Remove redundant static text headers or redundant delivery cards
    sections.removeWhere((s) => s.type == 'section_header' || s.type == 'delivery_status_bar');

    // 1. Extract carousel slider if present
    SDUISectionModel? sliderSection;
    final sliderIdx = sections.indexWhere((s) => s.type == 'carousel_slider');
    if (sliderIdx != -1) {
      sliderSection = sections.removeAt(sliderIdx);
    }

    // 2. Extract category bar if present
    SDUISectionModel? categorySection;
    final catIdx = sections.indexWhere((s) => s.type == 'horizontal_category_bar');
    if (catIdx != -1) {
      categorySection = sections.removeAt(catIdx);
    }

    // 3. Re-insert slider at the very top (index 0)
    if (sliderSection != null) {
      sections.insert(0, sliderSection);
    }

    // 4. Re-insert category bar immediately after slider (index 1 or 0)
    if (categorySection != null) {
      final insertIdx = sliderSection != null ? 1 : 0;
      sections.insert(insertIdx, categorySection);
    }

    return SDUIPageModel(
      version: page.version,
      versionUuid: page.versionUuid,
      screenId: page.screenId,
      meta: page.meta,
      sections: sections,
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
      // ⚡ Search across all products by title or description
      filtered = currentState.fullProducts.where((p) {
        final matchTitle = p.title.toLowerCase().contains(lower);
        final matchDesc = p.description?.toLowerCase().contains(lower) ?? false;
        return matchTitle || matchDesc;
      }).toList();
    }

    // ⚡ 0ms Instant SDUI update
    final updatedSDUIPage = SDUIScreenBuilder.updatePageCategory(
      currentState.sduiPage,
      selectedCategorySlug: lower.isEmpty ? currentState.selectedCategory : null,
      filteredProducts: filtered,
      categories: currentState.categories,
    );

    emit(currentState.copyWith(
      searchQuery: trimmed,
      products: filtered,
      sduiPage: updatedSDUIPage,
      isUpdatingUI: false,
    ));
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

      // If search query is currently active, apply search filter too
      if (currentState.searchQuery.isNotEmpty) {
        final lower = currentState.searchQuery.toLowerCase();
        filteredProducts = filteredProducts.where((p) {
          final matchTitle = p.title.toLowerCase().contains(lower);
          final matchDesc = p.description?.toLowerCase().contains(lower) ?? false;
          return matchTitle || matchDesc;
        }).toList();
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
