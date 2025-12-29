// main.dart (updated)
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:staffsync/providers/connectivity_provider.dart';
import 'package:staffsync/screens/dashboard/SplashScreen.dart';
import 'app/router.dart';
import 'app/theme.dart';
import 'providers/auth_provider.dart';
import 'services/notification_service.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Global variable to store initial notification
Map<String, dynamic>? _initialNotificationData;
bool _isFromNotification = false;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  debugPrint('🚀 ========== APP STARTING ==========');

  // Initialize Firebase FIRST
  await Firebase.initializeApp();
  debugPrint('✅ Firebase initialized');

  // Initialize notifications
  await NotificationService.init();
  debugPrint('✅ Notification service initialized');

  // GET INITIAL MESSAGE - This is CRITICAL for killed state
  try {
    debugPrint('🔄 Getting initial message...');
    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();

    if (initialMessage != null) {
      debugPrint('🎯 INITIAL MESSAGE FOUND: ${initialMessage.data}');
      debugPrint('🎯 Message ID: ${initialMessage.messageId}');
      debugPrint('🎯 Sent Time: ${initialMessage.sentTime}');

      _initialNotificationData = initialMessage.data;
      _isFromNotification = true;

      // Also save to shared preferences for backup
      // await _saveNotificationData(initialMessage.data);
    } else {
      debugPrint('📭 No initial message found');
      _isFromNotification = false;
    }
  } catch (e) {
    debugPrint('❌ Error getting initial message: $e');
  }

  // Setup foreground handler
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    debugPrint('📱 Foreground message received: ${message.messageId}');
    debugPrint('📱 Data: ${message.data}');

    // Show notification
    final title = message.notification?.title ?? message.data['title'] ?? 'Notification';
    final body = message.notification?.body ?? message.data['body'] ?? 'New message';

    NotificationService.show(
      title: title,
      body: body,
      data: message.data,
    );
  });

  // Handle when app is in background and notification is clicked
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    debugPrint('👆 App opened from background via notification');
    debugPrint('👆 Data: ${message.data}');

    // Use navigatorKey to navigate
    _handleNotificationNavigation(message.data);
  });

  // Request permissions
  await _requestNotificationPermissions();

  // Get token
  final token = await FirebaseMessaging.instance.getToken();
  debugPrint("🔥 FCM Token: $token");

  debugPrint('✅ Starting app with notification data: $_initialNotificationData');
  debugPrint('✅ Is from notification: $_isFromNotification');

  runApp(MyApp(
    initialNotificationData: _initialNotificationData,
    isFromNotification: _isFromNotification,
  ));
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint("📩 Handling background message: ${message.messageId}");

  final title = message.notification?.title ?? message.data['title'] ?? 'Notification';
  final body = message.notification?.body ?? message.data['body'] ?? '';
  final imageUrl = message.notification?.android?.imageUrl ??
      message.notification?.apple?.imageUrl ??
      message.data['imageUrl'];

  await NotificationService.show(
    title: title,
    body: body,
    imageUrl: imageUrl,
    data: message.data,
  );
}

void _handleNotificationNavigation(Map<String, dynamic> data) {
  final type = data['type'];

  switch (type) {
    case 'leave_update':
      final leaveId = data['leaveId'];
      final status = data['status'];
      if (leaveId != null) {
        debugPrint('Navigate to leave: $leaveId (status: $status)');
        // Example:
        navigatorKey.currentState?.pushNamed(
          '/leave-detail',
          arguments: leaveId,
        );
      }
      break;

    case 'attendance_reminder':
      navigatorKey.currentState?.pushNamed('/attendance');
      break;

    case 'test_notification':
      final firedAt = data['firedAt'] ?? '';
      debugPrint('📌 Test notification tapped! firedAt: $firedAt'); // 🔹 log
      navigatorKey.currentState?.pushNamed(
        '/test',
        arguments: firedAt, // pass timestamp to TestScreen
      );
      break;
    default:
      debugPrint('No navigation defined for type: $type');
  }
}


Future<void> _requestNotificationPermissions() async {
  final messaging = FirebaseMessaging.instance;

  // For iOS
  await messaging.requestPermission(
    alert: true,
    announcement: false,
    badge: true,
    carPlay: false,
    criticalAlert: false,
    provisional: false,
    sound: true,
  );

  // For Android 13+
  final NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    announcement: false,
    badge: true,
    carPlay: false,
    criticalAlert: false,
    provisional: false,
    sound: true,
  );

  debugPrint('Notification permission status: ${settings.authorizationStatus}');
}

class MyApp extends StatelessWidget {
  final Map<String, dynamic>? initialNotificationData;
  final bool isFromNotification;

  const MyApp({
    super.key,
    this.initialNotificationData,
    required this.isFromNotification,
  });

  @override
  Widget build(BuildContext context) {
    debugPrint('🎨 Building MyApp with data: $initialNotificationData');
    debugPrint('🎨 Is from notification: $isFromNotification');

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ConnectivityProvider()),
      ],
      child: MaterialApp(
        title: 'Employee Management',
        navigatorKey: navigatorKey,
        theme: appTheme,
        // Remove home and use initialRoute instead
        initialRoute: '/',
        onGenerateRoute: (settings) {
          // Handle the initial route specially
          if (settings.name == '/') {
            return MaterialPageRoute(
              builder: (_) => SplashScreen(
                initialNotificationData: initialNotificationData,
                isFromNotification: isFromNotification,
              ),
            );
          }
          // For other routes, use your existing router
          return AppRouter.generateRoute(settings);
        },
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}