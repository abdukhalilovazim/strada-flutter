import 'package:equatable/equatable.dart';

class UserLoyaltyEntity extends Equatable {
  final int points;
  final int totalOrders;
  final DateTime? lastOrderDate;
  final int? expiringPoints;
  final DateTime? expiryDate;

  const UserLoyaltyEntity({
    required this.points,
    required this.totalOrders,
    this.lastOrderDate,
    this.expiringPoints,
    this.expiryDate,
  });

  @override
  List<Object?> get props => [
        points,
        totalOrders,
        lastOrderDate,
        expiringPoints,
        expiryDate,
      ];
}
