import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_messaging/firebase_messaging.dart';

import '../app/constants.dart';
import '../component/test.dart';
import '../main.dart';
import '../models/user.dart';
import '../screens/SnapchatLoginScreen.dart';
import '../services/auth_service.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../services/notification_service.dart';

class AppEntry extends StatefulWidget {
  final Map<String, dynamic>? initialNotificationData;

  const AppEntry({Key? key, this.initialNotificationData}) : super(key: key);

  @override
  State<AppEntry> createState() => _AppEntryState();
}

class _AppEntryState extends State<AppEntry> with WidgetsBindingObserver {
  final AuthService _authService = AuthService();

  bool _isLoading = true;
  bool _isLoggedIn = false;
  bool _isVerified = false;
  bool _hasNavigatedFromNotification = false; // Track if we've navigated

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _checkLoginStatus();
    _initNotifications();
  }

  void _initNotifications() {
    // 🔔 Foreground notifications
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;

      if (notification != null) {
        NotificationService.show(
          title: notification.title ?? 'Notification',
          body: notification.body ?? '',
        );
      }
    });

    // 👉 App opened from background via notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint("👉 Notification clicked: ${message.data}");
      _handleNotificationNavigation(message.data);
    });
  }

  Future<void> _checkLoginStatus() async {
    try {
      _isLoggedIn = await _authService.isLoggedIn();

      if (!_isLoggedIn) {
        setState(() => _isLoading = false);
        return;
      }

      final user = await _authService.getCurrentUser();

      if (user == null) {
        await _authService.logout();
        setState(() {
          _isLoggedIn = false;
          _isLoading = false;
        });
        return;
      }

      await _checkVerificationStatus(user);
    } catch (e) {
      debugPrint('❌ Login check error: $e');
      await _authService.logout();
      setState(() {
        _isLoggedIn = false;
        _isLoading = false;
      });
    }
  }

  Future<void> _checkVerificationStatus(User user) async {
    try {
      final token = await _authService.getToken();

      if (token == null) {
        setState(() {
          _isLoggedIn = false;
          _isLoading = false;
        });
        return;
      }

      final response = await http.get(
        Uri.parse('${AppConstants.apiBaseUrl}/auth/check-verification'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _isVerified = data['isVerified'] == true;
          _isLoading = false;
        });

        // AFTER login check, handle initial notification if exists
        if (widget.initialNotificationData != null && !_hasNavigatedFromNotification) {
          _handleInitialNotification();
        }
      } else if (response.statusCode == 403) {
        await _authService.logout();
        _showBlockedDialog(
          'Your account has been unverified by HR. Please contact HR.',
        );
      } else {
        await _authService.logout();
        setState(() {
          _isLoggedIn = false;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Verification error: $e');
      await _authService.logout();
      setState(() {
        _isLoggedIn = false;
        _isLoading = false;
      });
    }
  }

  void _handleInitialNotification() {
    if (widget.initialNotificationData != null && _isLoggedIn && _isVerified) {
      _hasNavigatedFromNotification = true;

      // Add a small delay to ensure navigation works properly
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleNotificationNavigation(widget.initialNotificationData!);
      });
    }
  }

  void _handleNotificationNavigation(Map<String, dynamic> data) {
    final type = data['type'];

    switch (type) {
      case 'test_notification':
        final firedAt = data['firedAt'] ?? '';
        navigatorKey.currentState?.pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => TestScreen(firedAt: firedAt),
          ),
              (route) => false, // Clear all previous routes
        );
        break;
    }
  }

  void _showBlockedDialog(String message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          title: const Text('Access Denied'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (_) => SnapchatLoginScreen(),
                  ),
                      (route) => false,
                );
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Checking session...'),
            ],
          ),
        ),
      );
    }

    // If we have initial notification and user is logged in,
    // we'll navigate from initState, so just show dashboard temporarily
    return _isLoggedIn && _isVerified
        ? const DashboardScreen()
        : SnapchatLoginScreen();
  }
}