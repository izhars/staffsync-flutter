import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../app/constants.dart';
import 'api_exception.dart';
import 'auth_service.dart';

class NetworkService {
  final String baseUrl = AppConstants.apiBaseUrl;
  final _authService = AuthService();

  // ---------------------------------------------------------
  // 🔥 UNIVERSAL RETRY WRAPPER
  // ---------------------------------------------------------
  Future<T> retry<T>(
      Future<T> Function() fn, {
        int retries = AppConstants.maxRetries,
        Duration initialDelay = const Duration(milliseconds: 600),
      }) async {
    int attempt = 0;
    Duration delay = initialDelay;

    while (true) {
      try {
        return await fn();
      } catch (e) {
        if (attempt >= retries) rethrow;

        await Future.delayed(delay);
        delay *= 2;
        attempt++;
      }
    }
  }


  // Add this new method to NetworkService class
  Future<dynamic> uploadFileWithMethod(
      String endpoint,
      String filePath,
      Map<String, String> fields,
      String fileFieldName,
      String method, // 'POST', 'PUT', 'PATCH'
      ) async {
    return retry(() async {
      final uri = Uri.parse('$baseUrl$endpoint');
      final request = http.MultipartRequest(method, uri); // Use dynamic method

      // Get auth token
      final token = await _authService.getToken();

      // Add auth header if token exists
      if (token != null && token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      // Add file with correct field name
      final file = File(filePath);
      if (await file.exists()) {
        final fileStream = http.ByteStream(file.openRead());
        final fileLength = await file.length();
        final fileName = filePath.split('/').last;
        final fileExtension = fileName.split('.').last.toLowerCase();

        // Determine MIME type based on file extension
        String mimeType;
        switch (fileExtension) {
          case 'jpg':
          case 'jpeg':
            mimeType = 'image/jpeg';
            break;
          case 'png':
            mimeType = 'image/png';
            break;
          case 'gif':
            mimeType = 'image/gif';
            break;
          case 'webp':
            mimeType = 'image/webp';
            break;
          case 'pdf':
            mimeType = 'application/pdf';
            break;
          case 'doc':
            mimeType = 'application/msword';
            break;
          case 'docx':
            mimeType = 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
            break;
          case 'txt':
            mimeType = 'text/plain';
            break;
          default:
            mimeType = 'application/octet-stream';
        }

        final multipartFile = http.MultipartFile(
          fileFieldName,
          fileStream,
          fileLength,
          filename: fileName,
          contentType: MediaType.parse(mimeType),
        );

        request.files.add(multipartFile);
      } else {
        throw Exception('File does not exist: $filePath');
      }

      // Add other fields as form fields
      fields.forEach((key, value) {
        request.fields[key] = value;
        print('[NetworkService] Added field: $key = $value');
      });

      // Add type field for upload middleware
      if (!fields.containsKey('type')) {
        request.fields['type'] = 'expense';
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      // Handle response
      if (response.statusCode >= 200 && response.statusCode < 300) {
        try {
          return jsonDecode(response.body);
        } catch (e) {
          throw ApiException(
            statusCode: response.statusCode,
            message: 'Failed to parse response',
          );
        }
      } else {
        String errorMessage;
        try {
          final errorJson = jsonDecode(response.body);
          errorMessage = errorJson['message'] ?? 'File upload failed';
        } catch (_) {
          errorMessage = 'File upload failed (${response.statusCode})';
        }
        throw ApiException(
          statusCode: response.statusCode,
          message: errorMessage,
        );
      }
    });
  }

  // ---------------------------------------------------------
  // 🔥 FIXED MULTIPART / FILE UPLOAD SUPPORT
  // ---------------------------------------------------------
  Future<dynamic> uploadFile(
      String endpoint,
      String filePath,
      Map<String, String> fields,
      String fileFieldName,
      ) async {
    return retry(() async {
      final uri = Uri.parse('$baseUrl$endpoint');
      final request = http.MultipartRequest('POST', uri);

      // Get auth token
      final token = await _authService.getToken();

      // Add auth header if token exists
      if (token != null && token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      // Add file with correct field name
      final file = File(filePath);
      if (await file.exists()) {
        final fileStream = http.ByteStream(file.openRead());
        final fileLength = await file.length();
        final fileName = filePath.split('/').last;
        final fileExtension = fileName.split('.').last.toLowerCase();

        // Determine MIME type based on file extension
        String mimeType;
        switch (fileExtension) {
          case 'jpg':
          case 'jpeg':
            mimeType = 'image/jpeg';
            break;
          case 'png':
            mimeType = 'image/png';
            break;
          case 'gif':
            mimeType = 'image/gif';
            break;
          case 'webp':
            mimeType = 'image/webp';
            break;
          case 'pdf':
            mimeType = 'application/pdf';
            break;
          case 'doc':
            mimeType = 'application/msword';
            break;
          case 'docx':
            mimeType = 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
            break;
          case 'txt':
            mimeType = 'text/plain';
            break;
          default:
            mimeType = 'application/octet-stream';
        }

        final multipartFile = http.MultipartFile(
          fileFieldName,
          fileStream,
          fileLength,
          filename: fileName,
          contentType: MediaType.parse(mimeType), // Set proper content type
        );

        request.files.add(multipartFile);
      } else {
        throw Exception('File does not exist: $filePath');
      }

      // Add other fields as form fields
      fields.forEach((key, value) {
        request.fields[key] = value;
        print('[NetworkService] Added field: $key = $value');
      });

      // Add type field for upload middleware
      if (!fields.containsKey('type')) {
        request.fields['type'] = 'expense'; // Ensure type is set
      }

      // Send request
      print('[NetworkService] Sending multipart request to: $uri');
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('[NetworkService] Response status: ${response.statusCode}');
      print('[NetworkService] Response body: ${response.body}');

      // Handle response
      if (response.statusCode >= 200 && response.statusCode < 300) {
        try {
          return jsonDecode(response.body);
        } catch (e) {
          throw ApiException(
            statusCode: response.statusCode,
            message: 'Failed to parse response',
          );
        }
      } else {
        String errorMessage;
        try {
          final errorJson = jsonDecode(response.body);
          errorMessage = errorJson['message'] ?? 'File upload failed';
        } catch (_) {
          errorMessage = 'File upload failed (${response.statusCode})';
        }
        throw ApiException(
          statusCode: response.statusCode,
          message: errorMessage,
        );
      }
    });
  }

  // ---------------------------------------------------------
  // 🔥 GET AUTH HEADERS
  // ---------------------------------------------------------
  Future<Map<String, String>> _headers() async {
    final token = await _authService.getToken();

    return {
      HttpHeaders.contentTypeHeader: 'application/json',
      if (token != null && token.isNotEmpty)
        HttpHeaders.authorizationHeader: 'Bearer $token',
    };
  }

  // ---------------------------------------------------------
  // 🔥 CORE REQUEST HANDLER (ApiException integrated)
  // ---------------------------------------------------------
  Future<dynamic> _handleRequest(Future<http.Response> Function() requestFn) async {
    try {
      final response = await requestFn().timeout(AppConstants.apiTimeout);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body);
      }

      throw ApiException(
        statusCode: response.statusCode,
        message: _extractErrorMessage(response),
      );
    } on SocketException {
      throw ApiException(statusCode: 0, message: "No internet connection");
    } on TimeoutException {
      throw ApiException(statusCode: 0, message: "Request timed out");
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(statusCode: 0, message: "Unexpected error: $e");
    }
  }


  // ---------------------------------------------------------
  // 🔥 Extract server error message safely
  // ---------------------------------------------------------
  String _extractErrorMessage(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);
      return decoded['message'] ?? "Something went wrong";
    } catch (_) {
      return "Something went wrong (${response.statusCode})";
    }
  }

  // ---------------------------------------------------------
  // 🔥 PUBLIC METHODS (GET/POST/PUT/DELETE)
  // ---------------------------------------------------------
  // ── GET with optional query params ────────────────────────
  Future<dynamic> get(
      String endpoint, {
        Map<String, String>? query,
      }) async {
    return retry(() async {
      final headers = await _headers();
      Uri uri = Uri.parse('$baseUrl$endpoint');
      if (query != null && query.isNotEmpty) {
        uri = uri.replace(queryParameters: {
          ...uri.queryParameters,
          ...query,
        });
      }
      return _handleRequest(() => http.get(uri, headers: headers));
    });
  }

  Future<dynamic> getWithParams(String endpoint, {Map<String, String>? params}) async {
    return retry(() async {
      final headers = await _headers();
      // Build full URL with query parameters if provided
      Uri uri = Uri.parse('$baseUrl$endpoint');
      if (params != null && params.isNotEmpty) {
        uri = uri.replace(queryParameters: params);
      }
      return _handleRequest(() {
        return http.get(uri, headers: headers);
      });
    });
  }


  Future<dynamic> patch(String endpoint, Map<String, dynamic> body) async {
    return retry(() async {
      final headers = await _headers();
      return _handleRequest(() {
        return http.patch(
          Uri.parse('$baseUrl$endpoint'),
          headers: headers,
          body: jsonEncode(body),
        );
      });
    });
  }

  Future<dynamic> post(String endpoint, Map<String, dynamic> body) async {
    return retry(() async {
      final headers = await _headers();
      return _handleRequest(() {
        return http.post(
          Uri.parse('$baseUrl$endpoint'),
          headers: headers,
          body: jsonEncode(body),
        );
      });
    });
  }

  Future<dynamic> put(String endpoint, Map<String, dynamic> body) async {
    return retry(() async {
      final headers = await _headers();
      return _handleRequest(() {
        return http.put(
          Uri.parse('$baseUrl$endpoint'),
          headers: headers,
          body: jsonEncode(body),
        );
      });
    });
  }

  Future<dynamic> delete(
      String endpoint, {
        Map<String, dynamic>? body,
      }) async {
    return retry(() async {
      final headers = await _headers();
      return _handleRequest(() {
        return http.delete(
          Uri.parse('$baseUrl$endpoint'),
          headers: headers,
          body: body != null ? jsonEncode(body) : null,
        );
      });
    });
  }

  Future<dynamic> deleteFace(String endpoint, [Map<String, dynamic>? body]) async {
    return retry(() async {
      final headers = await _headers();
      return _handleRequest(() {
        return http.delete(
          Uri.parse('$baseUrl$endpoint'),
          headers: headers,
          body: body != null ? jsonEncode(body) : null,
        );
      });
    });
  }
}