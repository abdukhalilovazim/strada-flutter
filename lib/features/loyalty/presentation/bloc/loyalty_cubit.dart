import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:pizza_strada/core/network/api_client.dart';
import 'package:pizza_strada/features/loyalty/domain/entities/user_loyalty_entity.dart';
import 'package:pizza_strada/features/loyalty/data/models/user_loyalty_model.dart';
import 'package:pizza_strada/core/storage/secure_storage.dart';

part 'loyalty_state.dart';

@lazySingleton
class LoyaltyCubit extends Cubit<LoyaltyState> {
  final ApiClient _apiClient;

  LoyaltyCubit({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient(),
        super(LoyaltyInitial());

  Future<void> init() async {
    final token = await SecureStorage.getToken();
    if (token == null) {
      emit(const LoyaltyFailure('Unauthenticated'));
      return;
    }

    emit(LoyaltyLoading());

    try {
      final response = await _apiClient.get('loyalty/balance');
      if (response != null && response is Map<String, dynamic>) {
        final entity = UserLoyaltyModel.fromJson(response);
        emit(LoyaltyLoaded(entity));
      } else {
        emit(const LoyaltyFailure('Loyalty data not found'));
      }
    } catch (e) {
      emit(LoyaltyFailure(e.toString()));
    }
  }
}

