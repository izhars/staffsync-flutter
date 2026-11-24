// lib/services/TaskService.dart
import '../models/task_item.dart';
import 'network_service.dart';

class TaskService {
  final NetworkService _network = NetworkService();

  // ─────────────────────────────────────────────────────────
  // GET /api/tasks/today
  // ─────────────────────────────────────────────────────────
  Future<TaskResponse> getTodayTask() async {
    final res = await _network.get('/daily-tasks/today');
    final map = res as Map<String, dynamic>;
    final data = map['data'];
    return TaskResponse(
      data: data == null
          ? null
          : DailyTaskEntry.fromJson(data as Map<String, dynamic>),
      message: map['message']?.toString() ?? '',
    );
  }

  // ─────────────────────────────────────────────────────────
  // POST /api/tasks  → submit
  // ─────────────────────────────────────────────────────────
  Future<TaskResponse> submitDailyTasks({
    required List<TaskItem> tasks,
    required String notes,
  }) async {
    final res = await _network.post('/daily-tasks', {
      'tasks': tasks.map((t) => t.toJson()).toList(),
      'notes': notes,
    });
    final map = res as Map<String, dynamic>;
    return TaskResponse(
      data: DailyTaskEntry.fromJson(map['data'] as Map<String, dynamic>),
      message: map['message']?.toString() ?? '',
    );
  }

  // ─────────────────────────────────────────────────────────
  // POST /api/tasks/draft  → save as draft
  // ─────────────────────────────────────────────────────────
  Future<TaskResponse> saveAsDraft({
    required List<TaskItem> tasks,
    required String notes,
  }) async {
    final res = await _network.post('/daily-tasks/draft', {
      'tasks': tasks.map((t) => t.toJson()).toList(),
      'notes': notes,
    });
    final map = res as Map<String, dynamic>;
    return TaskResponse(
      data: DailyTaskEntry.fromJson(map['data'] as Map<String, dynamic>),
      message: map['message']?.toString() ?? '',
    );
  }

  // ─────────────────────────────────────────────────────────
  // GET /api/tasks?from=&to=
  // ─────────────────────────────────────────────────────────
  Future<List<DailyTaskEntry>> getTasksByDateRange({
    required DateTime from,
    required DateTime to,
  }) async {
    final res = await _network.get('/daily-tasks', query: {
      'from': from.toIso8601String(),
      'to': to.toIso8601String(),
    });
    final map = res as Map<String, dynamic>;
    final list = map['data'] as List<dynamic>? ?? [];
    return list
        .map((e) => DailyTaskEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ─────────────────────────────────────────────────────────
  // GET /api/tasks/summary/weekly
  // ─────────────────────────────────────────────────────────
  Future<WeeklySummary> getWeeklySummary() async {
    final res = await _network.get('/daily-tasks/summary/weekly');
    final map = res as Map<String, dynamic>;
    return WeeklySummary.fromJson(map['data'] as Map<String, dynamic>);
  }

  // ─────────────────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────────────────
  static int calculateTotalTime(List<TaskItem> tasks) =>
      tasks.fold(0, (sum, t) => sum + t.timeSpent);

  static String formatMinutes(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (h > 0) return m > 0 ? '${h}h ${m}m' : '${h}h';
    return '${m}m';
  }
}