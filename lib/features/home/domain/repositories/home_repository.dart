import 'package:dartz/dartz.dart';
import 'package:pizza_strada/core/error/failures.dart';
import 'package:pizza_strada/features/home/domain/entities/home_entities.dart';

abstract class HomeRepository {
  Future<Either<Failure, List<CategoryEntity>>> getCategories();
  Future<Either<Failure, List<SliderEntity>>> getSliders();
  Future<Either<Failure, List<ProductEntity>>> getProducts({String? categorySlug});
  Future<Either<Failure, SettingsEntity>> getSettings();
}
