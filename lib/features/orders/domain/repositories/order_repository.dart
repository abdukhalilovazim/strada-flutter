import 'package:dartz/dartz.dart';
import 'package:pizza_strada/core/error/failures.dart';
import 'package:pizza_strada/features/orders/domain/entities/order_entity.dart';

abstract class OrderRepository {
  Future<Either<Failure, List<OrderEntity>>> getOrders();
  Future<Either<Failure, Map<String, dynamic>>> createOrder(Map<String, dynamic> params);
}
