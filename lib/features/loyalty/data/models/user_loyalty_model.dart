import 'package:pizza_strada/features/loyalty/domain/entities/user_loyalty_entity.dart';

class UserLoyaltyModel extends UserLoyaltyEntity {
  const UserLoyaltyModel({
    required super.points,
    required super.totalOrders,
    super.lastOrderDate,
    super.expiringPoints,
    super.expiryDate,
  });

  factory UserLoyaltyModel.fromJson(Map<String, dynamic> json) {
    final expAt = json['expiringAt'] ?? json['expiry_date'];
    return UserLoyaltyModel(
      points: json['points'] as int? ?? 0,
      totalOrders: json['total_orders'] as int? ?? 0,
      lastOrderDate: json['last_order_date'] != null
          ? DateTime.tryParse(json['last_order_date'] as String)
          : null,
      expiringPoints: (json['expiringPoints'] ?? json['expiring_points']) as int?,
      expiryDate: expAt != null
          ? DateTime.tryParse(expAt as String)
          : null,
    );
  }
}

