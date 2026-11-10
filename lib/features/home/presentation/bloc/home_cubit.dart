import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:pizza_strada/features/home/domain/entities/home_entities.dart';
import 'package:pizza_strada/features/home/domain/usecases/home_usecases.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class HomeState extends Equatable {
  const HomeState();
  @override
  List<Object?> get props => [];
}

class HomeInitial extends HomeState {}
class HomeLoading extends HomeState {}

class HomeLoaded extends HomeState {
  final List<SliderEntity> sliders;
  final List<StoryEntity> stories;
  final bool isStoriesLoading;
  final List<CategoryEntity> categories;
  final List<ProductEntity> fullProducts;
  final List<ProductEntity> products;
  final String? selectedCategory;
  final String searchQuery;

  const HomeLoaded({
    this.sliders = const [],
    this.stories = const [],
    this.isStoriesLoading = false,
    required this.categories,
    required this.fullProducts,
    required this.products,
    this.selectedCategory,
    this.searchQuery = '',
  });

  HomeLoaded copyWith({
    List<SliderEntity>? sliders,
    List<StoryEntity>? stories,
    bool? isStoriesLoading,
    List<CategoryEntity>? categories,
    List<ProductEntity>? fullProducts,
    List<ProductEntity>? products,
    String? selectedCategory,
    String? searchQuery,
  }) {
    return HomeLoaded(
      sliders: sliders ?? this.sliders,
      stories: stories ?? this.stories,
      isStoriesLoading: isStoriesLoading ?? this.isStoriesLoading,
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
        stories,
        isStoriesLoading,
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
  final GetStoriesUseCase _getStoriesUseCase;
  final GetProductsUseCase _getProductsUseCase;

  HomeCubit(
    this._getCategoriesUseCase,
    this._getStoriesUseCase,
    this._getProductsUseCase,
  ) : super(HomeInitial());

  Future<void> init({bool forceRefresh = false}) async {
    if (state is! HomeLoaded) {
      emit(HomeLoading());
    }

    try {
      final categoriesResult = await _getCategoriesUseCase();
      final productsResult = await _getProductsUseCase();

      final categories = categoriesResult.getOrElse(() => const []);
      final products = productsResult.getOrElse(() => const []);

      if (categories.isEmpty && products.isEmpty) {
        emit(const HomeFailure('Katalog ma\'lumotlarini yuklab bo\'lmadi'));
        return;
      }

      final defaultSlug = categories.isNotEmpty ? categories.first.slug : null;
      final initialProducts = defaultSlug != null
          ? products.where((p) => p.category?.slug == defaultSlug).toList()
          : products;

      final existingStories = (state is HomeLoaded) ? (state as HomeLoaded).stories : const <StoryEntity>[];

      emit(HomeLoaded(
        sliders: const [],
        stories: existingStories,
        isStoriesLoading: existingStories.isEmpty,
        categories: categories,
        fullProducts: products,
        products: initialProducts,
        selectedCategory: defaultSlug,
      ));
    } catch (e) {
      emit(HomeFailure(e.toString()));
    }
  }

  Future<void> loadStories() async {
    final currentState = state;
    if (currentState is HomeLoaded && currentState.stories.isNotEmpty) {
      return;
    }

    if (currentState is HomeLoaded) {
      emit(currentState.copyWith(isStoriesLoading: true));
    }

    try {
      final storiesResult = await _getStoriesUseCase();
      final rawStories = storiesResult.getOrElse(() => const []);

      List<StoryEntity> stories = rawStories;
      try {
        final prefs = await SharedPreferences.getInstance();
        final viewedIds = prefs.getStringList('viewed_story_ids') ?? [];
        stories = rawStories.map((story) {
          final isViewed = viewedIds.contains(story.id.toString());
          return story.copyWith(isViewed: isViewed);
        }).toList();
      } catch (_) {}

      final stateNow = state;
      if (stateNow is HomeLoaded) {
        emit(stateNow.copyWith(
          stories: stories,
          isStoriesLoading: false,
        ));
      }
    } catch (_) {
      final stateNow = state;
      if (stateNow is HomeLoaded) {
        emit(stateNow.copyWith(isStoriesLoading: false));
      }
    }
  }

  Future<void> markStoryViewed(int storyId) async {
    final currentState = state;
    if (currentState is! HomeLoaded) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final viewedIds = prefs.getStringList('viewed_story_ids') ?? [];
      final idStr = storyId.toString();
      if (!viewedIds.contains(idStr)) {
        viewedIds.add(idStr);
        await prefs.setStringList('viewed_story_ids', viewedIds);
      }
    } catch (_) {}

    final updatedStories = currentState.stories.map((story) {
      if (story.id == storyId) {
        return story.copyWith(isViewed: true);
      }
      return story;
    }).toList();

    emit(currentState.copyWith(stories: updatedStories));
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
