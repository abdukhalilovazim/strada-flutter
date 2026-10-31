import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:pizza_strada/core/network/api_client.dart';

part 'loyalty_state.dart';

@lazySingleton
class LoyaltyCubit extends Cubit<LoyaltyState> {
  LoyaltyCubit({ApiClient? apiClient}) : super(LoyaltyInitial());

  Future<void> init() async {
    // Disabled: loyalty feature and API requests removed
  }
}

