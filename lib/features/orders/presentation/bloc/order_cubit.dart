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

  Future<void> getOrders({bool silent = false}) async {
    if (!silent || state is! OrderLoaded) {
      emit(OrderLoading());
    }
    final result = await _getOrdersUseCase();
    if (isClosed) return;
    result.fold(
      (f) {
        if (!silent || state is! OrderLoaded) {
          emit(OrderFailure(f.messageKey));
        }
      },
      (orders) => emit(OrderLoaded(orders)),
    );
  }

  /// ⚡ 0ms Instant State Update: Detail sahifasidan yangilangan status
  /// qaytganda buyurtmalar ro'yxatida uni darhol yangilash (In Progress -> Canceled)
  void updateOrder(OrderEntity updatedOrder) {
    if (state is OrderLoaded) {
      final currentList = (state as OrderLoaded).orders;
      final index = currentList.indexWhere((o) => o.id == updatedOrder.id);
      if (index != -1) {
        final newList = List<OrderEntity>.from(currentList);
        newList[index] = updatedOrder;
        emit(OrderLoaded(newList));
      }
    }
  }
}
