import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:pizza_strada/features/orders/domain/entities/order_entity.dart';
import 'package:pizza_strada/features/orders/domain/usecases/get_orders_usecase.dart';

abstract class OrderState extends Equatable {
  const OrderState();
  @override
  List<Object?> get props => [];
}

class OrderInitial extends OrderState {}
class OrderLoading extends OrderState {}
class OrderLoaded extends OrderState {
  final List<OrderEntity> orders;
  const OrderLoaded(this.orders);
  @override
  List<Object?> get props => [orders];
}
class OrderFailure extends OrderState {
  final String message;
  const OrderFailure(this.message);
  @override
  List<Object?> get props => [message];
}

@injectable
class OrderCubit extends Cubit<OrderState> {
  final GetOrdersUseCase _getOrdersUseCase;

  OrderCubit(this._getOrdersUseCase) : super(OrderInitial());

  Future<void> getOrders() async {
    emit(OrderLoading());
    final result = await _getOrdersUseCase();
    result.fold(
      (f) => emit(OrderFailure(f.messageKey)),
      (orders) => emit(OrderLoaded(orders)),
    );
  }
}
