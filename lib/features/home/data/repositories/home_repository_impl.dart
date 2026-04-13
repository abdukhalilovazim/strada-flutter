import 'package:dartz/dartz.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:injectable/injectable.dart';
import 'package:pizza_strada/core/error/failures.dart';
import 'package:pizza_strada/features/home/data/datasources/home_remote_datasource.dart';
import 'package:pizza_strada/features/home/domain/entities/home_entities.dart';
import 'package:pizza_strada/features/home/domain/repositories/home_repository.dart';

@LazySingleton(as: HomeRepository)
class HomeRepositoryImpl implements HomeRepository {
  final HomeRemoteDataSource _remoteDataSource;

  HomeRepositoryImpl(this._remoteDataSource);

  @override
  Future<Either<Failure, List<CategoryEntity>>> getCategories() async {
    try {
      final result = await _remoteDataSource.getCategories();
      return Right(result);
    } catch (e) {
      String? errorMessage;
      if (e is OperationException && e.graphqlErrors.isNotEmpty) {
        errorMessage = e.graphqlErrors.first.message;
      }
      return Left(ServerFailure(message: errorMessage));
    }
  }

  @override
  Future<Either<Failure, List<SliderEntity>>> getSliders() async {
    try {
      final result = await _remoteDataSource.getSliders();
      return Right(result);
    } catch (e) {
      String? errorMessage;
      if (e is OperationException && e.graphqlErrors.isNotEmpty) {
        errorMessage = e.graphqlErrors.first.message;
      }
      return Left(ServerFailure(message: errorMessage));
    }
  }

  @override
  Future<Either<Failure, List<ProductEntity>>> getProducts({String? categorySlug}) async {
    try {
      final result = await _remoteDataSource.getProducts(categorySlug: categorySlug);
      return Right(result);
    } catch (e) {
      String? errorMessage;
      if (e is OperationException && e.graphqlErrors.isNotEmpty) {
        errorMessage = e.graphqlErrors.first.message;
      }
      return Left(ServerFailure(message: errorMessage));
    }
  }

  @override
  Future<Either<Failure, SettingsEntity>> getSettings() async {
    try {
      final result = await _remoteDataSource.getSettings();
      return Right(result);
    } catch (e) {
      String? errorMessage;
      if (e is OperationException && e.graphqlErrors.isNotEmpty) {
        errorMessage = e.graphqlErrors.first.message;
      }
      return Left(ServerFailure(message: errorMessage));
    }
  }
}
