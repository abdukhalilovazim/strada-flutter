class UserEntity {
  final int    id;
  final String fullName;
  final String phone;
  final String token;
  final String? birthdate;

  const UserEntity({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.token,
    this.birthdate,
  });
}
