import 'package:flutter/material.dart';

/// Known notification types (must match backend enum).
/// Any unknown type from backend is safely handled as [NotificationType.general].
enum NotificationType {
  general,
  incomingCall,
  callDeclined,
  callMissed,
  callEnded,
  callAccepted,
  call,
  employeeInteraction,
  info,
  warning,
  success,
  error,
  system,
  meeting,
  task,
  ticket,
  attendance,
  leave,
  leaveUpdate,
  payroll,
  announcement,
  expense,
  asset,
  celebration,
  holiday,
  security,
  message,
  onboarding,
  policy,
  unknown;

  static NotificationType fromString(String? raw) {
    if (raw == null || raw.isEmpty) return NotificationType.general;
    switch (raw) {
      case 'general':              return NotificationType.general;
      case 'incoming_call':        return NotificationType.incomingCall;
      case 'call_declined':        return NotificationType.callDeclined;
      case 'call_missed':          return NotificationType.callMissed;
      case 'call_ended':           return NotificationType.callEnded;
      case 'call_accepted':        return NotificationType.callAccepted;
      case 'call':                 return NotificationType.call;
      case 'employee_interaction': return NotificationType.employeeInteraction;
      case 'info':                 return NotificationType.info;
      case 'warning':              return NotificationType.warning;
      case 'success':              return NotificationType.success;
      case 'error':                return NotificationType.error;
      case 'system':               return NotificationType.system;
      case 'meeting':              return NotificationType.meeting;
      case 'task':                 return NotificationType.task;
      case 'ticket':               return NotificationType.ticket;
      case 'attendance':           return NotificationType.attendance;
      case 'leave':                return NotificationType.leave;
      case 'leave_update':         return NotificationType.leaveUpdate;
      case 'payroll':              return NotificationType.payroll;
      case 'announcement':         return NotificationType.announcement;
      case 'expense':              return NotificationType.expense;
      case 'asset':                return NotificationType.asset;
      case 'celebration':          return NotificationType.celebration;
      case 'holiday':              return NotificationType.holiday;
      case 'security':             return NotificationType.security;
      case 'message':              return NotificationType.message;
      case 'onboarding':           return NotificationType.onboarding;
      case 'policy':               return NotificationType.policy;
      default:                     return NotificationType.unknown;
    }
  }

  IconData get icon {
    switch (this) {
      case NotificationType.info:                 return Icons.info_rounded;
      case NotificationType.warning:              return Icons.warning_amber_rounded;
      case NotificationType.success:              return Icons.check_circle_rounded;
      case NotificationType.error:                return Icons.error_rounded;
      case NotificationType.incomingCall:         return Icons.phone_callback_rounded;
      case NotificationType.callDeclined:         return Icons.phone_disabled_rounded;
      case NotificationType.callMissed:           return Icons.phone_missed_rounded;
      case NotificationType.callEnded:            return Icons.call_end_rounded;
      case NotificationType.callAccepted:         return Icons.phone_in_talk_rounded;
      case NotificationType.call:                 return Icons.phone_rounded;
      case NotificationType.employeeInteraction:  return Icons.people_alt_rounded;
      case NotificationType.system:               return Icons.settings_rounded;
      case NotificationType.meeting:              return Icons.video_call_rounded;
      case NotificationType.task:                 return Icons.task_alt_rounded;
      case NotificationType.ticket:               return Icons.confirmation_number_rounded;
      case NotificationType.attendance:           return Icons.alarm_on_rounded;
      case NotificationType.leave:
      case NotificationType.leaveUpdate:          return Icons.beach_access_rounded;
      case NotificationType.payroll:              return Icons.account_balance_wallet_rounded;
      case NotificationType.announcement:         return Icons.campaign_rounded;
      case NotificationType.expense:              return Icons.receipt_long_rounded;
      case NotificationType.asset:                return Icons.devices_rounded;
      case NotificationType.celebration:          return Icons.cake_rounded;
      case NotificationType.holiday:              return Icons.event_available_rounded;
      case NotificationType.security:             return Icons.shield_rounded;
      case NotificationType.message:              return Icons.chat_rounded;
      case NotificationType.onboarding:           return Icons.badge_rounded;
      case NotificationType.policy:               return Icons.policy_rounded;
      case NotificationType.general:
      case NotificationType.unknown:
        return Icons.notifications_rounded;
    }
  }

