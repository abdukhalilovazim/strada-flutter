import 'package:pizza_strada/features/auth/domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.fullName,
    required super.phone,
    required super.token,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    id:       json['id']        as int,
    fullName: json['full_name'] as String,
    phone:    json['phone']     as String,
    token:    json['token']     as String? ?? '',
  );
}
