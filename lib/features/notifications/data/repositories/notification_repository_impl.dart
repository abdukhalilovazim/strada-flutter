import 'package:easy_localization/easy_localization.dart';
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

    if (list.isEmpty) {
      list = _getDefaultFallbackNotifications();
    }

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

  List<NotificationEntity> _getDefaultFallbackNotifications() {
    return [
      NotificationEntity(
        id: '1',
        title: 'notifications.item_welcome_title'.tr(),
        body: 'notifications.item_welcome_body'.tr(),
        type: NotificationType.system,
        icon: 'pizza',
        route: '/home',
        actionLabel: 'notifications.item_welcome_action'.tr(),
        createdAt: DateTime.now().subtract(const Duration(minutes: 25)),
      ),
      NotificationEntity(
        id: '2',
        title: 'notifications.item_promo_2plus1_title'.tr(),
        body: 'notifications.item_promo_2plus1_body'.tr(),
        type: NotificationType.promo,
        icon: 'promo',
        route: '/promotions',
        actionLabel: 'notifications.item_promo_2plus1_action'.tr(),
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      NotificationEntity(
        id: '3',
        title: 'notifications.item_promo_strada20_title'.tr(),
        body: 'notifications.item_promo_strada20_body'.tr(),
        type: NotificationType.promo,
        icon: 'coupon',
        route: '/promotions',
        actionLabel: 'notifications.item_promo_strada20_action'.tr(),
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      NotificationEntity(
        id: '4',
        title: 'notifications.item_order_delivery_title'.tr(),
        body: 'notifications.item_order_delivery_body'.tr(),
        type: NotificationType.order,
        icon: 'order',
        route: '/home',
        actionLabel: 'notifications.item_order_delivery_action'.tr(),
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
    ];
  }
}
