part of 'loyalty_cubit.dart';

abstract class LoyaltyState extends Equatable {
  const LoyaltyState();

  @override
  List<Object?> get props => [];
}

class LoyaltyInitial extends LoyaltyState {}

class LoyaltyLoading extends LoyaltyState {}

class LoyaltyLoaded extends LoyaltyState {
  final UserLoyaltyEntity loyalty;

  const LoyaltyLoaded(this.loyalty);

  @override
  List<Object?> get props => [loyalty];
}

class LoyaltyFailure extends LoyaltyState {
  final String message;

  const LoyaltyFailure(this.message);

  @override
  List<Object?> get props => [message];
}
