import 'package:flutter/material.dart';
import '../screens/SnapchatLoginScreen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/dashboard/SplashScreen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../component/test.dart';

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    // These parameters need to be passed from main.dart
    // We'll use a different approach - see below
    final args = settings.arguments;

    switch (settings.name) {
      case '/':
      // Check if arguments contain our notification data
        if (args is Map<String, dynamic>) {
          final initialData = args['initialNotificationData'] as Map<String, dynamic>?;
          final isFromNotification = args['isFromNotification'] as bool? ?? false;

          return MaterialPageRoute(
            builder: (_) => SplashScreen(
              initialNotificationData: initialData,
              isFromNotification: isFromNotification,
            ),
          );
        }
        // Default splash without notification data
        return MaterialPageRoute(
          builder: (_) => const SplashScreen(
            initialNotificationData: null,
            isFromNotification: false,
          ),
        );

      case '/login':
        return MaterialPageRoute(builder: (_) => SnapchatLoginScreen());

      case '/register':
        return MaterialPageRoute(builder: (_) => RegisterScreen());

      case '/dashboard':
        return MaterialPageRoute(builder: (_) => const DashboardScreen());

      case '/test':
        final firedAt = settings.arguments as String?;
        return MaterialPageRoute(
          builder: (_) => TestScreen(firedAt: firedAt),
        );

      default:
        return MaterialPageRoute(
          builder: (_) => const SplashScreen(
            initialNotificationData: null,
            isFromNotification: false,
          ),
        );
    }
  }
}