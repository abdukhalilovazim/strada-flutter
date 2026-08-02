import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:pizza_strada/core/error/failures.dart';
import 'package:pizza_strada/core/utils/api_helper.dart';
import 'package:pizza_strada/features/home/data/datasources/home_remote_datasource.dart';
import 'package:pizza_strada/features/home/domain/entities/home_entities.dart';
import 'package:pizza_strada/features/home/domain/repositories/home_repository.dart';

@LazySingleton(as: HomeRepository)
class HomeRepositoryImpl implements HomeRepository {
  final HomeRemoteDataSource _remoteDataSource;

  HomeRepositoryImpl(this._remoteDataSource);

  @override
  Future<Either<Failure, List<CategoryEntity>>> getCategories() async {
    return _safeCall(() => _remoteDataSource.getCategories());
  }

  @override
  Future<Either<Failure, List<ProductEntity>>> getProducts({String? categorySlug}) async {
    return _safeCall(() => _remoteDataSource.getProducts(categorySlug: categorySlug));
  }

  @override
  Future<Either<Failure, SettingsEntity>> getSettings() async {
    return _safeCall(() => _remoteDataSource.getSettings());
  }

  Future<Either<Failure, T>> _safeCall<T>(Future<T> Function() call) async {
    try {
      final result = await call();
      return Right(result);
    } on SocketException catch (_) {
      debugPrint('❌ [SocketException] Internet aloqasi yo\'q');
      return Left(const NetworkFailure(message: 'Internet aloqasi yo\'q. Tarmoqni tekshiring.'));
    } on HttpException catch (e) {
      debugPrint('❌ [HttpException] ${e.message}');
      return Left(ServerFailure(message: 'Server xatosi: ${e.message}'));
    } catch (e) {
      debugPrint('❌ [HomeRepo Error] $e');
      return Left(ApiHelper.fromException(e));
    }
  }
}

