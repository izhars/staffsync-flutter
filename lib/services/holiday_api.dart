import 'dart:convert';
import 'package:http/http.dart' as http;
import '../app/constants.dart';
import 'auth_service.dart';

class HolidayService {
  final String baseUrl = AppConstants.apiBaseUrl;
  final AuthService _authService = AuthService();

  Future<List<Map<String, dynamic>>> fetchHolidays({int? year, int? month}) async {
    final token = await _authService.getToken();

    Map<String, String> queryParams = {};
    if (year != null) queryParams['year'] = year.toString();
    if (month != null) queryParams['month'] = month.toString();

    final uri = Uri.parse('$baseUrl/holidays')
        .replace(queryParameters: queryParams);

    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      final List data = jsonResponse['data'] ?? [];

      return data.map<Map<String, dynamic>>((e) => {
        "id": e['_id'] ?? e['id'] ?? '',
        "name": (e['name'] as String?) ?? 'Holiday',
        "date": DateTime.parse(e['date'] as String),   // keep as DateTime
        "description": (e['description'] as String?) ?? '',
        "type": (e['type'] as String?) ?? 'General',
        "category": (e['category'] as String?) ?? 'Mandatory',
        "isMandatory": e['isMandatory'] == true,
        "isRestricted": e['isRestricted'] == true,
        "maxAllowed": e['maxAllowed'],
        "weekday": (e['weekday'] as String?) ?? '',
        "hasImage": e['hasImage'] == true,
        "imageUrl": e['image'] is Map ? e['image']['url'] : null,
        "imageThumbnail": e['imageThumbnail'],
      }).toList();
    } else {
      throw Exception(
        "Failed to load holidays: ${response.statusCode} - ${response.body}",
      );
    }
  }

  // Fetch upcoming holidays only
  Future<List<Map<String, dynamic>>> fetchUpcomingHolidays() async {
    try {
      final token = await _authService.getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/holidays/upcoming'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final List data = jsonResponse['data'] ?? [];

        return data.map((e) => {
          "id": e['_id'] ?? e['id'] ?? '',
          "name": e['name'] ?? 'Holiday',
          "date": DateTime.parse(e['date'] as String),
          "description": e['description'] ?? "",
          "type": e['type'] ?? "General",
          "category": e['category'] ?? "Mandatory",
          "isMandatory": e['isMandatory'] ?? false,
          "isRestricted": e['isRestricted'] ?? false,
          "maxAllowed": e['maxAllowed'],
          "weekday": e['weekday'] ?? "",
          "hasImage": e['hasImage'] ?? false,
          "imageUrl": e['image'] != null ? e['image']['url'] : null,
          "imageThumbnail": e['imageThumbnail'],
        }).toList();
      } else {
        throw Exception(
          "Failed to load upcoming holidays: ${response.statusCode}",
        );
      }
    } catch (e) {
      print('❌ fetchUpcomingHolidays error: $e');
      rethrow;
    }
  }
}