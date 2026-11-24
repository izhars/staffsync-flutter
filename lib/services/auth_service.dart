import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:async';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../models/device_session.dart';
import '../models/user.dart';
import 'api_service.dart';
import '../app/constants.dart';

class AuthService {
  // Storage keys
  static const _authTokenKey = 'auth_token';
  static const _userDataKey = 'user_data';
  static const _userIdKey = 'id';
  static const _fcmTokenKey = 'fcm_token';
  static const _deviceIdKey = 'device_id';
  static const _verificationStatusKey = 'verification_status';
  static const _lastVerificationCheckKey = 'last_verification_check';
  static const _lastActivityKey = 'last_activity';
  static const _sessionExpiryKey = 'session_expiry';

  // Timeout constants (in minutes)
  static const _verificationCacheTimeout = 5;
  static const _sessionTimeout = 30;

  final ApiService _apiService = ApiService();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  // Singleton instance
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  // ==================== DEVICE METHODS ====================

  /// Get or create unique device ID
  Future<String> getDeviceId({bool forceRefresh = false}) async {
    // Check if we already have a stored device ID
    final storedId = await _secureStorage.read(key: _deviceIdKey);
    if (storedId != null && !forceRefresh) {
      return storedId;
    }

    try {
      String deviceId;
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        deviceId = androidInfo.id ??
            androidInfo.serialNumber ??
            _generateFallbackId();
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        deviceId = iosInfo.identifierForVendor ?? _generateFallbackId();
      } else {
        deviceId = _generateFallbackId();
      }

      // Clean and store the ID
      deviceId = deviceId.replaceAll(RegExp(r'[^\w\-]'), '_');
      await _secureStorage.write(key: _deviceIdKey, value: deviceId);
      return deviceId;
    } catch (e) {
      debugPrint('Device ID fetch error: $e');
      final fallbackId = _generateFallbackId();
      await _secureStorage.write(key: _deviceIdKey, value: fallbackId);
      return fallbackId;
    }
  }

  String _generateFallbackId() {
    final random = Random();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final randomNum = random.nextInt(999999);
    return 'fallback_${timestamp}_$randomNum';
  }

  /// Get device information
  Future<Map<String, dynamic>> getDeviceInfo() async {
    try {
      final deviceId = await getDeviceId();
      final platform = Platform.isAndroid ? 'Android' :
      Platform.isIOS ? 'iOS' :
      Platform.isFuchsia ? 'Fuchsia' : 'Unknown';

      String model = 'Unknown';
      String osVersion = 'Unknown';

      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        model = androidInfo.model ?? 'Unknown';
        osVersion = androidInfo.version.release ?? 'Unknown';
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        model = iosInfo.model ?? 'Unknown';
        osVersion = iosInfo.systemVersion ?? 'Unknown';
      }

      // Get app version from package info
      final packageInfo = await PackageInfo.fromPlatform();

      return {
        'deviceId': deviceId,
        'platform': platform,
        'model': model,
        'osVersion': osVersion,
        'appVersion': packageInfo.version,
        'appBuildNumber': packageInfo.buildNumber,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      debugPrint('Device info error: $e');
      return {'deviceId': await getDeviceId(), 'error': e.toString()};
    }
  }

  // ==================== AUTHENTICATION METHODS ====================

  /// Login user with comprehensive error handling
  Future<User?> login(String employeeId, String password, {String? fcmToken}) async {
    try {
      final deviceId = await getDeviceId();
      final url = Uri.parse('${AppConstants.apiBaseUrl}/auth/login');

      final Map<String, dynamic> body = {
        'employeeId': employeeId.trim().toUpperCase(),
        'password': password,
        'deviceId': deviceId,
        'platform': Platform.isAndroid
            ? 'android'
            : Platform.isIOS
            ? 'ios'
            : 'web',
        'deviceInfo': await getDeviceInfo(),
      };

      // Add FCM token if available
      if (fcmToken != null && fcmToken.isNotEmpty) {
        body['fcmToken'] = fcmToken;
      }

      debugPrint('🔐 Login attempt for: $employeeId');
      debugPrint('📱 Device ID: $deviceId');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        final errorData = _parseErrorResponse(response);
        throw AuthException(
          errorData['message'] ?? 'Login failed',
          statusCode: response.statusCode,
          errorCode: errorData['code'],
          requiresLogout: errorData['requiresLogout'] ?? false,
        );
      }

      final data = jsonDecode(response.body);
      // ── 2FA branch ─────────────────────────────────────────────
      if (data['twoFactorRequired'] == true) {
        throw TwoFactorRequiredException(
          ticket: data['ticket'] ?? '',
          maskedEmail: data['maskedEmail'] ?? '',
          method: data['method'] ?? 'email',
          expiresInSeconds: (data['expiresInSeconds'] as num?)?.toInt() ?? 300,
        );
      }

      if (data['success'] != true || data['user'] == null) {
        throw AuthException(
          data['message'] ?? 'Login failed',
          statusCode: response.statusCode,
        );
      }

      final token = data['token'];
      final user = User.fromJson(data['user']);

      // Clear any previous verification cache
      await clearVerificationCache();

      // Store auth data
      await _storeAuthData(token, user, data['user']);

      // Store FCM token locally if provided
      if (fcmToken != null && fcmToken.isNotEmpty) {
        await _storeFcmToken(fcmToken);
      }

      // Update session activity
      await _updateLastActivity();

      debugPrint('✅ Login successful for: ${user.employeeId}');  // ← was user.email
      return user;
    } on http.ClientException catch (e) {
      throw AuthException('Network error: ${e.message}', networkError: true);
    } on SocketException catch (e) {
      throw AuthException('No internet connection: ${e.message}', networkError: true);
    } on TimeoutException catch (_) {
      throw AuthException('Request timeout. Please try again.', networkError: true);
    } on FormatException catch (e) {
      throw AuthException('Invalid server response: ${e.message}');
    } catch (e) {
      rethrow;
    }
  }

  /// Verify the OTP and complete the login
  Future<User?> verifyTwoFactorLogin({
    required String ticket,
    required String code,
    String? fcmToken,
  }) async {
    final deviceId = await getDeviceId();
    final url = Uri.parse('${AppConstants.apiBaseUrl}/auth/2fa/verify-login');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'ticket': ticket,
        'code': code,
        'deviceId': deviceId,
        'fcmToken': fcmToken,
        'platform': Platform.isAndroid
            ? 'android'
            : Platform.isIOS
            ? 'ios'
            : 'web',
      }),
    ).timeout(const Duration(seconds: 30));

    final data = jsonDecode(response.body);

    if (response.statusCode != 200 || data['success'] != true) {
      throw AuthException(
        data['message'] ?? '2FA verification failed',
        statusCode: response.statusCode,
        errorCode: data['code'],
      );
    }

    final token = data['token'] as String?;
    final userJson = data['user'] as Map<String, dynamic>?;
    if (token == null || userJson == null) {
      throw AuthException('Invalid 2FA response');
    }

    final user = User.fromJson(userJson);
    await clearVerificationCache();
    await _storeAuthData(token, user, userJson);
    if (fcmToken != null && fcmToken.isNotEmpty) {
      await _storeFcmToken(fcmToken);
    }
    await _updateLastActivity();
    return user;
  }

  /// Resend OTP
  Future<String> resendTwoFactorCode({required String ticket}) async {
    final url = Uri.parse('${AppConstants.apiBaseUrl}/auth/2fa/resend');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'ticket': ticket}),
    ).timeout(const Duration(seconds: 30));

    final data = jsonDecode(response.body);
    if (response.statusCode != 200 || data['success'] != true) {
      throw AuthException(
        data['message'] ?? 'Failed to resend code',
        statusCode: response.statusCode,
      );
    }
    return data['message']?.toString() ?? 'Code resent';
  }

  /// Register new user
  Future<Map<String, dynamic>> register(
      String name,
      String email,
      String password,
      String confirmPassword,
      {String? phone, String? employeeId}
      ) async {
    try {
      if (password != confirmPassword) {
        throw AuthException('Passwords do not match');
      }

      final response = await _apiService.post('/auth/register', {
        'name': name.trim(),
        'email': email.trim(),
        'password': password,
        'confirmPassword': confirmPassword,
        if (phone != null && phone.isNotEmpty) 'phone': phone.trim(),
        if (employeeId != null && employeeId.isNotEmpty) 'employeeId': employeeId.trim(),
        'deviceInfo': await getDeviceInfo(),
      });

      if (response['success'] != true) {
        throw AuthException(response['message'] ?? 'Registration failed');
      }

      return response;
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('Registration failed: ${e.toString()}');
    }
  }

  /// Verify email with OTP
  Future<bool> verifyEmail(String email, String otp) async {
    try {
      final response = await _apiService.post('/auth/verify-email', {
        'email': email.trim(),
        'otp': otp,
      });

      return response['success'] == true;
    } catch (e) {
      debugPrint('Email verification error: $e');
      return false;
    }
  }

  /// Resend verification email
  Future<bool> resendVerificationEmail(String email) async {
    try {
      final response = await _apiService.post('/auth/resend-verification', {
        'email': email.trim(),
      });

      return response['success'] == true;
    } catch (e) {
      debugPrint('Resend verification error: $e');
      return false;
    }
  }

  // ==================== VERIFICATION METHODS ====================

  /// Comprehensive verification check with caching and retry logic
  Future<VerificationResult> checkVerification({
    bool forceCheck = false,
    bool retryOnFailure = true,
    int maxRetries = 2,
  }) async {
    debugPrint('🔍 [VERIFY] Verification started | forceCheck=$forceCheck');

    final token = await getToken();

    if (token == null) {
      debugPrint('❌ [VERIFY] No auth token found');

      return VerificationResult(
        isVerified: false,
        message: 'No authentication token',
        requiresLogin: true,
        errorType: AuthErrorType.noToken,
      );
    }

    // Session expiry check
    if (await _isSessionExpired()) {
      debugPrint('⏰ [VERIFY] Session expired');

      return VerificationResult(
        isVerified: false,
        message: 'Session expired',
        requiresLogin: true,
        errorType: AuthErrorType.sessionExpired,
      );
    }

    // Cache check
    if (!forceCheck) {
      debugPrint('📦 [VERIFY] Checking cached verification');

      final cachedResult = await _getCachedVerification();
      if (cachedResult != null) {
        debugPrint('⚡ [VERIFY] Using cached verification result');
        return cachedResult;
      }
    }

    VerificationResult? result;
    int attempt = 0;

    while (attempt <= maxRetries) {
      try {
        attempt++;
        debugPrint('🌐 [VERIFY] Attempt $attempt/$maxRetries');

        result = await _performVerificationCheck(token);

        debugPrint('📥 [VERIFY] Server response:',);
        debugPrint('    isVerified=${result.isVerified}');
        debugPrint('    deviceMismatch=${result.deviceMismatch}');
        debugPrint('    requiresLogout=${result.requiresLogout}');
        debugPrint('    message=${result.message}');

        if (result.isVerified) {
          debugPrint('💾 [VERIFY] Caching verification result');
          await _cacheVerification(result);
          await _updateLastActivity();
        }

        return result;
      } catch (e) {
        debugPrint('💥 [VERIFY] Attempt $attempt failed: $e');

        if (attempt > maxRetries || !retryOnFailure) {
          debugPrint('🛑 [VERIFY] Retry limit reached');

          final cached = await _getCachedVerification();
          if (cached != null && !forceCheck) {
            debugPrint('📦 [VERIFY] Falling back to cached result');

            return cached.copyWith(
              message: 'Using cached verification (network error)',
              networkError: true,
            );
          }

          return VerificationResult(
            isVerified: false,
            message: e is AuthException ? e.message : 'Verification failed',
            networkError: true,
            errorType: AuthErrorType.networkError,
          );
        }

        // Backoff
        debugPrint('⏳ [VERIFY] Retrying after delay');
        await Future.delayed(Duration(seconds: attempt));
      }
    }

    // Should never happen
    debugPrint('🚨 [VERIFY] Unexpected fallthrough reached');

    return VerificationResult(
      isVerified: false,
      message: 'Verification failed after retries',
      errorType: AuthErrorType.unknown,
    );
  }

  /// Check session validity
  Future<SessionStatus> checkSession() async {
    try {
      final token = await getToken();

      if (token == null || token.isEmpty) {
        return SessionStatus.invalid;
      }

      final result = await _performVerificationCheck(token);

      // Device mismatch (highest priority)
      if (result.reason == 'DEVICE_MISMATCH') {
        return SessionStatus.deviceMismatch;
      }

      // Explicit logout required
      if (result.requiresLogout == true) {
        return SessionStatus.requiresLogout;
      }

      // Verified = good to go
      if (result.isVerified == true) {
        return SessionStatus.valid;
      }

      // Not verified but no hard error
      return SessionStatus.invalid;

    } on TimeoutException {
      return SessionStatus.unknown; // network issue
    } catch (e) {
      debugPrint('❌ checkSession error: $e');
      return SessionStatus.unknown;
    }
  }

  /// Perform actual verification API call
  Future<VerificationResult> _performVerificationCheck(String token) async {
    final deviceId = await getDeviceId();
    final url = Uri.parse('${AppConstants.apiBaseUrl}/auth/check-verification');

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
        'device-id': deviceId,
        'X-App-Version': '1.0.0', // Replace with actual version
      },
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return VerificationResult.fromJson(data);
    } else if (response.statusCode == 403) {
      // Account unverified
      final data = jsonDecode(response.body);
      return VerificationResult.fromJson(data)
          .copyWith(requiresLogout: true);
    } else if (response.statusCode == 401) {
      // Unauthorized or device mismatch
      final data = jsonDecode(response.body);
      return VerificationResult.fromJson(data)
          .copyWith(requiresLogout: true);
    } else if (response.statusCode == 429) {
      // Too many requests
      return VerificationResult(
        isVerified: false,
        message: 'Too many verification attempts. Please try again later.',
        errorType: AuthErrorType.rateLimited,
      );
    } else {
      // Other server errors
      final errorData = _parseErrorResponse(response);
      return VerificationResult(
        isVerified: false,
        message: errorData['message'] ?? 'Server error during verification',
        serverError: true,
        errorType: AuthErrorType.serverError,
      );
    }
  }

  /// Validate token without API call
  Future<bool> validateTokenLocally() async {
    final token = await getToken();
    if (token == null || token.isEmpty) return false;

    // Check token format (basic validation)
    final parts = token.split('.');
    if (parts.length != 3) return false;

    // Check expiry from storage
    if (await _isSessionExpired()) return false;

    return true;
  }

  // ==================== PROFILE METHODS ====================

  /// Update user profile
  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> updateData) async {
    final token = await getToken();
    if (token == null) {
      throw AuthException(
        'No auth token found',
        errorType: AuthErrorType.noToken,
      );
    }

    // Remove null values
    updateData.removeWhere((key, value) => value == null);

    final url = Uri.parse('${AppConstants.apiBaseUrl}/auth/update-profile');

    final response = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(updateData),
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) {
      final errorData = _parseErrorResponse(response);
      throw AuthException(
        errorData['message'] ?? 'Failed to update profile',
        statusCode: response.statusCode,
      );
    }

    final data = jsonDecode(response.body);

    if (data['success'] != true) {
      throw AuthException(data['message'] ?? 'Update failed');
    }

    // Update stored user data
    if (data['user'] != null) {
      await _secureStorage.write(
        key: _userDataKey,
        value: jsonEncode(data['user']),
      );

      // Clear verification cache since user data changed
      await clearVerificationCache();
    }

    return data;
  }

  /// Upload profile picture
  Future<Map<String, dynamic>> uploadProfilePicture(File imageFile) async {
    final token = await getToken();
    if (token == null) {
      throw AuthException(
        'No auth token found. Please login.',
        errorType: AuthErrorType.noToken,
      );
    }

    // Validate file
    if (!await imageFile.exists()) {
      throw AuthException('Image file does not exist');
    }

    final fileSize = await imageFile.length();
    if (fileSize > 5 * 1024 * 1024) { // 5MB limit
      throw AuthException('Image size must be less than 5MB');
    }

    final url = Uri.parse('${AppConstants.apiBaseUrl}/auth/profile-picture');

    final fileExtension = imageFile.path.split('.').last.toLowerCase();
    String mimeType = 'image/jpeg';
    if (fileExtension == 'png') mimeType = 'image/png';
    if (fileExtension == 'gif') mimeType = 'image/gif';
    if (fileExtension == 'webp') mimeType = 'image/webp';

    final request = http.MultipartRequest('PUT', url)
      ..headers['Authorization'] = 'Bearer $token'
      ..files.add(await http.MultipartFile.fromPath(
        'file',
        imageFile.path,
        contentType: MediaType.parse(mimeType),
        filename: 'profile_${DateTime.now().millisecondsSinceEpoch}.$fileExtension',
      ));

    final response = await request.send();
    final body = await response.stream.bytesToString();

    if (response.statusCode != 200) {
      final errorData = jsonDecode(body);
      throw AuthException(errorData['message'] ?? 'Upload failed');
    }

    final data = jsonDecode(body);

    if (data['success'] == true && data['user'] != null) {
      // Update stored user data
      await _secureStorage.write(
        key: _userDataKey,
        value: jsonEncode(data['user']),
      );
    }

    return data;
  }

  /// Change password
  Future<String?> changePassword(
      String currentPassword,
      String newPassword,
      String confirmPassword,
      ) async {
    // ── Client-side validation ─────────────────────────────────
    if (currentPassword.isEmpty) {
      throw AuthException('Current password is required');
    }
    if (newPassword.isEmpty) {
      throw AuthException('New password is required');
    }
    if (newPassword.length < 8) {
      throw AuthException('Password must be at least 8 characters');
    }
    if (newPassword == currentPassword) {
      throw AuthException('New password must differ from current password');
    }
    if (newPassword != confirmPassword) {
      throw AuthException('New passwords do not match');
    }

    final token = await getToken();
    if (token == null) {
      throw AuthException('Not logged in', errorType: AuthErrorType.noToken);
    }

    final url = Uri.parse('${AppConstants.apiBaseUrl}/auth/change-password');

    try {
      final response = await http.put(                      // ← PUT, not POST
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        }),
      ).timeout(const Duration(seconds: 30));

      final data = jsonDecode(response.body);

      if (response.statusCode != 200 || data['success'] != true) {
        throw AuthException(
          data['message'] ?? 'Failed to change password',
          statusCode: response.statusCode,
          errorCode: data['code'],
        );
      }

      // ── Naya token store karo (backend session rotate karta hai) ──
      final newToken = data['token'] as String?;
      if (newToken != null && newToken.isNotEmpty) {
        await _secureStorage.write(key: _authTokenKey, value: newToken);
        await _updateLastActivity();
      }

      debugPrint('✅ Password changed successfully');
      return newToken;   // caller ko bhi de do agar chahiye
    } on http.ClientException catch (e) {
      throw AuthException('Network error: ${e.message}', networkError: true);
    } on SocketException catch (e) {
      throw AuthException('No internet: ${e.message}', networkError: true);
    } on TimeoutException {
      throw AuthException('Request timeout. Try again.', networkError: true);
    }
  }

  // ==================== PASSWORD RESET METHODS ====================

  /// Send forgot password request
  Future<bool> forgotPassword(String email) async {
    final url = Uri.parse('${AppConstants.apiBaseUrl}/auth/forgot-password');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email.trim()}),
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['success'] == true;
    } else {
      final errorData = _parseErrorResponse(response);
      throw AuthException(errorData['message'] ?? 'Failed to send reset link');
    }
  }

  /// Reset password with token
  Future<bool> resetPassword(
      String token,
      String newPassword,
      String confirmPassword,
      ) async {
    if (newPassword != confirmPassword) {
      throw AuthException('Passwords do not match');
    }

    if (newPassword.length < 6) {
      throw AuthException('Password must be at least 6 characters');
    }

    final url = Uri.parse('${AppConstants.apiBaseUrl}/auth/reset-password');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'token': token,
        'newPassword': newPassword,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['success'] == true;
    } else {
      final errorData = _parseErrorResponse(response);
      throw AuthException(errorData['message'] ?? 'Failed to reset password');
    }
  }

  // ==================== USER DATA METHODS ====================

  /// Fetch current user from server
  Future<User?> fetchMe({bool forceRefresh = false}) async {
    final token = await getToken();
    if (token == null) {
      throw AuthException(
        'No auth token found. Please login.',
        errorType: AuthErrorType.noToken,
      );
    }

    // Check cache if not forcing refresh
    if (!forceRefresh) {
      final cachedUser = await getCurrentUser();
      if (cachedUser != null) {
        return cachedUser;
      }
    }

    final url = Uri.parse('${AppConstants.apiBaseUrl}/auth/me');
    final response = await http.get(
      url,
      headers: await _buildHeaders(),
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw AuthException(
        'Failed to fetch user',
        statusCode: response.statusCode,
      );
    }

    final data = jsonDecode(response.body);
    if (data['success'] != true || data['user'] == null) {
      throw AuthException(data['message'] ?? 'Failed to fetch user');
    }

    final user = User.fromJson(data['user']);

    // Update stored data
    await _secureStorage.write(
      key: _userDataKey,
      value: jsonEncode(data['user']),
    );

    // Clear verification cache since user data updated
    await clearVerificationCache();
    await _updateLastActivity();

    return user;
  }

  /// Refresh user data silently
  Future<void> refreshUserData() async {
    try {
      await fetchMe(forceRefresh: true);
    } catch (e) {
      debugPrint('Silent refresh failed: $e');
      // Don't throw - this is a background operation
    }
  }

  // ==================== LOGOUT METHOD ====================

  /// Logout with cleanup
  Future<void> logout({bool notifyServer = true}) async {
    final token = await getToken();

    if (notifyServer && token != null) {
      try {
        await http.post(
          Uri.parse('${AppConstants.apiBaseUrl}/auth/logout'),
          headers: await _buildHeaders(),
        ).timeout(const Duration(seconds: 5));
      } catch (e) {
        debugPrint('Logout API call failed: $e');
        // Continue with local cleanup even if API fails
      }
    }

    await _clearAuthData();
    debugPrint('✅ User logged out successfully');
  }

  /// Force logout (e.g., on device mismatch)
  Future<void> forceLogout(String reason) async {
    debugPrint('🔒 Force logout: $reason');
    await logout(notifyServer: false);
  }

  // ==================== FCM TOKEN METHODS ====================

  Future<void> _storeFcmToken(String token) async {
    await _secureStorage.write(key: _fcmTokenKey, value: token);
  }

  Future<String?> getStoredFcmToken() async {
    return await _secureStorage.read(key: _fcmTokenKey);
  }

  Future<bool> updateFcmToken(String fcmToken) async {
    try {
      final token = await getToken();
      if (token == null) return false;

      final url = Uri.parse('${AppConstants.apiBaseUrl}/auth/update-fcm-token');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'fcmToken': fcmToken,
          'deviceId': await getDeviceId(),
        }),
      );

      if (response.statusCode == 200) {
        await _storeFcmToken(fcmToken);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('FCM token update error: $e');
      return false;
    }
  }

  // ==================== CACHE MANAGEMENT ====================

  Future<VerificationResult?> _getCachedVerification() async {
    try {
      final lastCheckStr = await _secureStorage.read(key: _lastVerificationCheckKey);
      final statusStr = await _secureStorage.read(key: _verificationStatusKey);

      if (lastCheckStr != null && statusStr != null) {
        final lastCheck = DateTime.parse(lastCheckStr);
        final now = DateTime.now();
        final difference = now.difference(lastCheck);

        // Use cached result if less than timeout
        if (difference.inMinutes < _verificationCacheTimeout) {
          final status = jsonDecode(statusStr) as Map<String, dynamic>;
          return VerificationResult.fromJson(status);
        }
      }
    } catch (e) {
      debugPrint('Cache read error: $e');
    }
    return null;
  }

  Future<void> _cacheVerification(VerificationResult result) async {
    try {
      await _secureStorage.write(
        key: _verificationStatusKey,
        value: jsonEncode(result.toJson()),
      );
      await _secureStorage.write(
        key: _lastVerificationCheckKey,
        value: DateTime.now().toIso8601String(),
      );
    } catch (e) {
      debugPrint('Cache write error: $e');
    }
  }

  /// Clear verification cache
  Future<void> clearVerificationCache() async {
    await _secureStorage.delete(key: _verificationStatusKey);
    await _secureStorage.delete(key: _lastVerificationCheckKey);
  }

  // ==================== SESSION MANAGEMENT ====================

  Future<void> _updateLastActivity() async {
    await _secureStorage.write(
      key: _lastActivityKey,
      value: DateTime.now().toIso8601String(),
    );

    // Calculate and store expiry
    final expiry = DateTime.now().add(const Duration(minutes: _sessionTimeout));
    await _secureStorage.write(
      key: _sessionExpiryKey,
      value: expiry.toIso8601String(),
    );
  }

  Future<bool> _isSessionExpired() async {
    try {
      final expiryStr = await _secureStorage.read(key: _sessionExpiryKey);
      if (expiryStr == null) return true;

      final expiry = DateTime.parse(expiryStr);
      return DateTime.now().isAfter(expiry);
    } catch (e) {
      debugPrint('Session expiry check error: $e');
      return true;
    }
  }

  /// Extend session (call on user activity)
  Future<void> extendSession() async {
    await _updateLastActivity();
  }

  // ==================== CONVENIENCE GETTERS ====================

  /// Get authentication token
  Future<String?> getToken() async {
    try {
      return await _secureStorage.read(key: _authTokenKey);
    } catch (e) {
      debugPrint('Error reading token: $e');
      return null;
    }
  }

  /// Get stored user data (as Map<String, dynamic>)
  Future<Map<String, dynamic>?> getUserData() async {
    try {
      final userDataJson = await _secureStorage.read(key: _userDataKey);
      if (userDataJson == null) return null;
      return jsonDecode(userDataJson) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Error reading user data: $e');
      return null;
    }
  }

  /// Get current user object
  Future<User?> getCurrentUser() async {
    final userMap = await getUserData();
    if (userMap == null) return null;
    try {
      return User.fromJson(userMap);
    } catch (e) {
      debugPrint('Error parsing user from stored data: $e');
      return null;
    }
  }

  /// Check if user is logged in (with token validation)
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    if (token == null || token.isEmpty) return false;

    // Quick local validation
    return await validateTokenLocally();
  }

  // ==================== FIELD SPECIFIC GETTERS ====================

  Future<String?> getUserStringField(String fieldName) async {
    try {
      final userDataJson = await _secureStorage.read(key: _userDataKey);
      if (userDataJson == null) return null;

      final userMap = jsonDecode(userDataJson) as Map<String, dynamic>;
      return _extractStringFromMap(userMap, fieldName);
    } catch (e) {
      debugPrint('Error getting user field $fieldName: $e');
      return null;
    }
  }

  String? _extractStringFromMap(Map<String, dynamic> map, String fieldName) {
    // Try direct access
    if (map.containsKey(fieldName)) {
      final value = map[fieldName];
      if (value is String) return value;
      if (value != null) return value.toString();
    }

    // Try camelCase variations
    final camelCaseField = _toCamelCase(fieldName);
    if (map.containsKey(camelCaseField)) {
      final value = map[camelCaseField];
      if (value is String) return value;
      if (value != null) return value.toString();
    }

    // Try snake_case variations
    final snakeCaseField = _toSnakeCase(fieldName);
    if (map.containsKey(snakeCaseField)) {
      final value = map[snakeCaseField];
      if (value is String) return value;
      if (value != null) return value.toString();
    }

    // Common field name variations
    final variations = {
      'fullname': ['fullName', 'full_name', 'name', 'username'],
      'employeeid': ['employeeId', 'employee_id', 'empId', 'staffId'],
      'profilepicture': ['profilePicture', 'profile_picture', 'avatar', 'image'],
      'phone': ['phoneNumber', 'mobile', 'contact', 'phoneNo'],
      'role': ['role', 'userRole', 'type', 'position'],
      'department': ['department', 'dept', 'division'],
      'designation': ['designation', 'title', 'jobTitle'],
    };

    final lowerFieldName = fieldName.toLowerCase();
    if (variations.containsKey(lowerFieldName)) {
      for (final variation in variations[lowerFieldName]!) {
        if (map.containsKey(variation)) {
          final value = map[variation];
          if (value is String) return value;
          if (value != null) return value.toString();
        }
      }
    }

    return null;
  }

  String _toCamelCase(String input) {
    final parts = input.split('_');
    if (parts.length == 1) return input;

    return parts.first.toLowerCase() +
        parts.sublist(1).map((part) =>
        part.isNotEmpty ? part[0].toUpperCase() + part.substring(1).toLowerCase() : ''
        ).join();
  }

  String _toSnakeCase(String input) {
    return input.replaceAllMapped(
        RegExp(r'([a-z])([A-Z])'),
            (match) => '${match.group(1)}_${match.group(2)!.toLowerCase()}'
    ).toLowerCase();
  }

  // Specific field getters
  Future<String?> getUserId() async => getUserStringField('id');
  Future<String?> getUserEmail() async => getUserStringField('email');
  Future<String?> getUserRole() async => getUserStringField('role');
  Future<String?> getUserName() async => getUserStringField('fullName');
  Future<String?> getEmployeeId() async => getUserStringField('employeeId');
  Future<String?> getUserDepartment() async => getUserStringField('department');
  Future<String?> getUserDesignation() async => getUserStringField('designation');
  Future<String?> getUserPhone() async => getUserStringField('phone');
  Future<String?> getUserProfilePicture() async => getUserStringField('profilePicture');
  Future<String?> getUserDeviceId() async => getUserStringField('deviceId');

  // ==================== PRIVATE METHODS ====================

  Future<Map<String, String>> _buildHeaders() async {
    final token = await getToken();
    final deviceId = await getDeviceId();
    final packageInfo = await PackageInfo.fromPlatform();

    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
      'X-App-Version': packageInfo.version,
      'device-id': deviceId,
    };
  }

  Future<void> _storeAuthData(String token, User user, Map<String, dynamic> userJson) async {
    try {
      await _secureStorage.write(key: _authTokenKey, value: token);
      await _secureStorage.write(key: _userIdKey, value: user.id);
      await _secureStorage.write(key: _userDataKey, value: jsonEncode(userJson));
      await _updateLastActivity();
    } catch (e) {
      debugPrint('Error storing auth data: $e');
      rethrow;
    }
  }

  Future<void> _clearAuthData() async {
    try {
      await _secureStorage.delete(key: _authTokenKey);
      await _secureStorage.delete(key: _userDataKey);
      await _secureStorage.delete(key: _userIdKey);
      await _secureStorage.delete(key: _fcmTokenKey);
      await _secureStorage.delete(key: _verificationStatusKey);
      await _secureStorage.delete(key: _lastVerificationCheckKey);
      await _secureStorage.delete(key: _lastActivityKey);
      await _secureStorage.delete(key: _sessionExpiryKey);
      // Note: Don't delete deviceId - it's device-specific, not user-specific
    } catch (e) {
      debugPrint('Error clearing auth data: $e');
    }
  }

  Map<String, dynamic> _parseErrorResponse(http.Response response) {
    try {
      final data = jsonDecode(response.body);
      return {
        'message': data['message'] ?? 'Request failed with status ${response.statusCode}',
        'code': data['code'],
        'requiresLogout': data['requiresLogout'] ??
            response.statusCode == 401 ||
                response.statusCode == 403,
      };
    } catch (_) {
      return {
        'message': 'Request failed with status ${response.statusCode}',
        'requiresLogout': response.statusCode == 401 || response.statusCode == 403,
      };
    }
  }
  // ==================== SESSION / DEVICE MANAGEMENT ====================
  /// Fetch all active devices/sessions for current user
  Future<List<DeviceSession>> getSessions() async {
    final token = await getToken();
    if (token == null) {
      throw AuthException('Not logged in', errorType: AuthErrorType.noToken);
    }

    final url = Uri.parse('${AppConstants.apiBaseUrl}/auth/sessions');
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      final errorData = _parseErrorResponse(response);
      throw AuthException(
        errorData['message'] ?? 'Failed to load sessions',
        statusCode: response.statusCode,
      );
    }

    final data = jsonDecode(response.body);
    final currentSessionId = data['currentSessionId'] as String?;
    final list = (data['data'] as List<dynamic>? ?? [])
        .map((e) => DeviceSession.fromJson(e as Map<String, dynamic>, currentSessionId))
        .toList();

    return list;
  }

  /// Revoke a single device (cannot be current one — use logout for that)
  Future<void> revokeSession(String sessionId) async {
    final token = await getToken();
    if (token == null) {
      throw AuthException('Not logged in', errorType: AuthErrorType.noToken);
    }

    final url = Uri.parse('${AppConstants.apiBaseUrl}/auth/sessions/$sessionId');
    final response = await http.delete(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      final errorData = _parseErrorResponse(response);
      throw AuthException(
        errorData['message'] ?? 'Failed to revoke session',
        statusCode: response.statusCode,
      );
    }
  }

  /// Revoke all OTHER devices (keeps current one)
  Future<int> revokeAllOtherSessions() async {
    final token = await getToken();
    if (token == null) {
      throw AuthException('Not logged in', errorType: AuthErrorType.noToken);
    }

    final url = Uri.parse('${AppConstants.apiBaseUrl}/auth/sessions');
    final response = await http.delete(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      final errorData = _parseErrorResponse(response);
      throw AuthException(
        errorData['message'] ?? 'Failed to revoke sessions',
        statusCode: response.statusCode,
      );
    }

    final data = jsonDecode(response.body);
    return (data['revokedCount'] as num?)?.toInt() ?? 0;
  }
}

