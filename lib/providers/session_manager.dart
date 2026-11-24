// services/session_service.dart
import 'package:flutter/material.dart';
import '../screens/snapchat_login_screen.dart';
import '../services/auth_service.dart';

class SessionService {
  static final SessionService _instance = SessionService._internal();
  factory SessionService() => _instance;
  SessionService._internal();

  static const String _sessionStatusKey = 'session_status_key';

  Future<SessionStatus> checkSession() async {
    // Reuse your existing AuthService logic
    final authService = AuthService();
    return await authService.checkSession();
  }

  // Global session validation with auto-handling
  Future<bool> validateSession({
    required BuildContext context,
    bool showDialogs = true,
    Function()? onSessionValid,
    Function()? onSessionExpired,
  }) async {
    try {
      final status = await checkSession();

      switch (status) {
        case SessionStatus.valid:
          onSessionValid?.call();
          return true;

        case SessionStatus.expired:
        case SessionStatus.requiresLogout:
          if (showDialogs && context.mounted) {
            await _showSessionExpiredDialog(context);
          }
          onSessionExpired?.call();
          return false;

        case SessionStatus.deviceMismatch:
          if (showDialogs && context.mounted) {
            await _showDeviceMismatchDialog(context);
          }
          return false;

        case SessionStatus.invalid:
        case SessionStatus.unknown:
          return false;
      }
    } catch (e) {
      debugPrint('Session validation error: $e');
      return false;
    }
  }

  Future<void> _showSessionExpiredDialog(BuildContext context) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Session Expired'),
        content: const Text('Your session has expired. Please login again.'),
        actions: [
          TextButton(
            onPressed: () async {
              await AuthService().logout();
              if (context.mounted) {
                Navigator.of(context).pop();
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (_) => const SnapchatLoginScreen(),
                  ),
                      (route) => false,
                );
              }
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _showDeviceMismatchDialog(BuildContext context) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Device Mismatch'),
        content: const Text('Account is logged in on another device. Please login again.'),
        actions: [
          TextButton(
            onPressed: () async {
              await AuthService().logout();
              if (context.mounted) {
                Navigator.of(context).pop();
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (_) => const SnapchatLoginScreen(),
                  ),
                      (route) => false,
                );
              }
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}