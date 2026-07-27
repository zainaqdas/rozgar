import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'supabase_service.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('FCM background: ${message.notification?.title}');
}

class PushService {
  PushService._();
  static final PushService instance = PushService._();

  FirebaseMessaging? _messaging;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  bool get isInitialized => _initialized;

  Future<void> initialize() async {
    if (_initialized) return;
    // Firebase is not configured for web (no FirebaseOptions in web/index.html).
    // Skip push init on web to avoid the "FirebaseOptions cannot be null" assertion.
    if (kIsWeb) {
      debugPrint('PushService: skipping init on web (Firebase not configured)');
      return;
    }
    try {
      await Firebase.initializeApp();
      _messaging = FirebaseMessaging.instance;

      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      await _messaging!.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );
      await _localNotifications.initialize(
        const InitializationSettings(android: androidSettings, iOS: iosSettings),
        onDidReceiveNotificationResponse: _onNotificationTap,
      );

      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      final token = await _messaging!.getToken();
      if (token != null) {
        await _registerToken(token);
      }

      _messaging!.onTokenRefresh.listen((newToken) {
        _registerToken(newToken);
      });

      _initialized = true;
      debugPrint('PushService initialized');
    } catch (e) {
      debugPrint('PushService init failed (Firebase not configured?): $e');
    }
  }

  Future<void> _registerToken(String token) async {
    try {
      await SupabaseService.instance.saveDeviceToken(token, _platform());
    } catch (e) {
      debugPrint('Failed to register device token: $e');
    }
  }

  String _platform() {
    if (kIsWeb) return 'web';
    if (defaultTargetPlatform == TargetPlatform.iOS) return 'ios';
    return 'android';
  }

  void _handleForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'rozgar_channel',
          'Rozgar Notifications',
          channelDescription: 'Job updates, messages, and hiring notifications',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: message.data['type'],
    );
  }

  void _onNotificationTap(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging?.unsubscribeFromTopic(topic);
    } catch (e) {
      debugPrint('Topic unsubscribe failed: $e');
    }
  }
}
