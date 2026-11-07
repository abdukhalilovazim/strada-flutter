import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pizza_strada/features/notifications/domain/entities/notification_entity.dart';
import 'package:pizza_strada/features/notifications/domain/repositories/notification_repository.dart';
import 'package:pizza_strada/features/notifications/domain/usecases/notification_usecases.dart';
import 'package:pizza_strada/features/notifications/presentation/bloc/notifications_cubit.dart';

class MockNotificationRepo implements NotificationRepository {
  List<NotificationEntity> list;
  MockNotificationRepo(this.list);

  @override
  Future<List<NotificationEntity>> getNotifications() async => list;
  @override
  Future<void> markAllRead(List<String> ids) async {}
  @override
  Future<void> markRead(String id) async {}
}

void main() {
  testWidgets('Notification bell shows red dot only when unreadCount > 0', (tester) async {
    final repo = MockNotificationRepo([
      NotificationEntity(
        id: '1',
        title: 'Title',
        body: 'Body',
        type: NotificationType.system,
        icon: 'pizza',
        createdAt: DateTime.now(),
        isRead: false,
      ),
    ]);

    final cubit = NotificationsCubit(
      GetNotificationsUseCase(repo),
      MarkAllNotificationsReadUseCase(repo),
      MarkNotificationReadUseCase(repo),
      repo.list,
    );

    Widget buildTestWidget() {
      return BlocProvider<NotificationsCubit>.value(
        value: cubit,
        child: MaterialApp(
          home: Scaffold(
            appBar: AppBar(
              actions: [
                BlocBuilder<NotificationsCubit, NotificationsState>(
                  builder: (context, notifState) {
                    final unreadCount = (notifState is NotificationsLoaded)
                        ? notifState.unreadCount
                        : 0;

                    return Stack(
                      key: const Key('notif_icon_stack'),
                      children: [
                        const Icon(Icons.notifications_none_rounded),
                        if (unreadCount > 0)
                          const Positioned(
                            key: Key('notif_unread_badge'),
                            child: SizedBox(width: 8, height: 8),
                          ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      );
    }

    // 1. Initial unread item -> Badge is present
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('notif_unread_badge')), findsOneWidget);

    // 2. Mark as read -> Badge disappears
    await cubit.markAllAsRead();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('notif_unread_badge')), findsNothing);
  });
}
