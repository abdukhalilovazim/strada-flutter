import 'package:equatable/equatable.dart';

enum NotificationType {
  system(1),
  promo(2),
  order(3);

  final int value;
  const NotificationType(this.value);

  static NotificationType fromValue(dynamic val) {
    if (val == null) return NotificationType.system;
    if (val is int) {
      return NotificationType.values.firstWhere(
        (e) => e.value == val,
        orElse: () => NotificationType.system,
      );
    }
    final str = val.toString().toLowerCase();
    if (str == '2' || str == 'promo') return NotificationType.promo;
    if (str == '3' || str == 'order') return NotificationType.order;
    return NotificationType.system;
  }

  bool get isPromo => this == NotificationType.promo;
  bool get isOrder => this == NotificationType.order;
  bool get isSystem => this == NotificationType.system;
}

class NotificationEntity extends Equatable {
  final String id;
  final String title;
  final String body;
  final NotificationType type;
  final String icon; // 'pizza' | 'promo' | 'coupon' | 'order' | 'bell'
  final String? image;
  final String? route;
  final String? actionLabel;
  final DateTime createdAt;
  final bool isRead;

  const NotificationEntity({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.icon,
    this.image,
    this.route,
    this.actionLabel,
    required this.createdAt,
    this.isRead = false,
  });

  NotificationEntity copyWith({
    String? id,
    String? title,
    String? body,
    NotificationType? type,
    String? icon,
    String? image,
    String? route,
    String? actionLabel,
    DateTime? createdAt,
    bool? isRead,
  }) {
    return NotificationEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      icon: icon ?? this.icon,
      image: image ?? this.image,
      route: route ?? this.route,
      actionLabel: actionLabel ?? this.actionLabel,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        body,
        type,
        icon,
        image,
        route,
        actionLabel,
        createdAt,
        isRead,
      ];
}
