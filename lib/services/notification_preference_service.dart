import 'dart:convert';
import 'package:http/http.dart' as http;
import '../app/constants.dart';
import '../models/notification_preference.dart';
import 'auth_service.dart';

class NotificationPreferenceService {
  final String baseUrl = AppConstants.apiBaseUrl;
  final AuthService _authService = AuthService();

  // ✅ Mount path from server: { path: '/notifications-preferences', router: ... }
  static const String _basePath = '/notifications-preferences';

  Future<Map<String, String>> _getHeaders() async {
    final token = await _authService.getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Not authenticated. Please sign in again.');
    }
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Uri _uri(String path, [Map<String, String>? query]) {
    final uri = Uri.parse('$baseUrl$_basePath$path');
    return query == null ? uri : uri.replace(queryParameters: query);
  }

  String _decodeError(http.Response response) {
    try {
      final body = jsonDecode(response.body);
      if (body is Map && body['message'] is String) {
        return body['message'] as String;
      }
    } catch (_) {}
    return '${response.statusCode} ${response.reasonPhrase ?? ''}'.trim();
  }

  // ── GET /notifications-preferences/preferences ─────────────────

  Future<NotificationPreference> getPreferences() async {
    final url = _uri('/preferences');
    final headers = await _getHeaders();

    try {
      final response = await http
          .get(url, headers: headers)
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
        final data = jsonData['data'];
        if (data is! Map<String, dynamic>) {
          throw Exception('Malformed preferences response');
        }
        return NotificationPreference.fromJson(data);
      }
      throw Exception('Failed to load preferences: ${_decodeError(response)}');
    } on Exception {
      rethrow;
    } catch (e) {
      throw Exception('Error fetching preferences: $e');
    }
  }

  // ── PUT /notifications-preferences/preferences ─────────────────

  Future<NotificationPreference> updatePreferences({
    bool? pushEnabled,
    Map<String, bool>? categories,
    QuietHours? quietHours,
  }) async {
    final body = <String, dynamic>{};
    if (pushEnabled != null) body['pushEnabled'] = pushEnabled;
    if (categories != null) body['categories'] = categories;
    if (quietHours != null) body['quietHours'] = quietHours.toJson();

    if (body.isEmpty) {
      return getPreferences();
    }

    final url = _uri('/preferences');
    final headers = await _getHeaders();

    try {
      final response = await http
          .put(url, headers: headers, body: jsonEncode(body))
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
        final data = jsonData['data'];
        if (data is! Map<String, dynamic>) {
          throw Exception('Malformed update response');
        }
        return NotificationPreference.fromJson(data);
      }
      throw Exception('Failed to update preferences: ${_decodeError(response)}');
    } on Exception {
      rethrow;
    } catch (e) {
      throw Exception('Error updating preferences: $e');
    }
  }


  // ── POST /notifications-preferences/preferences/2fa/setup ──────
  Future<void> request2FASetupCode() async {
    final url = _uri('/preferences/2fa/setup');
    final headers = await _getHeaders();

    try {
      final response = await http
          .post(url, headers: headers)
          .timeout(const Duration(seconds: 20));

      if (response.statusCode != 200) {
        throw Exception('Failed to send 2FA code: ${_decodeError(response)}');
      }
    } on Exception {
      rethrow;
    } catch (e) {
      throw Exception('Error requesting 2FA code: $e');
    }
  }

// ── POST /notifications-preferences/preferences/2fa/enable ─────
  Future<NotificationPreference> enableTwoFactor(String code) async {
    final url = _uri('/preferences/2fa/enable');
    final headers = await _getHeaders();

    try {
      final response = await http
          .post(url, headers: headers, body: jsonEncode({'code': code}))
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
        final data = jsonData['data'];
        if (data is! Map<String, dynamic>) {
          throw Exception('Malformed 2FA enable response');
        }
        return NotificationPreference.fromJson(data);
      }
      throw Exception('Failed to enable 2FA: ${_decodeError(response)}');
    } on Exception {
      rethrow;
    } catch (e) {
      throw Exception('Error enabling 2FA: $e');
    }
  }

// ── POST /notifications-preferences/preferences/2fa/disable/request
  Future<void> request2FADisableCode() async {
    final url = _uri('/preferences/2fa/disable/request');
    final headers = await _getHeaders();

    try {
      final response = await http
          .post(url, headers: headers)
          .timeout(const Duration(seconds: 20));

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to send confirmation code: ${_decodeError(response)}',
        );
      }
    } on Exception {
      rethrow;
    } catch (e) {
      throw Exception('Error requesting confirmation code: $e');
    }
  }

