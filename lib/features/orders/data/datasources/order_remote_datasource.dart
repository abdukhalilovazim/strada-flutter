import 'package:injectable/injectable.dart';
import 'package:pizza_strada/core/network/api_client.dart';
import 'package:pizza_strada/features/orders/data/models/order_model.dart';

abstract class OrderRemoteDataSource {
  Future<List<OrderModel>> getOrders();
  Future<OrderModel> getOrder(int id);
  Future<int> createOrder({
    required String fullName,
    required String phone,
    required String address,
    required String branchId,
    required bool isDelivery,
    required List<Map<String, dynamic>> items,
  });
}

@LazySingleton(as: OrderRemoteDataSource)
class OrderRemoteDataSourceImpl implements OrderRemoteDataSource {
  final ApiClient _client;

  OrderRemoteDataSourceImpl(this._client);

  @override
  Future<List<OrderModel>> getOrders() async {
    final response = await _client.get('orders');
    return (response as List).map((e) => OrderModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<OrderModel> getOrder(int id) async {
    final response = await _client.get('orders/$id');
    return OrderModel.fromJson(response as Map<String, dynamic>);
  }

  @override
  Future<int> createOrder({
    required String fullName,
    required String phone,
    required String address,
    required String branchId,
    required bool isDelivery,
    required List<Map<String, dynamic>> items,
  }) async {
    final response = await _client.post(
      'orders',
      body: {
        'type': isDelivery ? 0 : 1,
        'branch_id': isDelivery ? null : int.tryParse(branchId),
        'address': isDelivery ? address : null,
        'payment_method': 0,
        'products': items,
      },
    );

    final map = response as Map<String, dynamic>;
    return int.tryParse(map['order_id']?.toString() ?? map['id']?.toString() ?? '0') ?? 0;
  }
}

