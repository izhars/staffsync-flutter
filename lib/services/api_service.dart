import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../app/constants.dart';

class ApiService {
  static const String baseUrl = AppConstants.apiBaseUrl;
  static const Duration timeout = AppConstants.apiTimeout;
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  Future<Map<String, String>> _getHeaders(Map<String, String>? headers) async {
    final orgCode = await _storage.read(key: 'organization_code');
    return {
      'Content-Type': 'application/json',
      if (orgCode != null && orgCode.isNotEmpty) 'x-organization-code': orgCode,
      ...?headers,
    };
  }

  Future<Map<String, dynamic>> get(String endpoint, {Map<String, String>? headers}) async {
    try {
      final reqHeaders = await _getHeaders(headers);
      final response = await http.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: reqHeaders,
      ).timeout(timeout);

      return _handleResponse(response);
    } catch (e) {
      throw Exception('Failed to fetch data: $e');
    }
  }

  Future<Map<String, dynamic>> post(String endpoint, dynamic data, {Map<String, String>? headers}) async {
    try {
      final reqHeaders = await _getHeaders(headers);
      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: reqHeaders,
        body: jsonEncode(data),
      ).timeout(timeout);

      return _handleResponse(response);
    } catch (e) {
      throw Exception('Failed to post data: $e');
    }
  }

  Future<Map<String, dynamic>> put(String endpoint, dynamic data, {Map<String, String>? headers}) async {
    try {
      final reqHeaders = await _getHeaders(headers);
      final response = await http.put(
        Uri.parse('$baseUrl$endpoint'),
        headers: reqHeaders,
        body: jsonEncode(data),
      ).timeout(timeout);

      return _handleResponse(response);
    } catch (e) {
      throw Exception('Failed to update data: $e');
    }
  }

  Future<Map<String, dynamic>> delete(String endpoint, {Map<String, String>? headers}) async {
    try {
      final reqHeaders = await _getHeaders(headers);
      final response = await http.delete(
        Uri.parse('$baseUrl$endpoint'),
        headers: reqHeaders,
      ).timeout(timeout);

      return _handleResponse(response);
    } catch (e) {
      throw Exception('Failed to delete data: $e');
    }
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    final responseData = jsonDecode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return {'success': true, 'data': responseData};
    } else {
      throw Exception(responseData['message'] ?? 'Request failed with status: ${response.statusCode}');
    }
  }

}