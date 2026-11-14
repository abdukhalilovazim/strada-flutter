import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pizza_strada/core/error/failures.dart';
import 'package:pizza_strada/features/orders/domain/entities/order_entity.dart';
import 'package:pizza_strada/features/orders/domain/repositories/order_repository.dart';
import 'package:pizza_strada/features/orders/domain/usecases/get_orders_usecase.dart';
import 'package:pizza_strada/features/orders/presentation/bloc/order_cubit.dart';

class MockOrderRepository implements OrderRepository {
  List<OrderEntity> ordersToReturn = [];

  @override
  Future<Either<Failure, List<OrderEntity>>> getOrders() async {
    return Right(ordersToReturn);
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> createOrder(Map<String, dynamic> params) async {
    return const Right({});
  }
}

void main() {
  late MockOrderRepository mockRepository;
  late GetOrdersUseCase useCase;
  late OrderCubit cubit;

  final order1 = OrderEntity(
    id: 101,
    status: 4, // In progress
    statusText: 'Tayyorlanmoqda',
    subtotalPrice: 100000,
    discountAmount: 0,
    deliveryPrice: 10000,
    totalPrice: 110000,
    products: const [],
  );

  final order1Canceled = OrderEntity(
    id: 101,
    status: 1, // Canceled
    statusText: 'Bekor qilindi',
    subtotalPrice: 100000,
    discountAmount: 0,
    deliveryPrice: 10000,
    totalPrice: 110000,
    products: const [],
  );

  final order2 = OrderEntity(
    id: 102,
    status: 2,
    statusText: 'Yangi',
    subtotalPrice: 50000,
    discountAmount: 0,
    deliveryPrice: 10000,
    totalPrice: 60000,
    products: const [],
  );

  setUp(() {
    mockRepository = MockOrderRepository();
    useCase = GetOrdersUseCase(mockRepository);
    cubit = OrderCubit(useCase);
  });

  tearDown(() {
    cubit.close();
  });

  test('Initial state is OrderInitial', () {
    expect(cubit.state, isA<OrderInitial>());
  });

  test('getOrders loads orders and emits OrderLoaded', () async {
    mockRepository.ordersToReturn = [order1, order2];

    await cubit.getOrders();

    expect(cubit.state, isA<OrderLoaded>());
    final loaded = cubit.state as OrderLoaded;
    expect(loaded.orders.length, 2);
    expect(loaded.orders.first.status, 4);
  });

  test('updateOrder updates single order in-place without loading flicker', () async {
    mockRepository.ordersToReturn = [order1, order2];
    await cubit.getOrders();

    // Now update order1 to canceled
    cubit.updateOrder(order1Canceled);

    expect(cubit.state, isA<OrderLoaded>());
    final loaded = cubit.state as OrderLoaded;
    expect(loaded.orders.first.id, 101);
    expect(loaded.orders.first.status, 1);
    expect(loaded.orders.first.statusText, 'Bekor qilindi');
    expect(loaded.orders[1].id, 102);
  });

  test('getOrders(silent: true) preserves current loaded state without emitting OrderLoading', () async {
    mockRepository.ordersToReturn = [order1];
    await cubit.getOrders();

    mockRepository.ordersToReturn = [order1Canceled, order2];

    final states = <OrderState>[];
    cubit.stream.listen(states.add);

    await cubit.getOrders(silent: true);

    // Should NOT contain OrderLoading
    expect(states.any((s) => s is OrderLoading), isFalse);
    expect(cubit.state, isA<OrderLoaded>());
    final loaded = cubit.state as OrderLoaded;
    expect(loaded.orders.length, 2);
    expect(loaded.orders.first.status, 1);
  });
}
