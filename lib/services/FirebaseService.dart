import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class FirebaseService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  static Future<String?> getFcmToken() async {
    try {
      // Request permission (only for iOS)
      await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      // Get token
      final token = await _firebaseMessaging.getToken();
      return token;
    } catch (e) {
      print('Error getting FCM token: $e');
      return null;
    }
  }

  static Future<void> setupFcm(BuildContext context) async {
    // Get initial token
    final token = await getFcmToken();
    if (token != null) {
      // Store in provider
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      authProvider.setFcmToken(token);

      // Update on server if user is logged in
      if (authProvider.user != null) {
        await authProvider.updateFcmTokenOnServer(token);
      }
    }

    // Listen for token refresh
    _firebaseMessaging.onTokenRefresh.listen((newToken) async {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      authProvider.setFcmToken(newToken);

      if (authProvider.user != null) {
        await authProvider.updateFcmTokenOnServer(newToken);
      }
    });

    // Handle background messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Got a message whilst in the foreground!');
      print('Message data: ${message.data}');

      if (message.notification != null) {
        print('Message also contained a notification: ${message.notification}');
      }
    });
  }
}