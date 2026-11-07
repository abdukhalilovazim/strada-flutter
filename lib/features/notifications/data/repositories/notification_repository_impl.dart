import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/notification_entity.dart';
import '../../domain/repositories/notification_repository.dart';
import '../datasources/notification_remote_datasource.dart';

@LazySingleton(as: NotificationRepository)
class NotificationRepositoryImpl implements NotificationRepository {
  final NotificationRemoteDataSource _remoteDataSource;
  static const _readIdsKey = 'read_notification_ids';

  NotificationRepositoryImpl(this._remoteDataSource);

  @override
  Future<List<NotificationEntity>> getNotifications() async {
    List<String> readIds = [];
    try {
      final prefs = await SharedPreferences.getInstance();
      readIds = prefs.getStringList(_readIdsKey) ?? [];
    } catch (_) {}

    List<NotificationEntity> list = const [];
    try {
      list = await _remoteDataSource.getNotifications();
    } catch (_) {}

    return list.map((item) {
      final isRead = item.isRead || readIds.contains(item.id);
      return item.copyWith(isRead: isRead);
    }).toList();
  }

  @override
  Future<void> markAllRead(List<String> ids) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existing = prefs.getStringList(_readIdsKey) ?? [];
      final updated = {...existing, ...ids}.toList();
      await prefs.setStringList(_readIdsKey, updated);
    } catch (_) {}

    try {
      await _remoteDataSource.markAllRead(ids);
    } catch (_) {}
  }

  @override
  Future<void> markRead(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existing = prefs.getStringList(_readIdsKey) ?? [];
      if (!existing.contains(id)) {
        existing.add(id);
        await prefs.setStringList(_readIdsKey, existing);
      }
    } catch (_) {}

    try {
      await _remoteDataSource.markRead(id);
    } catch (_) {}
  }
}
