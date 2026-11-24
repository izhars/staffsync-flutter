class NotificationPreference {
  final bool pushEnabled;
  final Map<String, bool> categories;
  final QuietHours quietHours;
  final TwoFactorSecurity security;

  const NotificationPreference({
    required this.pushEnabled,
    required this.categories,
    required this.quietHours,
    required this.security,
  });

  factory NotificationPreference.fromJson(Map<String, dynamic> json) {
    return NotificationPreference(
      pushEnabled: json['pushEnabled'] as bool? ?? true,
      categories: ((json['categories'] as Map<String, dynamic>?) ?? const {})
          .map((k, v) => MapEntry(k, v == true)),
      quietHours: QuietHours.fromJson(
        (json['quietHours'] as Map<String, dynamic>?) ?? const {},
      ),
      security: TwoFactorSecurity.fromJson(
        (json['security'] as Map<String, dynamic>?) ?? const {},
      ),
    );
  }

  NotificationPreference copyWith({
    bool? pushEnabled,
    Map<String, bool>? categories,
    QuietHours? quietHours,
    TwoFactorSecurity? security,
  }) {
    return NotificationPreference(
      pushEnabled: pushEnabled ?? this.pushEnabled,
      categories: categories ?? this.categories,
      quietHours: quietHours ?? this.quietHours,
      security: security ?? this.security,
    );
  }
}


class TwoFactorSecurity {
  final bool twoFactorEnabled;
  final String twoFactorMethod;
  final DateTime? twoFactorEnabledAt;

  const TwoFactorSecurity({
    required this.twoFactorEnabled,
    required this.twoFactorMethod,
    this.twoFactorEnabledAt,
  });

  factory TwoFactorSecurity.fromJson(Map<String, dynamic> json) {
    return TwoFactorSecurity(
      twoFactorEnabled: json['twoFactorEnabled'] as bool? ?? false,
      twoFactorMethod: json['twoFactorMethod'] as String? ?? 'email',
      twoFactorEnabledAt: json['twoFactorEnabledAt'] != null
          ? DateTime.tryParse(json['twoFactorEnabledAt'] as String)
          : null,
    );
  }
}

class QuietHours {
  final bool enabled;
  final String start; // "HH:mm"
  final String end;   // "HH:mm"
  final String timezone;

  QuietHours({
    required this.enabled,
    required this.start,
    required this.end,
    required this.timezone,
  });

  factory QuietHours.fromJson(Map<String, dynamic> json) {
    return QuietHours(
      enabled: json['enabled'] ?? false,
      start: json['start'] ?? '22:00',
      end: json['end'] ?? '07:00',
      timezone: json['timezone'] ?? 'Asia/Kolkata',
    );
  }

  Map<String, dynamic> toJson() => {
    'enabled': enabled,
    'start': start,
    'end': end,
    'timezone': timezone,
  };

  QuietHours copyWith({bool? enabled, String? start, String? end, String? timezone}) {
    return QuietHours(
      enabled: enabled ?? this.enabled,
      start: start ?? this.start,
      end: end ?? this.end,
      timezone: timezone ?? this.timezone,
    );
  }
}

class NotificationHistoryItem {
  final String id;
  final String title;
  final String body;
  final String category;
  final Map<String, dynamic> data;
  final bool isUrgent;
  final bool isRead;
  final DateTime sentAt;

  NotificationHistoryItem({
    required this.id,
    required this.title,
    required this.body,
    required this.category,
    required this.data,
    required this.isUrgent,
    required this.isRead,
    required this.sentAt,
  });

  factory NotificationHistoryItem.fromJson(Map<String, dynamic> json) {
    return NotificationHistoryItem(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      category: json['category'] ?? 'unknown',
      data: Map<String, dynamic>.from(json['data'] ?? {}),
      isUrgent: json['isUrgent'] ?? false,
      isRead: json['isRead'] ?? false,
      sentAt: json['sentAt'] != null
          ? DateTime.tryParse(json['sentAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}