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
  final List<ProductEntity> products;
  final SettingsEntity? settings;
  final String? selectedCategory;

  const HomeLoaded({
    required this.sliders,
    required this.categories,
    required this.products,
    this.settings,
    this.selectedCategory,
  });

  @override
  List<Object?> get props => [sliders, categories, products, settings, selectedCategory];
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

  HomeCubit(
    this._getCategoriesUseCase,
    this._getSlidersUseCase,
    this._getProductsUseCase,
    this._getSettingsUseCase,
  ) : super(HomeInitial());

  Future<void> init() async {
    emit(HomeLoading());
    final slidersCol    = await _getSlidersUseCase();
    final categoriesCol = await _getCategoriesUseCase();
    final productsCol   = await _getProductsUseCase();
    final settingsCol   = await _getSettingsUseCase();

    slidersCol.fold(
      (f) => emit(HomeFailure(f.messageKey)),
      (sliders) => categoriesCol.fold(
        (f) => emit(HomeFailure(f.messageKey)),
        (categories) => productsCol.fold(
          (f) => emit(HomeFailure(f.messageKey)),
          (products) => settingsCol.fold(
            (f) => emit(HomeFailure(f.messageKey)),
            (settings) => emit(HomeLoaded(
              sliders: sliders,
              categories: categories,
              products: products,
              settings: settings,
            )),
          ),
        ),
      ),
    );
  }

  Future<void> selectCategory(String slug) async {
    final currentState = state;
    if (currentState is HomeLoaded) {
      if (currentState.selectedCategory == slug) return;

      emit(HomeLoading());
      final productsCol = await _getProductsUseCase(categorySlug: slug);

      productsCol.fold(
        (f) => emit(HomeFailure(f.messageKey)),
        (products) => emit(HomeLoaded(
          sliders: currentState.sliders,
          categories: currentState.categories,
          products: products,
          settings: currentState.settings,
          selectedCategory: slug,
        )),
      );
    }
  }
}
