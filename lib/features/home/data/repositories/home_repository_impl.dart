import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
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
    return _safeCall(() => _remoteDataSource.getCategories());
  }

  @override
  Future<Either<Failure, List<SliderEntity>>> getSliders() async {
    return _safeCall(() => _remoteDataSource.getSliders());
  }

  @override
  Future<Either<Failure, List<ProductEntity>>> getProducts({String? categorySlug}) async {
    return _safeCall(() => _remoteDataSource.getProducts(categorySlug: categorySlug));
  }

  @override
  Future<Either<Failure, SettingsEntity>> getSettings() async {
    return _safeCall(() => _remoteDataSource.getSettings());
  }

  /// Barcha API so'rovlari uchun umumiy xato tutuvchi (error handler).
  ///
  /// Xato turlariga qarab tegishli [Failure] qaytaradi:
  /// - [SocketException] / [HttpException] → [NetworkFailure] (internet yo'q)
  /// - [OperationException] → GraphQL / Link xatosi
  /// - Boshqa xatolar → [ServerFailure]
  Future<Either<Failure, T>> _safeCall<T>(Future<T> Function() call) async {
    try {
      final result = await call();
      return Right(result);
    } on OperationException catch (e) {
      debugPrint('❌ [OperationException] $e');
      return Left(_handleOperationException(e));
    } on SocketException catch (_) {
      debugPrint('❌ [SocketException] Internet aloqasi yo\'q');
      return Left(const NetworkFailure(message: 'Internet aloqasi yo\'q. Tarmoqni tekshiring.'));
    } on HttpException catch (e) {
      debugPrint('❌ [HttpException] ${e.message}');
      return Left(ServerFailure(message: 'Server xatosi: ${e.message}'));
    } catch (e) {
      debugPrint('❌ [Unknown Error] $e');
      return Left(ServerFailure(message: e.toString()));
    }
  }

  /// GraphQL [OperationException] ichidan aniq xato xabarini chiqaradi.
  ///
  /// Agar graphqlErrors bo'lsa — server qaytargan xabar.
  /// Agar linkException bo'lsa — tarmoq yoki firewall (Security360) xatosi.
  Failure _handleOperationException(OperationException e) {
    // 1. GraphQL server xatosi (masalan: validation, auth error)
    if (e.graphqlErrors.isNotEmpty) {
      final message = e.graphqlErrors.map((err) => err.message).join(', ');
      return ServerFailure(message: message);
    }

    // 2. Link exception — tarmoq, SSL, yoki firewall (Security360) xatosi
    final linkException = e.linkException;
    if (linkException != null) {
      // Server javob qaytargan bo'lsa (masalan: 403 Forbidden)
      if (linkException is HttpLinkServerException) {
        final statusCode = linkException.response.statusCode;
        if (statusCode == 403) {
          return const ServerFailure(message: 'So\'rov bloklandi (403). Security sozlamalarini tekshiring.');
        }
        return ServerFailure(message: 'Server xatosi (HTTP $statusCode)');
      }

      // Tarmoq xatosi (timeout, DNS xatosi va h.k.)
      if (linkException is NetworkException) {
        return NetworkFailure(message: 'Tarmoq xatosi: ${linkException.message}');
      }

      // Boshqa link xatolari
      return ServerFailure(message: 'Ulanish xatosi: ${linkException.toString().length > 100 ? linkException.toString().substring(0, 100) : linkException.toString()}');
    }

    return const ServerFailure(message: 'Noma\'lum xato yuz berdi');
  }
}
