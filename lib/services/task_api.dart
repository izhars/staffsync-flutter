import 'network_service.dart';
import 'auth_service.dart';

/// Typed exception so the UI can distinguish error kinds.
class TaskApiException implements Exception {
  final String message;
  final int? statusCode;

  TaskApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class TaskApi {
  final NetworkService _networkService;
  final AuthService _authService;

  TaskApi({NetworkService? networkService, AuthService? authService})
      : _networkService = networkService ?? NetworkService(),
        _authService = authService ?? AuthService();

  // ---------------------------------------------------------
  // 🔐 Get current user ID
  // ---------------------------------------------------------
  Future<String> getCurrentUserId() async {
    try {
      final user = await _authService.getCurrentUser();
      if (user == null) {
        throw TaskApiException('User not authenticated. Please login.');
      }
      return user.id;
    } on TaskApiException {
      rethrow;
    } catch (e) {
      throw TaskApiException('Failed to get current user ID: $e');
    }
  }

  // ---------------------------------------------------------
  // 📋 Get my tasks
  // ---------------------------------------------------------
  Future<Map<String, dynamic>> getMyTasks({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _networkService.get(
        '/tasks?page=$page&limit=$limit',
      );

      if (response is! Map) {
        throw TaskApiException('Invalid response format');
      }
      return Map<String, dynamic>.from(response);
    } on TaskApiException {
      rethrow;
    } catch (e) {
      throw TaskApiException('Failed to fetch tasks: $e');
    }
  }

  // ---------------------------------------------------------
  // 📌 Get single task by ID
  // ---------------------------------------------------------
  Future<Map<String, dynamic>> getTask(String id) async {
    try {
      final response = await _networkService.get('/tasks/$id');

      if (response is! Map) {
        throw TaskApiException('Invalid response format');
      }

      final map = Map<String, dynamic>.from(response);

      if (map['success'] != true) {
        throw TaskApiException(map['message']?.toString() ?? 'Failed to fetch task');
      }

      final data = map['data'];
      if (data is! Map) {
        throw TaskApiException('Invalid data format');
      }

      return Map<String, dynamic>.from(data);
    } on TaskApiException {
      rethrow;
    } catch (e) {
      throw TaskApiException('Failed to fetch task: $e');
    }
  }

  // ---------------------------------------------------------
  // ✅ Mark task as complete
  // ---------------------------------------------------------
  Future<Map<String, dynamic>> completeTask(String id) async {
    try {
      final response = await _networkService.post('/tasks/$id/complete', {});

      if (response is! Map) {
        throw TaskApiException('Invalid response format');
      }

      final map = Map<String, dynamic>.from(response);

      if (map['success'] != true) {
        throw TaskApiException(map['message']?.toString() ?? 'Failed to complete task');
      }

      final data = map['data'];
      if (data is! Map) {
        throw TaskApiException('Invalid data format');
      }

      return Map<String, dynamic>.from(data);
    } on TaskApiException {
      rethrow;
    } catch (e) {
      throw TaskApiException('Failed to complete task: $e');
    }
  }

  // ---------------------------------------------------------
  // 💬 Add comment to task
  // ---------------------------------------------------------
  Future<Map<String, dynamic>> addComment(String id, String text) async {
    try {
      final response = await _networkService.post(
        '/tasks/$id/comments',
        {'text': text},
      );

      if (response is! Map) {
        throw TaskApiException('Invalid response format');
      }

      final map = Map<String, dynamic>.from(response);

      if (map['success'] != true) {
        throw TaskApiException(map['message']?.toString() ?? 'Failed to add comment');
      }

      final data = map['data'];
      if (data is! Map) {
        throw TaskApiException('Invalid data format');
      }

      return Map<String, dynamic>.from(data);
    } on TaskApiException {
      rethrow;
    } catch (e) {
      throw TaskApiException('Failed to add comment: $e');
    }
  }
}