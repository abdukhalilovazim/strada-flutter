import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:injectable/injectable.dart';
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
  final GraphQLClient _client;

  OrderRemoteDataSourceImpl(this._client);

  @override
  Future<List<OrderModel>> getOrders() async {
    const String query = r'''
      query Orders {
        orders {
          order_id
          address
          comment
          status
          status_text
          payment_url
          type
          branch
          latitude
          longitude
          payment_method_text
          payment_method
          subtotal_price
          discount_amount
          delivery_price
          total_price
          products {
            slug
            title
            image
            variant
            price
            quantity
            total_amount
          }
        }
      }
    ''';
    final result = await _client.query(QueryOptions(
      document: gql(query),
      operationName: 'Orders',
    ));
    if (result.hasException) throw result.exception!;
    return (result.data?['orders'] as List).map((e) => OrderModel.fromJson(e)).toList();
  }

  @override
  Future<OrderModel> getOrder(int id) async {
    const String query = r'''
      query Order($id: Int!) {
        order(id: $id) {
          order_id
          address
          comment
          status
          status_text
          payment_url
          type
          branch
          latitude
          longitude
          payment_method_text
          payment_method
          subtotal_price
          discount_amount
          delivery_price
          total_price
          products {
            slug
            title
            image
            variant
            price
            quantity
            total_amount
          }
        }
      }
    ''';
    final result = await _client.query(QueryOptions(
      document: gql(query),
      variables: {'id': id},
      operationName: 'Order',
    ));
    if (result.hasException) throw result.exception!;
    return OrderModel.fromJson(result.data?['order']);
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
    const String mutation = r'''
      mutation createOrder($full_name: String!, $phone: String!, $address: String!, $branch_id: String!, $is_delivery: Boolean!, $items: [OrderItemInput!]!) {
        createOrder(full_name: $full_name, phone: $phone, address: $address, branch_id: $branch_id, is_delivery: $is_delivery, items: $items)
      }
    ''';
    final result = await _client.mutate(MutationOptions(
      document: gql(mutation),
      variables: {
        'full_name': fullName,
        'phone': phone,
        'address': address,
        'branch_id': branchId,
        'is_delivery': isDelivery,
        'items': items,
      },
      operationName: 'createOrder',
    ));
    if (result.hasException) throw result.exception!;
    return result.data?['createOrder'] as int;
  }
}