// ==================== SUPPORTING CLASSES ====================

class VerificationResult {
  final bool isVerified;
  final String message;
  final bool requiresLogout;
  final bool requiresLogin;
  final bool deviceMismatch;
  final bool serverError;
  final bool networkError;
  final AuthErrorType errorType;
  final Map<String, dynamic>? userData;
  final String? reason;
  final DateTime? timestamp;

  VerificationResult({
    this.isVerified = false,
    this.message = '',
    this.requiresLogout = false,
    this.requiresLogin = false,
    this.deviceMismatch = false,
    this.serverError = false,
    this.networkError = false,
    this.errorType = AuthErrorType.none,
    this.userData,
    this.reason,
    this.timestamp,
  });

  factory VerificationResult.fromJson(Map<String, dynamic> json) {
    return VerificationResult(
      isVerified: json['isVerified'] ?? false,
      message: json['message'] ?? '',
      requiresLogout: json['requiresLogout'] ??
          json['reason'] == 'DEVICE_MISMATCH' ||
              json['isVerified'] == false,
      deviceMismatch: json['reason'] == 'DEVICE_MISMATCH',
      userData: json['user'],
      reason: json['reason'],
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'])
          : DateTime.now(),
      errorType: _parseErrorType(json),
    );
  }

  Map<String, dynamic> toJson() => {
    'isVerified': isVerified,
    'message': message,
    'requiresLogout': requiresLogout,
    'deviceMismatch': deviceMismatch,
    'serverError': serverError,
    'networkError': networkError,
    'errorType': errorType.name,
    'userData': userData,
    'reason': reason,
    'timestamp': timestamp?.toIso8601String(),
  };

