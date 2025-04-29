import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class NotificationService {
  static final _firebaseMessaging = FirebaseMessaging.instance;

  static Future<void> init() async {
    // 1. Solicitar permisos (especialmente necesario en iOS)
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('✅ Permiso concedido para notificaciones');

      // 2. Obtener el FCM Token
      String? token = await _firebaseMessaging.getToken();
      debugPrint('📱 FCM Token obtenido: $token');

      // (Opcional) Aquí puedes enviar el token a tu backend o Firestore si quieres
    } else {
      debugPrint('⚠️ El usuario no concedió permisos de notificación');
    }

    // 3. Escuchar notificaciones en primer plano (foreground)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('📩 Notificación recibida en primer plano:');
      debugPrint('🔔 Título: ${message.notification?.title}');
      debugPrint('📝 Cuerpo: ${message.notification?.body}');
    });
  }

  /// Guarda el FCM token en tu backend
  static Future<void> saveFcmToken() async {
    try {
      final firebaseUser = FirebaseAuth.instance.currentUser;

      if (firebaseUser == null) {
        print('Usuario no autenticado. No se puede enviar el token.');
        return;
      }

      // Obtener el token FCM
      final fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken == null) {
        print('No se pudo obtener el token FCM.');
        return;
      }

      // Obtener el ID Token de Firebase para autenticación
      final idToken = await firebaseUser.getIdToken();

      // Hacer POST al backend
      final response = await http.post(
        Uri.parse('https://paints-api.reachu.io/auth/save-token'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: jsonEncode({'token': fcmToken}),
      );

      if (response.statusCode == 200) {
        print('✅ Token FCM guardado exitosamente en backend.');
      } else {
        print('⚠️ Error al guardar el token FCM: ${response.statusCode}');
        print('Response body: ${response.body}');
      }
    } catch (e) {
      print('⚠️ Excepción al guardar token FCM: $e');
    }
  }

  /// Escucha cambios de token (ej. si el usuario reinstala la app)
  static void listenForTokenRefresh() {
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      print('🔄 Token FCM actualizado automáticamente: $newToken');
      await saveFcmToken(); // vuelve a enviar el nuevo token
    });
  }
}
