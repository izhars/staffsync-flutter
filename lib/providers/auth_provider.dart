import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/two_factor_result.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  TwoFactorRequired? _pendingTwoFactor;
  TwoFactorRequired? get pendingTwoFactor => _pendingTwoFactor;

  User? _user;
  bool _isLoading = false;
  String? _error;
  String? _fcmToken;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get fcmToken => _fcmToken;

  /// Set FCM token
  void setFcmToken(String token) {
    _fcmToken = token;
    notifyListeners();
  }

  /// 🔹 Login with Employee ID + password + FCM token
  Future<LoginOutcome> login(
      String employeeId,
      String password, {
        String? fcmToken,
      }) async {
    _isLoading = true;
    _error = null;
    _pendingTwoFactor = null;
    notifyListeners();

    try {
      _user = await _authService.login(
        employeeId,
        password,
        fcmToken: fcmToken ?? _fcmToken,
      );
      _isLoading = false;
      notifyListeners();
      return _user != null ? LoginOutcome.success : LoginOutcome.failed;
    } on TwoFactorRequiredException catch (e) {
      _pendingTwoFactor = TwoFactorRequired(
        ticket: e.ticket,
        maskedEmail: e.maskedEmail,
        method: e.method,
        expiresInSeconds: e.expiresInSeconds,
      );
      _isLoading = false;
      notifyListeners();
      return LoginOutcome.twoFactorRequired;
    } catch (e) {
      _error = _extractErrorMessage(e);
      _isLoading = false;
      notifyListeners();
      return LoginOutcome.failed;
    }
  }

  /// Called from the 2FA verify screen
  Future<bool> verifyTwoFactorLogin({
    required String ticket,
    required String code,
    String? fcmToken,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _user = await _authService.verifyTwoFactorLogin(
        ticket: ticket,
        code: code,
        fcmToken: fcmToken ?? _fcmToken,
      );
      _pendingTwoFactor = null;
      _isLoading = false;
      notifyListeners();
      return _user != null;
    } catch (e) {
      _error = _extractErrorMessage(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<String> resendTwoFactorCode(String ticket) {
    return _authService.resendTwoFactorCode(ticket: ticket);
  }

  /// Update FCM token on server
  Future<bool> updateFcmTokenOnServer(String token) async {
    try {
      final success = await _authService.updateFcmToken(token);
      if (success) {
        _fcmToken = token;
      }
      return success;
    } catch (e) {
      return false;
    }
  }

  /// Get stored FCM token
  Future<String?> getStoredFcmToken() async {
    return await _authService.getStoredFcmToken();
  }

  /// Send forgot password request (still uses email, since it's account-recovery)
  Future<bool> forgotPassword(String email) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final success = await _authService.forgotPassword(email.trim());
      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _error = _extractErrorMessage(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// 🔹 Extract clean error message from various error formats
  String _extractErrorMessage(dynamic error) {
    if (error is String) {
      return error.replaceFirst('Exception:', '').trim();
    }

    if (error is Exception) {
      String msg = error.toString().replaceFirst('Exception:', '').trim();

      try {
        final decoded = jsonDecode(msg);
        if (decoded is Map && decoded.containsKey('message')) {
          return decoded['message'].toString();
        }
      } catch (_) {
        // Not JSON, return as is
      }

      return msg;
    }

    if (error is Map) {
      if (error.containsKey('message')) {
        return error['message'].toString();
      }
      return error.toString();
    }

    return error.toString();
  }

  /// 🔹 Logout and delete stored token
  Future<void> logout() async {
    await _authService.logout();
    _user = null;
    notifyListeners();
  }

  /// 🔹 Check if auth token exists
  Future<bool> hasToken() async {
    final token = await _secureStorage.read(key: 'auth_token');
    return token != null && token.isNotEmpty;
  }

  /// 🔹 Clear error message
  void clearError() {
    if (_error != null) {
      _error = null;
      notifyListeners();
    }
  }
}

enum LoginOutcome { success, twoFactorRequired, failed }