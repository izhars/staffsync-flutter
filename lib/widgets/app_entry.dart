import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_messaging/firebase_messaging.dart';
import '../app/constants.dart';
import '../core/navigation.dart';
import '../models/user.dart';
import '../screens/snapchat_login_screen.dart';
import '../services/auth_service.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../services/notification_service.dart';

class AppEntry extends StatefulWidget {
  final Map<String, dynamic>? initialNotificationData;
  final bool isFromNotification;

  const AppEntry({
    Key? key,
    this.initialNotificationData,
    required this.isFromNotification,
  }) : super(key: key);

  @override
  State<AppEntry> createState() => _AppEntryState();
}

class _AppEntryState extends State<AppEntry> with WidgetsBindingObserver {
  final AuthService _authService = AuthService();

  bool _isLoading = true;
  bool _isLoggedIn = false;
  bool _isVerified = false;
  bool _hasNavigatedFromNotification = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkLoginStatus();
    _initNotifications();
  }

  void _initNotifications() {
    // ✅ FCM foreground & onMessageOpenedApp listeners are handled
    // centrally in NotificationService.init() — no duplicate listeners here.
    // See notification_service.dart _setupFirebaseListeners().
    debugPrint('🔔 [AppEntry] Notification handling delegated to NotificationService');
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
        if (widget.initialNotificationData != null &&
            !_hasNavigatedFromNotification &&
            widget.isFromNotification) {
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
    if (widget.initialNotificationData != null &&
        _isLoggedIn &&
        _isVerified &&
        !_hasNavigatedFromNotification) {
      _hasNavigatedFromNotification = true;

      // Add a small delay to ensure navigation works properly
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleNotificationNavigation(widget.initialNotificationData!);
      });
    }
  }

  void _handleNotificationNavigation(Map<String, dynamic> data) {
    final type = data['type'];

    debugPrint('📱 AppEntry handling notification: $type');

    switch (type) {
      case 'incoming_call':
        debugPrint('📞 Call notification handled in main.dart');
        break;

      case 'employee_interaction':
        final senderName = data['senderName'] ?? 'Someone';
        final interactionType = data['interactionType'] ?? 'interacted';

        ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
          SnackBar(
            content: Text('$senderName $interactionType'),
            backgroundColor: Colors.blue,
            duration: Duration(seconds: 3),
          ),
        );
        break;

      default:
        debugPrint('Unknown notification type: $type');
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
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed) {
      // Check for pending notifications when app resumes
      FirebaseMessaging.instance.getInitialMessage().then((message) {
        if (message != null && !_hasNavigatedFromNotification) {
          _handleNotificationNavigation(message.data);
          _hasNavigatedFromNotification = true;
        }
      });
    }
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

    return _isLoggedIn && _isVerified
        ? const DashboardScreen()
        : SnapchatLoginScreen();
  }
}