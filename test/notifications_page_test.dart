import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pizza_strada/core/theme/app_theme.dart';
import 'package:pizza_strada/features/notifications/domain/entities/notification_entity.dart';
import 'package:pizza_strada/features/notifications/domain/repositories/notification_repository.dart';
import 'package:pizza_strada/features/notifications/domain/usecases/notification_usecases.dart';
import 'package:pizza_strada/features/notifications/presentation/bloc/notifications_cubit.dart';
import 'package:pizza_strada/features/notifications/presentation/pages/notifications_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class InMemoryAssetLoader extends AssetLoader {
  const InMemoryAssetLoader();

  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async {
    return const {
      "notifications.title": "Bildirishnomalar",
      "notifications.mark_all_read": "Hammasini o'qish",
      "notifications.all_read": "Barchasi o'qilgan",
      "notifications.read_status": "O'qilgan",
      "notifications.all_read_success": "Barcha bildirishnomalar o'qilgan deb belgilandi",
      "notifications.filter_all": "Barchasi",
      "notifications.filter_promos": "Aksiyalar",
      "notifications.filter_orders": "Buyurtmalar",
      "notifications.type_promo": "Aksiya",
      "notifications.type_order": "Buyurtma",
      "notifications.type_system": "Tizim xabari",
      "notifications.empty_title": "Hozircha bildirishnomalar yo'q",
      "notifications.empty_desc": "Yangi aksiyalar, maxsus takliflar va buyurtmangiz holati shu yerda aks etadi.",
      "notifications.go_to_menu": "Menyuga qaytish",
      "common.close": "Yopish",
      "common.view": "Ko'rish",
    };
  }
}

class MockNotificationRepository implements NotificationRepository {
  List<NotificationEntity> notifications = [
    NotificationEntity(
      id: '1',
      title: 'Xush kelibsiz! 🍕',
      body: 'Strada Pizza ilovasiga xush kelibsiz!',
      type: NotificationType.system,
      icon: 'pizza',
      route: '/home',
      actionLabel: 'Pitsalarni ko\'rish',
      createdAt: DateTime.now().subtract(const Duration(minutes: 10)),
      isRead: false,
    ),
    NotificationEntity(
      id: '2',
      title: 'Aksiya: 2+1 pitsa bepul! 🎁',
      body: 'Har 2 ta katta pitsa buyurtma qilganingizda...',
      type: NotificationType.promo,
      icon: 'promo',
      route: '/promotions',
      actionLabel: 'Aksiyaga o\'tish',
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

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  setUp(() {
    mockRepo = MockNotificationRepository();
    cubit = NotificationsCubit(
      GetNotificationsUseCase(mockRepo),
      MarkAllNotificationsReadUseCase(mockRepo),
      MarkNotificationReadUseCase(mockRepo),
      mockRepo.notifications,
    );
  });

  Widget buildTestableWidget() {
    return EasyLocalization(
      supportedLocales: const [Locale('uz'), Locale('ru'), Locale('en')],
      path: 'lib/l10n',
      assetLoader: const InMemoryAssetLoader(),
      fallbackLocale: const Locale('uz'),
      startLocale: const Locale('uz'),
      saveLocale: false,
      useOnlyLangCode: true,
      child: Builder(
        builder: (context) {
          return MaterialApp(
            localizationsDelegates: context.localizationDelegates,
            supportedLocales: context.supportedLocales,
            locale: context.locale,
            theme: AppTheme.light,
            home: NotificationsPage(cubit: cubit),
          );
        },
      ),
    );
  }

  testWidgets('Tapping notification card opens detail bottom sheet with full details',
      (WidgetTester tester) async {
    await tester.pumpWidget(buildTestableWidget());
    await tester.pumpAndSettle();

    // Verify notification card is present
    final cardFinder = find.text('Xush kelibsiz! 🍕');
    expect(cardFinder, findsOneWidget);

    // Tap on the first notification card
    await tester.tap(cardFinder);
    await tester.pumpAndSettle();

    // Verify detail sheet is displayed with action button and close button (using pure .tr())
    expect(find.text('Pitsalarni ko\'rish'), findsOneWidget);
    expect(find.text('common.close'.tr()), findsOneWidget);

    // Tap close button
    await tester.tap(find.text('common.close'.tr()));
    await tester.pumpAndSettle();

    // Verify sheet is closed
    expect(find.text('common.close'.tr()), findsNothing);
  });

  testWidgets('Mark all as read updates all notifications to read status',
      (WidgetTester tester) async {
    await tester.pumpWidget(buildTestableWidget());
    await tester.pumpAndSettle();

    // Unread count should initially be 2, so the mark all read icon is visible (using pure .tr())
    final markAllBtnFinder = find.byTooltip('notifications.mark_all_read'.tr());
    expect(markAllBtnFinder, findsOneWidget);

    // Tap mark all read
    await tester.tap(markAllBtnFinder);
    await tester.pumpAndSettle();

    // After marking all as read, unread count becomes 0 and mark all read button disappears
    expect(find.byTooltip('notifications.mark_all_read'.tr()), findsNothing);

    // Verify read status badges are displayed on the cards (using pure .tr())
    expect(find.text('notifications.read_status'.tr()), findsNWidgets(2));
  });
}
