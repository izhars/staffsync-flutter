// quote_service.dart (updated with new function for listing quotes)
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/quote.dart';

class QuoteService {
  static const String _baseUrl = 'https://favqs.com/api';
  static const String _apiToken = '65150caea3a17b62165ba6c86389d72b';

  /// Fetches the Quote of the Day (no token required)
  Future<Quote> fetchRandomQuote() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/qotd'),
      headers: {
        'Authorization': 'Token token="$_apiToken"',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return Quote.fromJson(data['quote']); // 👈 THIS is the fix
    } else {
      throw Exception('Failed to fetch quote: ${response.statusCode}');
    }
  }

  // quote_service.dart (add this method)
  Future<Map<String, dynamic>> fetchQuotesByAuthor({
    required String author,
    int page = 1,
  }) async {
    final uri = Uri.parse('$_baseUrl/quotes').replace(
      queryParameters: {
        'filter': author,
        'type': 'author',
        'page': page.toString(),
      },
    );

    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Token token="$_apiToken"',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to fetch quotes by author: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> fetchActivities({
    String type = 'author', // 'author' or 'tag'
    required String filter,
    int page = 1,
  }) async {
    final uri = Uri.parse('$_baseUrl/activities/').replace(
      queryParameters: {
        'type': type,
        'filter': filter,
        'page': page.toString(),
      },
    );

    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Token token="$_apiToken"',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to fetch activities: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> fetchQuotes({
    String? filter,
    String? type,
    int page = 1,
  }) async {
    final uri = Uri.parse('$_baseUrl/quotes').replace(
      queryParameters: {
        if (filter != null) 'filter': filter,
        if (type != null) 'type': type,
        'page': page.toString(),
      },
    );

    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Token token="$_apiToken"',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to fetch quotes: ${response.statusCode}');
    }
  }
}