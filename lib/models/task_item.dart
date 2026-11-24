// lib/models/TaskItem.dart
enum TaskCategory {
  development,
  meeting,
  testing,
  documentation,
  research,
  support,
  other,
}

enum TaskStatus { draft, submitted, approved }

class TaskItem {
  final String title;
  final String description;
  final String project;
  final int timeSpent;
  final TaskCategory category;

  TaskItem({
    required this.title,
    this.description = '',
    this.project = '',
    required this.timeSpent,
    required this.category,
  });

  factory TaskItem.fromJson(Map<String, dynamic> json) => TaskItem(
    title: json['title']?.toString() ?? '',
    description: json['description']?.toString() ?? '',
    project: json['project']?.toString() ?? '',
    timeSpent: (json['timeSpent'] as num?)?.toInt() ?? 0,
    category: _categoryFromString(json['category']?.toString()),
  );

  Map<String, dynamic> toJson() => {
    'title': title,
    'description': description,
    'project': project,
    'timeSpent': timeSpent,
    'category': category.name,
  };

  TaskItem copyWith({
    String? title,
    String? description,
    String? project,
    int? timeSpent,
    TaskCategory? category,
  }) =>
      TaskItem(
        title: title ?? this.title,
        description: description ?? this.description,
        project: project ?? this.project,
        timeSpent: timeSpent ?? this.timeSpent,
        category: category ?? this.category,
      );

  static TaskCategory _categoryFromString(String? s) {
    return TaskCategory.values.firstWhere(
          (e) => e.name == s,
      orElse: () => TaskCategory.development,
    );
  }
}

class TaskResponse {
  final DailyTaskEntry? data;
  final String message;

  TaskResponse({required this.data, required this.message});
}

class DailyTaskEntry {
  final String id;
  final List<TaskItem> tasks;
  final String? notes;
  final TaskStatus status;
  final int totalTime;
  final DateTime date;

  DailyTaskEntry({
    required this.id,
    required this.tasks,
    required this.notes,
    required this.status,
    required this.totalTime,
    required this.date,
  });

  factory DailyTaskEntry.fromJson(Map<String, dynamic> json) {
    return DailyTaskEntry(
      id: json['_id'] ?? json['id'] ?? '',
      tasks: (json['tasks'] as List<dynamic>? ?? [])
          .map((t) => TaskItem.fromJson(t as Map<String, dynamic>))
          .toList(),
      notes: json['notes'] as String?,
      status: _parseStatus(json['status'] as String?),
      totalTime: (json['totalTime'] as num?)?.toInt() ?? 0,
      date: DateTime.tryParse(json['date']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}

TaskStatus _parseStatus(String? s) {
  switch (s) {
    case 'submitted':
      return TaskStatus.submitted;
    case 'approved':
      return TaskStatus.approved;
    case 'draft':
    default:
      return TaskStatus.draft;
  }
}

class WeeklySummary {
  final List<WeeklyDay> days;
  final int totalWeeklyTime;
  final double averageDailyTime;

  WeeklySummary({
    required this.days,
    required this.totalWeeklyTime,
    required this.averageDailyTime,
  });

  factory WeeklySummary.fromJson(Map<String, dynamic> json) {
    return WeeklySummary(
      days: (json['days'] as List<dynamic>? ?? [])
          .map((d) => WeeklyDay.fromJson(d as Map<String, dynamic>))
          .toList(),
      totalWeeklyTime: (json['totalWeeklyTime'] as num?)?.toInt() ?? 0,
      averageDailyTime:
      (json['averageDailyTime'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class WeeklyDay {
  final String date;
  final int totalTime;
  final int taskCount;

  WeeklyDay({
    required this.date,
    required this.totalTime,
    required this.taskCount,
  });

  factory WeeklyDay.fromJson(Map<String, dynamic> json) => WeeklyDay(
    date: json['_id']?.toString() ?? '',
    totalTime: (json['totalTime'] as num?)?.toInt() ?? 0,
    taskCount: (json['taskCount'] as num?)?.toInt() ?? 0,
  );
}
