import 'package:pizza_strada/features/auth/domain/entities/user_entity.dart';
import 'package:pizza_strada/features/loyalty/data/models/user_loyalty_model.dart';

class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.fullName,
    required super.phone,
    required super.token,
    super.loyalty,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    id:       json['id']        as int,
    fullName: json['full_name'] as String,
    phone:    json['phone']     as String,
    token:    json['token']     as String? ?? '',
    loyalty:  json['loyalty'] != null 
                ? UserLoyaltyModel.fromJson(json['loyalty'] as Map<String, dynamic>) 
                : null,
  );
}