  Color color(BuildContext context) {
    switch (this) {
      case NotificationType.info:
      case NotificationType.call:
      case NotificationType.incomingCall:
      case NotificationType.callAccepted:
      case NotificationType.message:
        return Colors.blue.shade600;
      case NotificationType.warning:
      case NotificationType.callMissed:
      case NotificationType.leave:
      case NotificationType.leaveUpdate:
        return Colors.orange.shade700;
      case NotificationType.success:
      case NotificationType.task:
      case NotificationType.holiday:
        return Colors.green.shade600;
      case NotificationType.error:
      case NotificationType.callDeclined:
      case NotificationType.callEnded:
      case NotificationType.security:
        return Colors.red.shade600;
      case NotificationType.payroll:
        return Colors.teal.shade700;
      case NotificationType.ticket:
        return Colors.indigo.shade600;
      case NotificationType.attendance:
        return Colors.blue.shade700;
      case NotificationType.announcement:
        return Colors.purple.shade600;
      case NotificationType.expense:
        return Colors.deepOrange.shade600;
      case NotificationType.celebration:
        return Colors.pink.shade500;
      case NotificationType.asset:
        return Colors.indigo.shade500;
      case NotificationType.onboarding:
      case NotificationType.policy:
        return Colors.cyan.shade700;
      case NotificationType.employeeInteraction:
      case NotificationType.meeting:
        return Colors.purple.shade500;
      case NotificationType.system:
        return Colors.blueGrey.shade600;
      case NotificationType.general:
      case NotificationType.unknown:
        return Theme.of(context).colorScheme.primary;
    }
  }
}

class AppNotification {
  final String id;
  final String? userId;
  final String? role;
  final NotificationType type;
  final String rawType;
  final String title;
  final String message;
  bool read;
  final String? link;
  final Map<String, dynamic> meta;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? createdBy;
  final bool isGlobal;
  final bool deleted;

  AppNotification({
    required this.id,
    this.userId,
    this.role,
    required this.type,
    required this.rawType,
    required this.title,
    required this.message,
    required this.read,
    this.link,
    required this.meta,
    required this.createdAt,
    this.updatedAt,
    this.createdBy,
    this.isGlobal = false,
    this.deleted = false,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    final rawType = _asString(json['type']) ?? 'general';

    return AppNotification(
      id: _asString(json['_id']) ?? _asString(json['id']) ?? '',
      userId: _extractId(json['user']),
      role: _asString(json['role']),
      type: NotificationType.fromString(rawType),
      rawType: rawType,
      title: _asString(json['title']) ?? 'Notification',
      message: _asString(json['message']) ?? '',
      read: json['read'] == true,
      link: _asString(json['link']),
      meta: _asMap(json['meta']),
      createdAt: _asDate(json['createdAt']) ?? DateTime.now(),
      updatedAt: _asDate(json['updatedAt']),
      createdBy: _extractId(json['createdBy']),
      isGlobal: json['isGlobal'] == true,
      deleted: json['deleted'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'role': role,
    'type': rawType,
    'title': title,
    'message': message,
    'read': read,
    'link': link,
    'meta': meta,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
    'createdBy': createdBy,
    'isGlobal': isGlobal,
    'deleted': deleted,
  };

  /// Convenience: get a meta value as string safely.
  String? metaString(String key) {
    final v = meta[key];
    if (v == null) return null;
    return v.toString();
  }

  bool metaBool(String key, {bool fallback = false}) {
    final v = meta[key];
    if (v is bool) return v;
    if (v is String) return v.toLowerCase() == 'true';
    return fallback;
  }

  // ── Helpers ───────────────────────────────────────────────

  static String? _asString(dynamic v) {
    if (v == null) return null;
    if (v is String) return v;
    return v.toString();
  }

  /// Handles ObjectId as string OR as { _id: '...' } populated object.
  static String? _extractId(dynamic v) {
    if (v == null) return null;
    if (v is String) return v;
    if (v is Map) {
      final id = v['_id'] ?? v['id'];
      return id?.toString();
    }
    return v.toString();
  }

  static Map<String, dynamic> _asMap(dynamic v) {
    if (v is Map<String, dynamic>) return v;
    if (v is Map) return v.map((k, val) => MapEntry(k.toString(), val));
    return const {};
  }

  static DateTime? _asDate(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    if (v is String) return DateTime.tryParse(v)?.toLocal();
    if (v is int) {
      // Could be seconds or ms — guess by magnitude.
      if (v > 100000000000) return DateTime.fromMillisecondsSinceEpoch(v);
      return DateTime.fromMillisecondsSinceEpoch(v * 1000);
    }
    return null;
  }
}