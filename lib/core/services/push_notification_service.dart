import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:pizza_strada/core/di/injection.dart';
import 'package:pizza_strada/core/services/deep_link_service.dart';
import 'package:pizza_strada/core/storage/shared_prefs.dart';
import 'package:pizza_strada/features/notifications/presentation/bloc/notifications_cubit.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('🌙 [PushNotification] Background message: ${message.messageId} | data: ${message.data}');
}

class PushNotificationService {
  PushNotificationService._();
  static final PushNotificationService instance = PushNotificationService._();

  bool _isInitialized = false;

  /// Firebase va FCM push xabarnomalar xizmatini xavfsiz ishga tushirish
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      // 1. Firebase Core ishga tushirish
      try {
        await Firebase.initializeApp();
      } catch (e) {
        debugPrint('⚠️ [PushNotification] Firebase.initializeApp() skipped or error: $e');
      }

      // Agar Firebase muvaffaqiyatli ulangan bo'lsa
      if (Firebase.apps.isNotEmpty) {
        FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

        final messaging = FirebaseMessaging.instance;

        // 2. Xabarnoma ruxsatini so'rash
        final settings = await messaging.requestPermission(
          alert: true,
          badge: true,
          sound: true,
          provisional: false,
        );
        debugPrint('🔔 [PushNotification] Permission status: ${settings.authorizationStatus}');

        // 3. FCM tokenni olish va keshga saqlash
        try {
          final token = await messaging.getToken();
          if (token != null && token.isNotEmpty) {
            await SharedPrefs.saveFcmToken(token);
            debugPrint('🔑 [PushNotification] FCM Token saved: ${token.substring(0, token.length > 15 ? 15 : token.length)}...');
          }
        } catch (e) {
          debugPrint('⚠️ [PushNotification] getToken error: $e');
        }

        // 4. Token yangilanishini tinglash
        messaging.onTokenRefresh.listen((newToken) async {
          await SharedPrefs.saveFcmToken(newToken);
          debugPrint('🔄 [PushNotification] FCM Token refreshed');
        });

        // 5. Ilova butunlay yopiq (terminated) holatda bo'lganda xabarnomaga bosib ochish
        final initialMessage = await messaging.getInitialMessage();
        if (initialMessage != null) {
          debugPrint('🚀 [PushNotification] App launched from terminated state via notification: ${initialMessage.data}');
          _handleMessageClick(initialMessage);
        }

        // 6. Ilova orqa fonda (background) bo'lganda push bosilganda
        FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
          debugPrint('📲 [PushNotification] Notification opened from background: ${message.data}');
          _handleMessageClick(message);
        });

        // 7. Ilova ochiq (foreground) paytida xabarnoma kelganda
        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          debugPrint('🔔 [PushNotification] Foreground message received: ${message.notification?.title} | ${message.data}');
          _handleForegroundMessage(message);
        });

        _isInitialized = true;
      }
    } catch (e) {
      debugPrint('⚠️ [PushNotification] Init failed: $e');
    }
  }

  /// Push xabarnoma bosilganda kerakli sahifaga o'tish
  void _handleMessageClick(RemoteMessage message) {
    final data = Map<String, dynamic>.from(message.data);
    DeepLinkService.instance.handleNotificationData(data);
  }

  /// Ilova ochiq paytida bildirishnomalarni yangilash
  void _handleForegroundMessage(RemoteMessage message) {
    try {
      if (getIt.isRegistered<NotificationsCubit>()) {
        getIt<NotificationsCubit>().refresh();
      }
    } catch (_) {}
  }
}

