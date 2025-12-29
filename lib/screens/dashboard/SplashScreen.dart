// screens/splash_screen.dart
import 'package:flutter/material.dart';
import 'package:staffsync/screens/SnapchatLoginScreen.dart';
import 'package:staffsync/screens/dashboard/dashboard_screen.dart';
import 'package:staffsync/services/auth_service.dart';
import 'package:staffsync/app/constants.dart';
import 'package:staffsync/models/user.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:staffsync/component/test.dart'; // Import TestScreen

class SplashScreen extends StatefulWidget {
  final Map<String, dynamic>? initialNotificationData;
  final bool isFromNotification;

  const SplashScreen({
    Key? key,
    this.initialNotificationData,
    required this.isFromNotification,
  }) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final AuthService _authService = AuthService();
  bool _processing = true;

  @override
  void initState() {
    super.initState();
    debugPrint('🔄 SplashScreen initState called');
    debugPrint('📊 Initial data: ${widget.initialNotificationData}');
    debugPrint('🎯 Is from notification: ${widget.isFromNotification}');

    // Add a small delay to ensure everything is loaded
    Future.delayed(const Duration(milliseconds: 500), () {
      _initializeApp();
    });
  }

  Future<void> _initializeApp() async {
    try {
      debugPrint('🔄 Starting app initialization...');

      // FIRST: Check if we came from notification
      if (widget.isFromNotification && widget.initialNotificationData != null) {
        debugPrint('🎯 App opened from notification - checking login status');

        // Check if user is logged in
        final isLoggedIn = await _authService.isLoggedIn();

        if (isLoggedIn) {
          debugPrint('✅ User is logged in - navigating directly from notification');
          // User is logged in, navigate directly
          _handleNotificationNavigation(widget.initialNotificationData!);
          return;
        } else {
          debugPrint('⚠️ User not logged in - will show login screen first');
          // User needs to login first
          _navigateToLogin();
          return;
        }
      }

      // NORMAL FLOW: Not from notification
      debugPrint('🔄 Normal flow - checking authentication...');

      final isLoggedIn = await _authService.isLoggedIn();

      if (!isLoggedIn) {
        debugPrint('➡️ Not logged in - navigating to login');
        _navigateToLogin();
        return;
      }

      final user = await _authService.getCurrentUser();
      final token = await _authService.getToken();

      if (user == null || token == null) {
        debugPrint('❌ Invalid session - logging out');
        await _authService.logout();
        _navigateToLogin();
        return;
      }

      final isVerified = await _checkVerificationStatus(token);

      if (!isVerified) {
        debugPrint('❌ Account not verified');
        _showBlockedDialog('Your account has been unverified by HR. Please contact HR.');
        return;
      }

      debugPrint('✅ All checks passed - navigating to dashboard');
      _navigateToDashboard();

    } catch (e) {
      debugPrint('❌ Splash initialization error: $e');
      _navigateToLogin();
    } finally {
      setState(() {
        _processing = false;
      });
    }
  }

  Future<bool> _checkVerificationStatus(String token) async {
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.apiBaseUrl}/auth/check-verification'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['isVerified'] == true;
      }
      return false;
    } catch (e) {
      debugPrint('❌ Verification check error: $e');
      return false;
    }
  }

  void _navigateToLogin() {
    debugPrint('➡️ Navigating to login screen');
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => SnapchatLoginScreen()),
          (route) => false,
    );
  }

  void _navigateToDashboard() {
    debugPrint('➡️ Navigating to dashboard');
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const DashboardScreen()),
          (route) => false,
    );
  }

  void _handleNotificationNavigation(Map<String, dynamic> data) {
    debugPrint('🎯 Handling notification navigation with data: $data');

    final type = data['type'];

    switch (type) {
      case 'test_notification':
        final firedAt = data['firedAt'] ?? '';
        debugPrint('➡️ Navigating to TestScreen with firedAt: $firedAt');

        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => TestScreen(firedAt: firedAt),
          ),
              (route) => false,
        );
        break;

    // Add other notification types as needed
      case 'leave_update':
      // Handle leave update
        break;

      case 'attendance_reminder':
      // Handle attendance
        break;

      default:
        debugPrint('⚠️ Unknown notification type: $type - navigating to dashboard');
        _navigateToDashboard();
    }
  }

  void _showBlockedDialog(String message) {
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
                MaterialPageRoute(builder: (_) => SnapchatLoginScreen()),
                    (route) => false,
              );
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Your logo
            Image.asset(
              'assets/staff_syncc.png',
              width: 150,
              height: 150,
            ),
            const SizedBox(height: 30),
            const Text(
              'StaffSync',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 50),
            if (_processing) ...[
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
              const SizedBox(height: 20),
              Text(
                widget.isFromNotification ? 'Opening notification...' : 'Loading...',
                style: const TextStyle(color: Colors.grey),
              ),
            ],
            // Debug info
            if (widget.isFromNotification) ...[
              const SizedBox(height: 20),
              const Text(
                '📱 Opened from notification',
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}