import 'package:injectable/injectable.dart';
import '../../../../core/network/api_client.dart';
import '../models/notification_model.dart';

abstract class NotificationRemoteDataSource {
  Future<List<NotificationModel>> getNotifications();
  Future<void> markAllRead(List<String> ids);
  Future<void> markRead(String id);
}

@LazySingleton(as: NotificationRemoteDataSource)
class NotificationRemoteDataSourceImpl implements NotificationRemoteDataSource {
  final ApiClient _client;

  NotificationRemoteDataSourceImpl([ApiClient? client]) : _client = client ?? ApiClient();

  @override
  Future<List<NotificationModel>> getNotifications() async {
    try {
      final response = await _client.get('notifications').timeout(const Duration(seconds: 4));
      final List items;
      if (response is List) {
        items = response;
      } else if (response is Map<String, dynamic> && response['data'] is List) {
        items = response['data'] as List;
      } else {
        items = const [];
      }
      return items
          .map((e) => NotificationModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<void> markAllRead(List<String> ids) async {
    try {
      await _client.post('notifications/read-all', body: {'ids': ids}).timeout(const Duration(seconds: 4));
    } catch (_) {
      // Best-effort remote update
    }
  }

  @override
  Future<void> markRead(String id) async {
    try {
      await _client.post('notifications/$id/read').timeout(const Duration(seconds: 4));
    } catch (_) {
      // Best-effort remote update
    }
  }
}
