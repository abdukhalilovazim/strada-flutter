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
  final List<CategoryEntity> categories;
  final List<ProductEntity> fullProducts;
  final List<ProductEntity> products;
  final SettingsEntity? settings;
  final String? selectedCategory;
  /// Banner slider'lar (Carousel uchun)
  final List<SliderEntity> sliders;

  const HomeLoaded({
    required this.categories,
    required this.fullProducts,
    required this.products,
    this.settings,
    this.selectedCategory,
    this.sliders = const [],
  });

  @override
  List<Object?> get props => [categories, fullProducts, products, settings, selectedCategory, sliders];
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
  final GetProductsUseCase _getProductsUseCase;
  final GetSettingsUseCase _getSettingsUseCase;

  HomeCubit(
    this._getCategoriesUseCase,
    this._getProductsUseCase,
    this._getSettingsUseCase,
  ) : super(HomeInitial());

  Future<void> init() async {
    emit(HomeLoading());
    final categoriesCol = await _getCategoriesUseCase();
    final productsCol   = await _getProductsUseCase();
    final settingsCol   = await _getSettingsUseCase();

    categoriesCol.fold(
      (f) => emit(HomeFailure(f.messageKey)),
      (categories) => productsCol.fold(
        (f) => emit(HomeFailure(f.messageKey)),
        (products) => settingsCol.fold(
          (f) => emit(HomeFailure(f.messageKey)),
          (settings) => emit(HomeLoaded(
            categories: categories,
            fullProducts: products,
            products: products,
            settings: settings,
            sliders: const [], // API dan slider endpoint qo'shilganda to'ldiriladi
          )),
        ),
      ),
    );
  }

  Future<void> selectCategory(String slug) async {
    final currentState = state;
    if (currentState is HomeLoaded) {
      if (currentState.selectedCategory == slug) {
        emit(HomeLoaded(
          categories: currentState.categories,
          fullProducts: currentState.fullProducts,
          products: currentState.fullProducts,
          settings: currentState.settings,
          selectedCategory: null,
          sliders: currentState.sliders,
        ));
        return;
      }

      final filteredProducts = currentState.fullProducts.where((p) {
        return p.category?.slug == slug;
      }).toList();

      emit(HomeLoaded(
        categories: currentState.categories,
        fullProducts: currentState.fullProducts,
        products: filteredProducts,
        settings: currentState.settings,
        selectedCategory: slug,
        sliders: currentState.sliders,
      ));
    }
  }
}
