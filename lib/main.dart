import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:staffsync/services/notification_service.dart';
import 'package:staffsync/utils/my_app_constants.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Firebase ──────────────────────────────────────────────────
  try {
    await Firebase.initializeApp();
    // ── Background FCM entry point (registered ONCE, top-level fn). ─
    FirebaseMessaging.onBackgroundMessage(firebaseBackgroundMessageHandler);
  } catch (e) {
    debugPrint('Firebase initialization warning: $e');
  }

  // ── Local notification channels + plugin ──────────────────────
  await NotificationService.initialize();

  // ── Foreground / opened-app listeners + permission + token save. ──
  final notificationService = NotificationService();
  try {
    await notificationService.init();
  } catch (e) {
    debugPrint('NotificationService init warning: $e');
  }

  // ── Cold-start notification (consumed once by SplashScreen). ────
  final initialNotificationData =
  await notificationService.getInitialNotificationData();

  runApp(MyApp(
    initialNotificationData: initialNotificationData,
    isFromNotification: initialNotificationData != null,
  ));
}