import '../models/app_notification.dart';
import 'network_service.dart';

class LocalNotificationService {
  final NetworkService _network = NetworkService();

  // ── Fetch list ────────────────────────────────────────────
  Future<List<AppNotification>> fetchMyNotifications({
    int page = 1,
    int limit = 50,
    String? type,
    bool? read,
  }) async {
    final query = <String, String>{
      'page': '$page',
      'limit': '$limit',
    };
    if (type != null) query['type'] = type;
    if (read != null) query['read'] = '$read';

    final response = await _network.get('/notifications/me', query: query);

    if (response is Map<String, dynamic> && response['data'] is List) {
      final list = response['data'] as List;
      return list
          .whereType<Map>()
          .map((e) => AppNotification.fromJson(
        e.map((k, v) => MapEntry(k.toString(), v)),
      ))
          .where((n) => n.id.isNotEmpty)
          .toList();
    }
    return <AppNotification>[];
  }

  // ── Single mark read ──────────────────────────────────────
  Future<void> markAsRead(String notificationId) async {
    if (notificationId.isEmpty) return;
    await _network.patch('/notifications/$notificationId/read', {});
  }

  // ── Mark all read ─────────────────────────────────────────
  Future<Map<String, dynamic>> markAllAsRead() async {
    final response = await _network.patch('/notifications/read-all', {});
    if (response is Map<String, dynamic>) {
      return response;
    }
    return {'success': true};
  }

  // ── Delete one ────────────────────────────────────────────
  Future<void> deleteNotification(String notificationId) async {
    if (notificationId.isEmpty) return;
    await _network.delete('/notifications/$notificationId');
  }

  // ── Delete many ───────────────────────────────────────────
  Future<void> deleteMultiple(List<String> ids) async {
    if (ids.isEmpty) return;
    await _network.delete('/notifications', body: {'ids': ids});
  }

  // ── Delete all (clear) ────────────────────────────────────
  Future<void> deleteAllNotifications() async {
    await _network.delete('/notifications/clear-all');
  }

  // ── Unread count ──────────────────────────────────────────
  Future<int> getUnreadCount() async {
    try {
      final response = await _network.get('/notifications/counts');
      if (response is Map<String, dynamic>) {
        final counts = response['counts'];
        if (counts is Map && counts['unread'] != null) {
          return (counts['unread'] as num).toInt();
        }
        // Fallback: some backends return { count: N }
        if (response['count'] != null) {
          return (response['count'] as num).toInt();
        }
      }
      return 0;
    } catch (_) {
      // Never crash the UI on a count fetch.
      return 0;
    }
  }

  // ── Detailed counts ───────────────────────────────────────
  Future<Map<String, int>> getCounts() async {
    try {
      final response = await _network.get('/notifications/counts');
      if (response is Map<String, dynamic> &&
          response['counts'] is Map<String, dynamic>) {
        final c = response['counts'] as Map<String, dynamic>;
        return {
          'total':  (c['total']  as num?)?.toInt() ?? 0,
          'unread': (c['unread'] as num?)?.toInt() ?? 0,
          'read':   (c['read']   as num?)?.toInt() ?? 0,
        };
      }
    } catch (_) {}
    return {'total': 0, 'unread': 0, 'read': 0};
  }
}