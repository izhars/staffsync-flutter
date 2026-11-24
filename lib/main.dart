import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:staffsync/services/notification_service.dart';
import 'package:staffsync/utils/my_app_constants.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Firebase ──────────────────────────────────────────────────
  await Firebase.initializeApp();

  // ── Local notification channels + plugin ──────────────────────
  await NotificationService.initialize();

  // ── Background FCM entry point (registered ONCE, top-level fn). ─
  FirebaseMessaging.onBackgroundMessage(firebaseBackgroundMessageHandler);

  // ── Foreground / opened-app listeners + permission + token save. ──
  final notificationService = NotificationService();
  await notificationService.init();

  // ── Cold-start notification (consumed once by SplashScreen). ────
  final initialNotificationData =
  await notificationService.getInitialNotificationData();

  runApp(MyApp(
    initialNotificationData: initialNotificationData,
    isFromNotification: initialNotificationData != null,
  ));
}