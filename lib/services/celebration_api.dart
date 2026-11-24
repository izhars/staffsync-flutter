// services/celebration_api.dart

import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../app/constants.dart';
import '../models/celebration.dart';
import 'api_exception.dart';
import 'auth_service.dart';

class CelebrationService {
  CelebrationService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  final String baseUrl = AppConstants.apiBaseUrl;
  final AuthService _authService = AuthService();

  static const Duration _timeout = Duration(seconds: 15);

  Future<Map<String, String>> _headers() async {
    final token = await _authService.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  /// Decodes a response or throws [ApiException].
  Map<String, dynamic> _handle(http.Response response) {
    Map<String, dynamic> body;
    try {
      body = json.decode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw ApiException(
        statusCode: response.statusCode,
        message: 'Malformed response from server',
      );
    }

    if (response.statusCode >= 200 && response.statusCode < 300) return body;

    throw ApiException(
      statusCode: response.statusCode,
      message: body['message']?.toString() ??
          body['error']?.toString() ??
          'Something went wrong',
    );
  }

  Future<Map<String, dynamic>> _get(
      String path, Map<String, String> query) async {
    final uri = Uri.parse('$baseUrl$path').replace(queryParameters: query);
    final response =
    await _client.get(uri, headers: await _headers()).timeout(_timeout);
    return _handle(response);
  }

  Future<Map<String, dynamic>> _post(
      String path, Map<String, dynamic> body) async {
    final uri = Uri.parse('$baseUrl$path');
    final response = await _client
        .post(uri, headers: await _headers(), body: json.encode(body))
        .timeout(_timeout);
    return _handle(response);
  }

  Future<Map<String, dynamic>> _patch(String path,
      [Map<String, dynamic>? body]) async {
    final uri = Uri.parse('$baseUrl$path');
    final response = await _client
        .patch(uri,
        headers: await _headers(),
        body: body == null ? null : json.encode(body))
        .timeout(_timeout);
    return _handle(response);
  }

  String _todayIso() {
    final n = DateTime.now();
    final m = n.month.toString().padLeft(2, '0');
    final d = n.day.toString().padLeft(2, '0');
    return '${n.year}-$m-$d';
  }

  // ─────────────────────────────────────────────
  // Celebrations
  // ─────────────────────────────────────────────

  Future<CelebrationResponse> getTodayCelebrations({
    String? date,
    String? department,
    int page = 1,
    int limit = 10,
  }) async {
    final json = await _get('/celebrations/all-today', {
      'page': '$page',
      'limit': '$limit',
      if (date != null) 'date': date,
      if (department != null) 'department': department,
    });
    return CelebrationResponse.fromJson(json);
  }

  Future<UpcomingResponse> getUpcomingCelebrations({
    String? date,
    String? department,
    int upcomingDays = 7,
    int page = 1,
    int limit = 10,
  }) async {
    final json = await _get('/celebrations/all-upcoming', {
      'page': '$page',
      'limit': '$limit',
      'upcomingDays': '$upcomingDays',
      if (date != null) 'date': date,
      if (department != null) 'department': department,
    });
    return UpcomingResponse.fromJson(json);   // ✅ was CelebrationResponse
  }

  Future<CelebrationResponse> getBirthdays({
    String? date,
    String? department,
    bool includeUpcoming = false,
    int upcomingDays = 7,
    int page = 1,
    int limit = 10,
  }) async {
    final json = await _get('/celebrations/birthdays', {
      'page': '$page',
      'limit': '$limit',
      if (date != null) 'date': date,
      if (department != null) 'department': department,
      if (includeUpcoming) 'includeUpcoming': 'true',
      if (includeUpcoming) 'upcomingDays': '$upcomingDays',
    });
    return CelebrationResponse.fromJson(json);
  }

  Future<CelebrationResponse> getMarriageAnniversaries({
    String? date,
    String? department,
    bool includeUpcoming = false,
    int upcomingDays = 7,
    int page = 1,
    int limit = 10,
  }) async {
    final json = await _get('/celebrations/marriage-anniversaries', {
      'page': '$page',
      'limit': '$limit',
      if (date != null) 'date': date,
      if (department != null) 'department': department,
      if (includeUpcoming) 'includeUpcoming': 'true',
      if (includeUpcoming) 'upcomingDays': '$upcomingDays',
    });
    return CelebrationResponse.fromJson(json);
  }

  Future<CelebrationResponse> getWorkAnniversaries({
    String? date,
    String? department,
    bool includeUpcoming = false,
    int upcomingDays = 7,
    int page = 1,
    int limit = 10,
  }) async {
    final json = await _get('/celebrations/work-anniversaries', {
      'page': '$page',
      'limit': '$limit',
      if (date != null) 'date': date,
      if (department != null) 'department': department,
      if (includeUpcoming) 'includeUpcoming': 'true',
      if (includeUpcoming) 'upcomingDays': '$upcomingDays',
    });
    return CelebrationResponse.fromJson(json);
  }

  // ─────────────────────────────────────────────
  // Regards
  // ─────────────────────────────────────────────

  /// POST /celebrations/:employeeId/regards
  /// [celebrationType] must be `birthday` | `marriage` | `work`.
  /// If [celebrationDate] is null, today's date is used.
  Future<RegardItem> sendRegards({
    required String employeeId,
    required String celebrationType,
    required String message,
    String? celebrationDate,
  }) async {
    final date = celebrationDate ?? _todayIso();
    final json = await _post('/celebrations/$employeeId/regards', {
      'celebrationType': celebrationType,
      'celebrationDate': date,
      'message': message.trim(),
    });

    final data = json['data'];
    if (data is Map<String, dynamic>) {
      return RegardItem.fromJson({
        '_id': data['id'],
        'celebrationType': data['celebrationType'],
        'celebrationDate': data['celebrationDate'],
        'message': data['message'],
        'status': data['status'] ?? 'pending',
      });
    }
    throw ApiException(
      statusCode: 500,
      message: 'Unexpected response while sending regards',
    );
  }

  Future<RegardBucket> getMyReceivedRegards(
      {int page = 1, int limit = 20}) async {
    final json = await _get('/celebrations/regards/received', {
      'page': '$page',
      'limit': '$limit',
    });
    return RegardBucket.fromJson(json);
  }

  Future<RegardBucket> getMySentRegards(
      {int page = 1, int limit = 20}) async {
    final json = await _get('/celebrations/regards/sent', {
      'page': '$page',
      'limit': '$limit',
    });
    return RegardBucket.fromJson(json);
  }

  Future<int> getUnreadReceivedCount() async {
    try {
      final bucket = await getMyReceivedRegards(page: 1, limit: 50);
      return bucket.data.where((r) => r.isUnread).length;
    } catch (_) {
      return 0;
    }
  }

  Future<void> markRegardRead(String regardId) async {
    await _patch('/celebrations/regards/$regardId/read');
  }
}