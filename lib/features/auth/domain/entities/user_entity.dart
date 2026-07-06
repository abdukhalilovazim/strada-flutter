import 'package:pizza_strada/features/loyalty/domain/entities/user_loyalty_entity.dart';

class UserEntity {
  final int    id;
  final String fullName;
  final String phone;
  final String token;
  final UserLoyaltyEntity? loyalty;

  const UserEntity({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.token,
    this.loyalty,
  });
}
