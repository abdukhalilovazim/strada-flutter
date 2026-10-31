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
    final rawExpPoints = json['expiringPoints'] ?? json['expiring_points'];
    return UserLoyaltyModel(
      points: int.tryParse(json['points']?.toString() ?? '0') ?? 0,
      totalOrders: int.tryParse(json['total_orders']?.toString() ?? '0') ?? 0,
      lastOrderDate: json['last_order_date'] != null
          ? DateTime.tryParse(json['last_order_date'].toString())
          : null,
      expiringPoints: rawExpPoints != null ? int.tryParse(rawExpPoints.toString()) : null,
      expiryDate: expAt != null
          ? DateTime.tryParse(expAt.toString())
          : null,
    );
  }
}

