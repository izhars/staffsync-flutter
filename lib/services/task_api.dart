import 'network_service.dart';
import 'auth_service.dart';

class TaskApi {
  final NetworkService _networkService = NetworkService();
  final AuthService _authService = AuthService();

  // ---------------------------------------------------------
  // 🔐 Get current user ID
  // ---------------------------------------------------------
  Future<String> getCurrentUserId() async {
    try {
      final user = await _authService.getCurrentUser();
      if (user == null) {
        throw Exception('User not authenticated. Please login.');
      }
      return user.id;
    } catch (e) {
      throw Exception('Failed to get current user ID: $e');
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
      return Map<String, dynamic>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch tasks: $e');
    }
  }

  // ---------------------------------------------------------
  // 📌 Get single task by ID with proper error handling
  // ---------------------------------------------------------
  Future<Map<String, dynamic>> getTask(String id) async {
    try {
      final response = await _networkService.get('/tasks/$id');

      // Check if response is valid
      if (response is! Map<String, dynamic>) {
        throw Exception('Invalid response format');
      }

      // Check success flag
      if (response['success'] != true) {
        throw Exception(response['message'] ?? 'Failed to fetch task');
      }

      // Extract data
      final data = response['data'];
      if (data is! Map<String, dynamic>) {
        throw Exception('Invalid data format');
      }

      return data;
    } catch (e) {
      throw Exception('Failed to fetch task: $e');
    }
  }

  // ---------------------------------------------------------
  // ✅ Mark task as complete
  // ---------------------------------------------------------
  Future<Map<String, dynamic>> completeTask(String id) async {
    try {
      final response = await _networkService.post(
        '/tasks/$id/complete',
        {},
      );

      if (response['success'] == true) {
        return response['data'];
      } else {
        throw Exception(response['message'] ?? 'Failed to complete task');
      }
    } catch (e) {
      throw Exception('Failed to complete task: $e');
    }
  }

  // ---------------------------------------------------------
  // 💬 Add comment to task
  // ---------------------------------------------------------
  Future<Map<String, dynamic>> addComment(String id, String text) async {
    try {
      final response = await _networkService.post(
        '/tasks/$id/comments',
        {
          'text': text,  // Only send text, remove userId
        },
      );

      if (response['success'] == true) {
        return response['data']; // this returns the task object with updated comments
      } else {
        throw Exception(response['message'] ?? 'Failed to add comment');
      }
    } catch (e) {
      throw Exception('Failed to add comment: $e');
    }
  }
}