import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:pizza_strada/core/error/failures.dart';
import 'package:pizza_strada/core/utils/graphql_helper.dart';
import 'package:pizza_strada/features/orders/data/datasources/order_remote_datasource.dart';
import 'package:pizza_strada/features/orders/domain/entities/order_entity.dart';
import 'package:pizza_strada/features/orders/domain/repositories/order_repository.dart';

@LazySingleton(as: OrderRepository)
class OrderRepositoryImpl implements OrderRepository {
  final OrderRemoteDataSource _remoteDataSource;

  OrderRepositoryImpl(this._remoteDataSource);

  @override
  Future<Either<Failure, List<OrderEntity>>> getOrders() async {
    return _safeCall(() => _remoteDataSource.getOrders());
  }

  @override
  Future<Either<Failure, int>> createOrder({
    required String fullName,
    required String phone,
    required String address,
    required String branchId,
    required bool isDelivery,
    required List<Map<String, dynamic>> items,
  }) async {
    return _safeCall(() => _remoteDataSource.createOrder(
          fullName: fullName,
          phone: phone,
          address: address,
          branchId: branchId,
          isDelivery: isDelivery,
          items: items,
        ));
  }

  Future<Either<Failure, T>> _safeCall<T>(Future<T> Function() call) async {
    try {
      return Right(await call());
    } on OperationException catch (e) {
      debugPrint('❌ [OrderRepo] $e');
      return Left(GraphQLHelper.toFailure(e));
    } on SocketException {
      return Left(const NetworkFailure(message: 'Internet aloqasi yo\'q'));
    } catch (e) {
      debugPrint('❌ [OrderRepo] $e');
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
