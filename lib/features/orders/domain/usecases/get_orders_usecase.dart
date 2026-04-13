import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:pizza_strada/core/error/failures.dart';
import 'package:pizza_strada/features/orders/domain/entities/order_entity.dart';
import 'package:pizza_strada/features/orders/domain/repositories/order_repository.dart';

@lazySingleton
class GetOrdersUseCase {
  final OrderRepository _repository;
  GetOrdersUseCase(this._repository);
  Future<Either<Failure, List<OrderEntity>>> call() => _repository.getOrders();
}
