import 'package:dartz/dartz.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:injectable/injectable.dart';
import 'package:pizza_strada/core/error/failures.dart';
import 'package:pizza_strada/features/orders/data/datasources/order_remote_datasource.dart';
import 'package:pizza_strada/features/orders/domain/entities/order_entity.dart';
import 'package:pizza_strada/features/orders/domain/repositories/order_repository.dart';

@LazySingleton(as: OrderRepository)
class OrderRepositoryImpl implements OrderRepository {
  final OrderRemoteDataSource _remoteDataSource;

  OrderRepositoryImpl(this._remoteDataSource);

  @override
  Future<Either<Failure, List<OrderEntity>>> getOrders() async {
    try {
      final result = await _remoteDataSource.getOrders();
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
  Future<Either<Failure, int>> createOrder({
    required String fullName,
    required String phone,
    required String address,
    required String branchId,
    required bool isDelivery,
    required List<Map<String, dynamic>> items,
  }) async {
    try {
      final result = await _remoteDataSource.createOrder(
        fullName: fullName,
        phone: phone,
        address: address,
        branchId: branchId,
        isDelivery: isDelivery,
        items: items,
      );
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
