import '../../domain/entities/notification_entity.dart';

class NotificationModel extends NotificationEntity {
  const NotificationModel({
    required super.id,
    required super.title,
    required super.body,
    required super.type,
    required super.icon,
    super.image,
    super.route,
    super.actionLabel,
    required super.createdAt,
    super.isRead,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json, {bool isRead = false}) {
    DateTime parsedDate;
    try {
      parsedDate = json['created_at'] != null
          ? DateTime.parse(json['created_at'].toString())
          : DateTime.now();
    } catch (_) {
      parsedDate = DateTime.now();
    }

    return NotificationModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      type: NotificationType.fromValue(json['type']),
      icon: json['icon']?.toString() ?? 'bell',
      image: json['image']?.toString(),
      route: json['route']?.toString(),
      actionLabel: json['action_label']?.toString(),
      createdAt: parsedDate,
      isRead: isRead || (json['is_read'] == true),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'type': type.value,
      'icon': icon,
      'image': image,
      'route': route,
      'action_label': actionLabel,
      'created_at': createdAt.toIso8601String(),
      'is_read': isRead,
    };
  }
}