// ── POST /notifications-preferences/preferences/2fa/disable ────
  Future<NotificationPreference> disableTwoFactor(String code) async {
    final url = _uri('/preferences/2fa/disable');
    final headers = await _getHeaders();

    try {
      final response = await http
          .post(url, headers: headers, body: jsonEncode({'code': code}))
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
        final data = jsonData['data'];
        if (data is! Map<String, dynamic>) {
          throw Exception('Malformed 2FA disable response');
        }
        return NotificationPreference.fromJson(data);
      }
      throw Exception('Failed to disable 2FA: ${_decodeError(response)}');
    } on Exception {
      rethrow;
    } catch (e) {
      throw Exception('Error disabling 2FA: $e');
    }
  }

  // ── POST /notifications-preferences/register-token ─────────────

  Future<void> registerToken({
    required String fcmToken,
    String platform = 'unknown',
    String? deviceId,
  }) async {
    final url = _uri('/register-token');
    final headers = await _getHeaders();

    try {
      final response = await http
          .post(
        url,
        headers: headers,
        body: jsonEncode({
          'fcmToken': fcmToken,
          'platform': platform,
          if (deviceId != null) 'deviceId': deviceId,
        }),
      )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Failed to register token: ${_decodeError(response)}');
      }
    } on Exception {
      rethrow;
    } catch (e) {
      throw Exception('Error registering token: $e');
    }
  }

  // ── DELETE /notifications-preferences/unregister-token ─────────

  Future<void> unregisterToken(String fcmToken) async {
    final url = _uri('/unregister-token');
    final headers = await _getHeaders();

    try {
      final response = await http
          .delete(
        url,
        headers: headers,
        body: jsonEncode({'fcmToken': fcmToken}),
      )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Failed to unregister token: ${_decodeError(response)}');
      }
    } on Exception {
      rethrow;
    } catch (e) {
      throw Exception('Error unregistering token: $e');
    }
  }

  // ── GET /notifications-preferences/history ─────────────────────

  Future<NotificationHistoryResponse> getHistory({
    int page = 1,
    int limit = 20,
    String? category,
    bool? unreadOnly,
  }) async {
    final query = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
      if (category != null && category.isNotEmpty) 'category': category,
      if (unreadOnly == true) 'unread': 'true',
    };

    final url = _uri('/history', query);
    final headers = await _getHeaders();

    try {
      final response = await http
          .get(url, headers: headers)
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
        final data = jsonData['data'];
        if (data is! Map<String, dynamic>) {
          return NotificationHistoryResponse(
            items: const [],
            pagination: Pagination(
              page: page,
              limit: limit,
              total: 0,
              totalPages: 1,
            ),
            unreadCount: 0,
          );
        }
        return NotificationHistoryResponse.fromJson(data);
      }
      throw Exception('Failed to load history: ${_decodeError(response)}');
    } on Exception {
      rethrow;
    } catch (e) {
      throw Exception('Error fetching history: $e');
    }
  }

  // ── PATCH /notifications-preferences/:id/read ──────────────────

  Future<void> markAsRead(String id) async {
    final url = _uri('/$id/read');
    final headers = await _getHeaders();

    try {
      final response = await http
          .patch(url, headers: headers)
          .timeout(const Duration(seconds: 20));

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception(
          'Failed to mark notification read: ${_decodeError(response)}',
        );
      }
    } on Exception {
      rethrow;
    } catch (e) {
      throw Exception('Error marking notification read: $e');
    }
  }

  // ── PATCH /notifications-preferences/read-all ──────────────────

  Future<int?> markAllAsRead() async {
    final url = _uri('/read-all');
    final headers = await _getHeaders();

    try {
      final response = await http
          .patch(url, headers: headers)
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final modified = (body['modified'] as num?)?.toInt() ??
            ((body['data'] is Map<String, dynamic>)
                ? ((body['data'] as Map<String, dynamic>)['modified'] as num?)
                ?.toInt()
                : null);
        return modified ?? 0;
      }
      throw Exception('Failed to mark all as read: ${_decodeError(response)}');
    } on Exception {
      rethrow;
    } catch (e) {
      throw Exception('Error marking all as read: $e');
    }
  }
}

// ─────────────────────────────────────────────────────────────────
// Response models — unchanged
// ─────────────────────────────────────────────────────────────────

class NotificationHistoryResponse {
  final List<NotificationHistoryItem> items;
  final Pagination pagination;
  final int unreadCount;

  const NotificationHistoryResponse({
    required this.items,
    required this.pagination,
    required this.unreadCount,
  });

  factory NotificationHistoryResponse.fromJson(Map<String, dynamic> json) {
    return NotificationHistoryResponse(
      items: (json['items'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(NotificationHistoryItem.fromJson)
          .toList(growable: false),
      pagination: Pagination.fromJson(
        (json['pagination'] as Map<String, dynamic>?) ?? const {},
      ),
      unreadCount: (json['unreadCount'] as num?)?.toInt() ?? 0,
    );
  }
}

class Pagination {
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  const Pagination({
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  factory Pagination.fromJson(Map<String, dynamic> json) => Pagination(
    page: (json['page'] as num?)?.toInt() ?? 1,
    limit: (json['limit'] as num?)?.toInt() ?? 20,
    total: (json['total'] as num?)?.toInt() ?? 0,
    totalPages: (json['totalPages'] as num?)?.toInt() ?? 1,
  );
}