import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pizza_strada/core/extensions/string_extensions.dart';
import 'package:pizza_strada/core/theme/app_theme.dart';
import 'package:pizza_strada/features/notifications/domain/entities/notification_entity.dart';
import 'package:pizza_strada/features/notifications/domain/repositories/notification_repository.dart';
import 'package:pizza_strada/features/notifications/domain/usecases/notification_usecases.dart';
import 'package:pizza_strada/features/notifications/presentation/bloc/notifications_cubit.dart';
import 'package:pizza_strada/features/notifications/presentation/pages/notifications_page.dart';

class MockNotificationRepository implements NotificationRepository {
  List<NotificationEntity> notifications = [
    NotificationEntity(
      id: '1',
      title: 'notifications.item_welcome_title'.trOr('Xush kelibsiz!'),
      body: 'notifications.item_welcome_body'.trOr('Strada Pizza ilovasiga xush kelibsiz!'),
      type: NotificationType.system,
      icon: 'pizza',
      route: '/home',
      actionLabel: 'notifications.item_welcome_action'.trOr('Pitsalarni ko\'rish'),
      createdAt: DateTime.now().subtract(const Duration(minutes: 10)),
      isRead: false,
    ),
    NotificationEntity(
      id: '2',
      title: 'notifications.item_promo_2plus1_title'.trOr('Aksiya: 2+1 pitsa bepul!'),
      body: 'notifications.item_promo_2plus1_body'.trOr('Har 2 ta katta pitsa buyurtma qilganingizda...'),
      type: NotificationType.promo,
      icon: 'promo',
      route: '/promotions',
      actionLabel: 'notifications.item_promo_2plus1_action'.trOr('Aksiyaga o\'tish'),
      createdAt: DateTime.now().subtract(const Duration(hours: 1)),
      isRead: false,
    ),
  ];

  @override
  Future<List<NotificationEntity>> getNotifications() async => notifications;

  @override
  Future<void> markAllRead(List<String> ids) async {
    notifications = notifications.map((n) => n.copyWith(isRead: true)).toList();
  }

  @override
  Future<void> markRead(String id) async {
    notifications = notifications.map((n) {
      if (n.id == id) return n.copyWith(isRead: true);
      return n;
    }).toList();
  }
}

void main() {
  late MockNotificationRepository mockRepo;
  late NotificationsCubit cubit;

  setUp(() {
    mockRepo = MockNotificationRepository();
    cubit = NotificationsCubit(
      GetNotificationsUseCase(mockRepo),
      MarkAllNotificationsReadUseCase(mockRepo),
      MarkNotificationReadUseCase(mockRepo),
      mockRepo.notifications,
    );
  });

  testWidgets('Tapping notification card opens detail bottom sheet with full details',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: NotificationsPage(cubit: cubit),
      ),
    );

    await tester.pumpAndSettle();

    // Verify notification card is present via localized title or fallback
    final cardFinder = find.text('notifications.item_welcome_title'.trOr('Xush kelibsiz!'));
    expect(cardFinder, findsOneWidget);

    // Tap on the first notification card
    await tester.tap(cardFinder);
    await tester.pumpAndSettle();

    // Verify detail sheet is displayed with action button and close button
    expect(find.text('notifications.item_welcome_action'.trOr('Pitsalarni ko\'rish')), findsOneWidget);
    expect(find.text('common.close'.trOr('Yopish')), findsOneWidget);

    // Tap close button
    await tester.tap(find.text('common.close'.trOr('Yopish')));
    await tester.pumpAndSettle();

    // Verify sheet is closed
    expect(find.text('common.close'.trOr('Yopish')), findsNothing);
  });

  testWidgets('Mark all as read updates all notifications to read status',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: NotificationsPage(cubit: cubit),
      ),
    );

    await tester.pumpAndSettle();

    // Unread count should initially be 2, so the mark all read icon is visible
    final markAllBtnFinder = find.byTooltip('notifications.mark_all_read'.trOr('Hammasini o\'qish'));
    expect(markAllBtnFinder, findsOneWidget);

    // Tap mark all read
    await tester.tap(markAllBtnFinder);
    await tester.pumpAndSettle();

    // After marking all as read, unread count becomes 0 and mark all read button disappears
    expect(find.byTooltip('notifications.mark_all_read'.trOr('Hammasini o\'qish')), findsNothing);

    // Verify read status badges are displayed on the cards
    expect(find.text('notifications.read_status'.trOr('O\'qilgan')), findsNWidgets(2));
  });
}
