import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'api_service.dart';
import 'background_notification_service.dart';
import 'storage_service.dart';

/// FCM background isolate handler. Notification-type messages are shown
/// automatically by the system while the app is backgrounded/terminated, so
/// there's nothing to do here yet — but the handler must be registered.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {}

/// Wires Firebase Cloud Messaging: notification permission, the broadcast
/// topic, device-token registration with the backend, and foreground display.
/// Every call is guarded so a missing/unconfigured Firebase never breaks the app.
class PushNotificationService {
  PushNotificationService._();

  static final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  static const String _broadcastTopic = 'all';

  static Future<void> init() async {
    try {
      final settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      debugPrint('[Push] permission: ${settings.authorizationStatus}');

      // Every install listens on the broadcast topic for "send to all" pushes.
      await _fcm.subscribeToTopic(_broadcastTopic);

      // Register this device for per-user targeting (only when logged in).
      await registerToken();
      _fcm.onTokenRefresh.listen(_sendToken);

      // Foreground messages aren't shown automatically — render them ourselves.
      FirebaseMessaging.onMessage.listen(_onForegroundMessage);

      // Taps that opened the app from a notification.
      FirebaseMessaging.onMessageOpenedApp.listen(_onMessageOpened);
      final initial = await _fcm.getInitialMessage();
      if (initial != null) _onMessageOpened(initial);
    } catch (e) {
      debugPrint('[Push] init skipped: $e');
    }
  }

  /// Send the current FCM token to the backend. No-op if not logged in.
  static Future<void> registerToken() async {
    try {
      final token = await _fcm.getToken();
      if (token != null) await _sendToken(token);
    } catch (e) {
      debugPrint('[Push] registerToken error: $e');
    }
  }

  static Future<void> _sendToken(String fcmToken) async {
    try {
      // The auth token lives in flutter_secure_storage (StorageService), NOT
      // SharedPreferences — read it from the same place the rest of the app does.
      final auth = await StorageService().getToken();
      if (auth == null || auth.isEmpty) return; // only for logged-in users
      await ApiService().post(
        '/device-token',
        token: auth,
        body: {'token': fcmToken, 'platform': 'android'},
      );
    } catch (e) {
      debugPrint('[Push] _sendToken error: $e');
    }
  }

  static void _onForegroundMessage(RemoteMessage message) {
    debugPrint('[Push] foreground message: ${message.notification?.title} / ${message.data}');
    final n = message.notification;
    final title = n?.title ?? (message.data['title'] as String?) ?? 'Study Zone';
    final body = n?.body ?? (message.data['message'] as String?) ?? '';
    if (title.isEmpty && body.isEmpty) return;
    BackgroundNotificationService.showLocalNotification(
      title: title,
      body: body,
      payload: message.data['action_url'] as String?,
    );
  }

  static void _onMessageOpened(RemoteMessage message) {
    // The app is already opening; the in-app notification list refreshes on
    // its own. (Deep-linking to action_url can be added later.)
    debugPrint('[Push] opened from notification: ${message.messageId}');
  }
}
