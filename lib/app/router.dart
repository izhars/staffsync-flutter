import 'package:flutter/material.dart';
import '../screens/snapchat_login_screen.dart';
import '../screens/splash_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/policy_screen.dart';

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    final args = settings.arguments;

    switch (settings.name) {
      case '/':
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
        return MaterialPageRoute(
          builder: (_) => const SplashScreen(
            initialNotificationData: null,
            isFromNotification: false,
          ),
        );

      case '/login':
        return MaterialPageRoute(builder: (_) => SnapchatLoginScreen());

      case '/dashboard':
        return MaterialPageRoute(builder: (_) => const DashboardScreen());

      case '/policies':
        return MaterialPageRoute(builder: (_) => const PolicyScreen());

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