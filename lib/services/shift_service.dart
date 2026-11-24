// lib/services/shift_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../app/constants.dart';
import '../models/shift.dart';
import 'auth_service.dart';

class ShiftService {
  final String baseUrl = AppConstants.apiBaseUrl;
  final AuthService _authService = AuthService();

  // ✅ Mount path from server: { path: '/shifts', router: ... }
  static const String _basePath = '/shifts';

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

  // ── GET /shifts/my-shift ───────────────────────────────────────

  Future<MyShiftResponse?> getMyShift() async {
    final url = _uri('/my-shift');
    final headers = await _getHeaders();

    try {
      final response = await http
          .get(url, headers: headers)
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
        final data = jsonData['data'];
        if (data is! Map<String, dynamic>) {
          return null; // no shift assigned
        }
        return MyShiftResponse.fromJson(data);
      }
      if (response.statusCode == 404) return null; // no shift assigned
      throw Exception('Failed to load shift: ${_decodeError(response)}');
    } on Exception {
      rethrow;
    } catch (e) {
      throw Exception('Error fetching shift: $e');
    }
  }
}