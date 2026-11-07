import 'package:injectable/injectable.dart';
import '../entities/notification_entity.dart';
import '../repositories/notification_repository.dart';

@lazySingleton
class GetNotificationsUseCase {
  final NotificationRepository _repository;

  GetNotificationsUseCase(this._repository);

  Future<List<NotificationEntity>> call() => _repository.getNotifications();
}

@lazySingleton
class MarkAllNotificationsReadUseCase {
  final NotificationRepository _repository;

  MarkAllNotificationsReadUseCase(this._repository);

  Future<void> call(List<String> ids) => _repository.markAllRead(ids);
}

@lazySingleton
class MarkNotificationReadUseCase {
  final NotificationRepository _repository;

  MarkNotificationReadUseCase(this._repository);

  Future<void> call(String id) => _repository.markRead(id);
}

