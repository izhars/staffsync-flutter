class AppNotification {
  final String id;
  final String title;
  final String message;
  final String type;
  late final bool read;
  final DateTime createdAt;
  final Map<String, dynamic> meta;

  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.read,
    required this.createdAt,
    required this.meta,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['_id'],
      title: json['title'],
      message: json['message'],
      type: json['type'],
      read: json['read'],
      createdAt: DateTime.parse(json['createdAt']),
      meta: json['meta'] ?? {},
    );
  }
}
