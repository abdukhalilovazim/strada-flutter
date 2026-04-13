import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:pizza_strada/core/error/failures.dart';
import 'package:pizza_strada/features/home/domain/entities/home_entities.dart';
import 'package:pizza_strada/features/home/domain/repositories/home_repository.dart';

@lazySingleton
class GetCategoriesUseCase {
  final HomeRepository _repository;
  GetCategoriesUseCase(this._repository);
  Future<Either<Failure, List<CategoryEntity>>> call() => _repository.getCategories();
}

@lazySingleton
class GetSlidersUseCase {
  final HomeRepository _repository;
  GetSlidersUseCase(this._repository);
  Future<Either<Failure, List<SliderEntity>>> call() => _repository.getSliders();
}

@lazySingleton
class GetProductsUseCase {
  final HomeRepository _repository;
  GetProductsUseCase(this._repository);
  Future<Either<Failure, List<ProductEntity>>> call({String? categorySlug}) =>
      _repository.getProducts(categorySlug: categorySlug);
}

@lazySingleton
class GetSettingsUseCase {
  final HomeRepository _repository;
  GetSettingsUseCase(this._repository);
  Future<Either<Failure, SettingsEntity>> call() => _repository.getSettings();
}
