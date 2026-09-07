import 'package:injectable/injectable.dart';
import 'package:pizza_strada/core/network/api_client.dart';
import 'package:pizza_strada/features/orders/data/models/order_model.dart';

abstract class OrderRemoteDataSource {
  Future<List<OrderModel>> getOrders();
  Future<Map<String, dynamic>> createOrder(Map<String, dynamic> params);
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
  Future<Map<String, dynamic>> createOrder(Map<String, dynamic> params) async {
    final response = await _client.post('orders', body: params);
    return response as Map<String, dynamic>;
  }
}

