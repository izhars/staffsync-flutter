// my_app.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:staffsync/app/router.dart';
import 'package:staffsync/app/theme.dart';
import 'package:staffsync/core/navigation.dart';
import 'package:staffsync/providers/auth_provider.dart';
import 'package:staffsync/providers/connectivity_provider.dart';
import 'package:staffsync/providers/theme_provider.dart';
import 'package:staffsync/screens/splash_screen.dart';
import 'package:staffsync/screens/call/call_screen.dart';
import 'package:staffsync/screens/call/incoming_call_screen.dart';
import 'package:staffsync/screens/dashboard/dashboard_screen.dart';
import '../component/connectivity_wrapper.dart';
import '../screens/AppLockGate.dart';
import '../widgets/route_observer.dart';

class MyAppConstants {
  static const String appTitle = 'StaffSync';
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
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ConnectivityProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: MyAppConstants.appTitle,
            navigatorKey: navigatorKey,
            navigatorObservers: [routeObserver],
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            initialRoute: '/',
            onGenerateRoute: _onGenerateRoute,
            debugShowCheckedModeBanner: false,
            builder: (context, child) {
              return ConnectivityWrapper(
                child: AppLockGate(
                  child: child!,
                ),
              );
            },
          );
        },
      ),
    );
  }

  Route<dynamic>? _onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return MaterialPageRoute(
          builder: (_) => SplashScreen(
            initialNotificationData: initialNotificationData,
            isFromNotification: isFromNotification,
          ),
        );

      case '/dashboard':
        return MaterialPageRoute(builder: (_) => const DashboardScreen());

      case '/call':
        final args = settings.arguments as Map<String, dynamic>? ?? {};
        return MaterialPageRoute(
          builder: (_) => SimpleCallScreen(
            token: args['token'],
            roomId: args['roomId'],
            callId: args['callId'],
            callType: args['callType'] ?? 'video',
            isCaller: args['isCaller'] ?? true,
            targetUserName: args['targetUserName'] ?? '',
            targetUserId: args['targetUserId'] ?? '',
          ),
        );

      case '/incoming-call':
        final args = settings.arguments as Map<String, dynamic>? ?? {};
        final callData =
            (args['callData'] as Map<String, dynamic>?) ?? args;
        final userToken = args['userToken'] as String?;
        return MaterialPageRoute(
          builder: (_) => IncomingCallScreen(
            callData: callData,
            userToken: userToken,
          ),
        );

      default:
        return AppRouter.generateRoute(settings);
    }
  }
}