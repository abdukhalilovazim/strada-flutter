import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:injectable/injectable.dart';
import 'package:pizza_strada/features/orders/data/models/order_model.dart';

abstract class OrderRemoteDataSource {
  Future<List<OrderModel>> getOrders();
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
      query orders {
        orders {
          number
          status
          total
          date
          products {
            quantity
            price
            product {
              slug
              title
              thumbnail
              photo
            }
            variant {
              id
              title
              price
            }
          }
        }
      }
    ''';
    final result = await _client.query(QueryOptions(
      document: gql(query),
      operationName: 'orders', // Used by SplitLink for ORDER API
    ));
    if (result.hasException) throw result.exception!;
    return (result.data?['orders'] as List).map((e) => OrderModel.fromJson(e)).toList();
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
