import '../models/AppNotification.dart';
import 'network_service.dart';

class LocalNotificationService {
  final NetworkService _network = NetworkService();

  Future<List<AppNotification>> fetchMyNotifications() async {
    try {
      final response = await _network.get('/notifications/me');

      // Handle the response structure with pagination
      if (response is Map<String, dynamic> && response.containsKey('data')) {
        final List<dynamic> list = response['data'];

        // Check if there are notifications
        if (list.isEmpty) {
          return [];
        }

        return list
            .map((json) => AppNotification.fromJson(json))
            .toList();
      } else {
        throw Exception('Invalid response format: Expected data field');
      }
    } catch (e) {
      // Re-throw the error to be handled by UI
      rethrow;
    }
  }

  // Mark a single notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _network.patch(
        '/notifications/$notificationId/read',
        {},
      );
    } catch (e) {
      rethrow;
    }
  }

  // Mark all notifications as read
  Future<void> markAllAsRead() async {
    try {
      await _network.patch(
        '/notifications/me/read-all',
        {},
      );
    } catch (e) {
      rethrow;
    }
  }

  // Delete a notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _network.delete('/notifications/$notificationId');
    } catch (e) {
      rethrow;
    }
  }

  // Delete all notifications
  Future<void> deleteAllNotifications() async {
    try {
      await _network.delete('/notifications/me');
    } catch (e) {
      rethrow;
    }
  }

  // Get unread count
  Future<int> getUnreadCount() async {
    try {
      final response = await _network.get('/notifications/me/unread-count');

      if (response is Map<String, dynamic> && response.containsKey('count')) {
        return response['count'] as int;
      }

      return 0;
    } catch (e) {
      // If error occurs, return 0 so UI doesn't break
      return 0;
    }
  }
}