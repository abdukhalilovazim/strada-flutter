import '../entities/notification_entity.dart';

abstract class NotificationRepository {
  Future<List<NotificationEntity>> getNotifications();
  Future<void> markAllRead(List<String> ids);
  Future<void> markRead(String id);
}

