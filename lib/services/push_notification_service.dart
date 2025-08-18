// lib/services/push_notification_service.dart

import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:miniature_paint_finder/services/api_service.dart';
import 'package:miniature_paint_finder/services/auth_service.dart';
import 'package:miniature_paint_finder/main.dart'; // ← para navigatorKey

/// Top‐level function for handling notification taps in foreground
@pragma('vm:entry-point')
void onNotificationTap(NotificationResponse resp) {
  if (resp.payload != null) {
    final data = jsonDecode(resp.payload!);
    final route = data['targetRoute'] ?? data['route'] ?? '/';
    final args = data['screenArgs'];
    navigatorKey.currentState?.pushNamed(route, arguments: args);
  }
}

/// Top‐level function for handling notification taps when app is in background
@pragma('vm:entry-point')
void onNotificationTapBackground(NotificationResponse resp) {
  onNotificationTap(resp);
}

/// Top-level background message handler
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

class PushNotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _fln =
      FlutterLocalNotificationsPlugin();
  final ApiService _api;
  final IAuthService _auth;

  PushNotificationService({
    required ApiService apiService,
    required IAuthService authService,
  }) : _api = apiService,
       _auth = authService;

  static const AndroidNotificationChannel _androidChannel =
      AndroidNotificationChannel(
        'high_importance_channel',
        'High Importance Notifications',
        description: 'This channel is used for important notifications.',
        importance: Importance.high,
        playSound: true,
      );

  Future<void> init() async {
    // 1. Ensure Firebase is initialized (idempotent)
    await Firebase.initializeApp();

    // 2. Request iOS permissions (Android granted at install)
    await _fcm.requestPermission(alert: true, badge: true, sound: true);

    // 4. Create the Android notification channel
    await _fln
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_androidChannel);

    // 5. Initialize the plugin for both platforms, using top‐level callbacks
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinInit = DarwinInitializationSettings();
    await _fln.initialize(
      const InitializationSettings(android: androidInit, iOS: darwinInit),
      onDidReceiveNotificationResponse: onNotificationTap,
      onDidReceiveBackgroundNotificationResponse: onNotificationTapBackground,
    );

    // 6. Grab the FCM token
    final token = await _fcm.getToken();

    // 7. Register your token with backend
    final user = _auth.currentUser;
    if (token != null && user != null) {
      try {
        await _api.post('/notifications/register-token', {
          'userId': user.id,
          'token': token,
        });
      } catch (e) {}
    }

    // 8. Show a native notification for foreground FCM messages
    FirebaseMessaging.onMessage.listen((RemoteMessage msg) {
      final n = msg.notification;
      if (n == null || n.android == null) return;

      final payload = jsonEncode(
        msg.data.isNotEmpty ? msg.data : {'route': '/'},
      );

      _fln.show(
        n.hashCode,
        n.title,
        n.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _androidChannel.id,
            _androidChannel.name,
            channelDescription: _androidChannel.description,
            importance: Importance.high,
            priority: Priority.high,
            playSound: true,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        payload: payload, // ← añadimos payload
      );
    });

    // 9. Log taps on notifications when app is opened via them
    FirebaseMessaging.onMessageOpenedApp.listen((msg) {
      _handleRemoteMessage(msg); // ← navegamos
    });

    // 10. Handle cold start (app launched via notification)
    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) {
      _handleRemoteMessage(initial);
    }
  }

  // Nuevo método privado para procesar msg.data y navegar
  void _handleRemoteMessage(RemoteMessage msg) {
    final data = msg.data.isNotEmpty ? msg.data : {'route': '/'};
    final route = data['targetRoute'] ?? data['route'] ?? '/';
    final args = data['screenArgs'];
    navigatorKey.currentState?.pushNamed(route, arguments: args);
  }
}
