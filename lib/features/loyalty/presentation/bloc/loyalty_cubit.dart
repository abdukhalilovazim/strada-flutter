import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:pizza_strada/core/network/graphql_client.dart';
import 'package:pizza_strada/features/loyalty/domain/entities/user_loyalty_entity.dart';
import 'package:pizza_strada/features/loyalty/data/models/user_loyalty_model.dart';
import 'package:pizza_strada/core/storage/secure_storage.dart';

part 'loyalty_state.dart';

@lazySingleton
class LoyaltyCubit extends Cubit<LoyaltyState> {
  LoyaltyCubit() : super(LoyaltyInitial());

  Future<void> init() async {
    final token = await SecureStorage.getToken();
    if (token == null) {
      emit(const LoyaltyFailure('Unauthenticated'));
      return;
    }

    emit(LoyaltyLoading());

    try {
      const String query = r'''
        query getLoyalty {
          me {
            loyalty {
              points
              total_orders
              last_order_date
              expiring_points
              expiry_date
            }
          }
        }
      ''';

      final client = buildGraphQLClient();
      final result = await client.query(QueryOptions(
        document: gql(query),
        fetchPolicy: FetchPolicy.networkOnly,
      ));

      if (result.hasException) {
        throw result.exception!;
      }

      final loyaltyJson = result.data?['me']?['loyalty'];
      if (loyaltyJson != null) {
        final entity = UserLoyaltyModel.fromJson(loyaltyJson as Map<String, dynamic>);
        emit(LoyaltyLoaded(entity));
      } else {
        emit(const LoyaltyFailure('Loyalty data not found'));
      }
    } catch (e) {
      emit(LoyaltyFailure(e.toString()));
    }
  }
}