  VerificationResult copyWith({
    bool? isVerified,
    String? message,
    bool? requiresLogout,
    bool? requiresLogin,
    bool? deviceMismatch,
    bool? serverError,
    bool? networkError,
    AuthErrorType? errorType,
    Map<String, dynamic>? userData,
    String? reason,
    DateTime? timestamp,
  }) {
    return VerificationResult(
      isVerified: isVerified ?? this.isVerified,
      message: message ?? this.message,
      requiresLogout: requiresLogout ?? this.requiresLogout,
      requiresLogin: requiresLogin ?? this.requiresLogin,
      deviceMismatch: deviceMismatch ?? this.deviceMismatch,
      serverError: serverError ?? this.serverError,
      networkError: networkError ?? this.networkError,
      errorType: errorType ?? this.errorType,
      userData: userData ?? this.userData,
      reason: reason ?? this.reason,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  static AuthErrorType _parseErrorType(Map<String, dynamic> json) {
    final reason = json['reason']?.toString().toUpperCase();
    final status = json['status'];

    if (reason == 'DEVICE_MISMATCH') return AuthErrorType.deviceMismatch;
    if (reason == 'ACCOUNT_LOCKED') return AuthErrorType.accountLocked;
    if (reason == 'UNVERIFIED_ACCOUNT') return AuthErrorType.unverified;
    if (status == 403) return AuthErrorType.forbidden;
    if (status == 401) return AuthErrorType.unauthorized;
    if (status == 429) return AuthErrorType.rateLimited;

    return AuthErrorType.none;
  }
}

enum SessionStatus {
  valid,
  invalid,
  expired,
  requiresLogout,
  deviceMismatch,
  unknown,
}

enum AuthErrorType {
  none,
  networkError,
  serverError,
  unauthorized,
  forbidden,
  deviceMismatch,
  accountLocked,
  unverified,
  sessionExpired,
  noToken,
  rateLimited,
  invalidCredentials,
  twoFactorRequired,   // ← add this
  unknown,
}

class TwoFactorRequiredException extends AuthException {
  final String ticket;
  final String maskedEmail;
  final String method;
  final int expiresInSeconds;

  TwoFactorRequiredException({
    required this.ticket,
    required this.maskedEmail,
    this.method = 'email',
    this.expiresInSeconds = 300,
  }) : super('2FA required', errorType: AuthErrorType.twoFactorRequired);
}

class AuthException implements Exception {
  final String message;
  final int? statusCode;
  final String? errorCode;
  final bool requiresLogout;
  final bool networkError;
  final AuthErrorType errorType;

  AuthException(
      this.message, {
        this.statusCode,
        this.errorCode,
        this.requiresLogout = false,
        this.networkError = false,
        this.errorType = AuthErrorType.unknown,
      });

  @override
  String toString() {
    return 'AuthException: $message${statusCode != null ? ' (Status: $statusCode)' : ''}${errorCode != null ? ' [Code: $errorCode]' : ''}';
  }

  bool get isNetworkError => networkError || errorType == AuthErrorType.networkError;
  bool get requiresReauth => requiresLogout || errorType == AuthErrorType.unauthorized;
}

// ==================== HELPER CLASS ====================

class UserDataHelper {
  static final AuthService _authService = AuthService();

  // Authentication methods
  static Future<bool> isLoggedIn() => _authService.isLoggedIn();
  static Future<String?> getToken() => _authService.getToken();
  static Future<bool> validateToken() => _authService.validateTokenLocally();

  // User data methods
  static Future<Map<String, dynamic>?> getUserData() => _authService.getUserData();
  static Future<User?> getCurrentUser() => _authService.getCurrentUser();
  static Future<User?> fetchUser({bool force = false}) => _authService.fetchMe(forceRefresh: force);

  // Specific field getters
  static Future<String?> getRole() => _authService.getUserRole();
  static Future<String?> getEmail() => _authService.getUserEmail();
  static Future<String?> getName() => _authService.getUserName();
  static Future<String?> getId() => _authService.getUserId();
  static Future<String?> getEmployeeId() => _authService.getEmployeeId();
  static Future<String?> getDepartment() => _authService.getUserDepartment();
  static Future<String?> getDesignation() => _authService.getUserDesignation();
  static Future<String?> getPhone() => _authService.getUserPhone();
  static Future<String?> getProfilePicture() => _authService.getUserProfilePicture();
  static Future<String?> getDeviceId() => _authService.getUserDeviceId();

  // Generic field getter
  static Future<String?> getField(String fieldName) => _authService.getUserStringField(fieldName);

  // Verification methods
  static Future<VerificationResult> checkVerification({bool force = false}) =>
      _authService.checkVerification(forceCheck: force);
  static Future<SessionStatus> checkSession() => _authService.checkSession();

  // FCM token methods
  static Future<String?> getFcmToken() => _authService.getStoredFcmToken();
  static Future<bool> updateFcmToken(String token) => _authService.updateFcmToken(token);

  // Session management
  static Future<void> extendSession() => _authService.extendSession();
  static Future<void> refreshUserData() => _authService.refreshUserData();
}