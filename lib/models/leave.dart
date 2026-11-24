// models/leave.dart
import 'package:intl/intl.dart';

class Leave {
  final String id;
  final String employeeId;
  final String employeeName;
  final String leaveType;
  final DateTime startDate;
  final DateTime endDate;
  final double totalDays; // Changed to double for half-day support
  final String status;
  final String reason;
  final DateTime appliedOn;
  final String? rejectionReason;
  final String? approvedByName;
  final String leaveDuration; // "full" or "half"
  final String? halfDayType; // "first_half" or "second_half"
  final String? cancellationReason; // NEW — for cancelled leaves
  final String? cancelledByName;    // NEW — who cancelled it

  Leave({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.leaveType,
    required this.startDate,
    required this.endDate,
    required this.totalDays,
    required this.status,
    required this.reason,
    required this.appliedOn,
    this.rejectionReason,
    this.approvedByName,
    this.leaveDuration = 'full',
    this.halfDayType,
    this.cancellationReason,
    this.cancelledByName,
  });

  factory Leave.fromJson(Map<String, dynamic> json) {
    final employee = json['employee'];

    String employeeId = '';
    String employeeName = '';

    if (employee is Map<String, dynamic>) {
      employeeId = employee['employeeId'] ?? '';
      employeeName =
          '${employee['firstName'] ?? ''} ${employee['lastName'] ?? ''}'.trim();
    } else if (employee is String) {
      employeeId = employee;
    }

    // Parse dates safely (backend always sends them, but be defensive)
    DateTime parseDate(dynamic value) {
      if (value == null) return DateTime.now();
      try {
        return DateTime.parse(value.toString());
      } catch (_) {
        return DateTime.now();
      }
    }

    // Parse approvedBy / cancelledBy (either populated object or null)
    String? parsePersonName(dynamic person) {
      if (person is Map<String, dynamic>) {
        final name =
        '${person['firstName'] ?? ''} ${person['lastName'] ?? ''}'.trim();
        return name.isEmpty ? null : name;
      }
      return null;
    }

    return Leave(
      id: json['_id'] ?? json['id'] ?? '',
      employeeId: employeeId,
      employeeName: employeeName,
      leaveType: json['leaveType'] ?? '',
      startDate: parseDate(json['startDate']),
      endDate: parseDate(json['endDate']),
      totalDays: (json['totalDays'] ?? 0).toDouble(),
      status: json['status'] ?? '',
      reason: json['reason'] ?? '',
      appliedOn: parseDate(json['createdAt'] ?? json['appliedOn']),
      rejectionReason: json['rejectionReason'],
      approvedByName: parsePersonName(json['approvedBy']),
      leaveDuration: json['leaveDuration'] ?? 'full',
      halfDayType: json['halfDayType'],
      cancellationReason: json['cancellationReason'],
      cancelledByName: parsePersonName(json['cancelledBy']),
    );
  }

  // ─────────────────────────────────────────────
  // Display helpers
  // ─────────────────────────────────────────────

  /// Human-readable leave type (supports casual + combo).
  String get displayLeaveType {
    if (leaveType.isEmpty) return 'Leave';
    switch (leaveType.toLowerCase()) {
      case 'casual':
        return 'Casual Leave';
      case 'combo':
        return 'Combo Off';
      case 'sick':
        return 'Sick Leave';
      case 'earned':
        return 'Earned Leave';
      case 'unpaid':
        return 'Unpaid Leave';
      case 'maternity':
        return 'Maternity Leave';
      case 'paternity':
        return 'Paternity Leave';
      default:
        return leaveType[0].toUpperCase() + leaveType.substring(1);
    }
  }

  /// Short formatted date range, respecting half-day.
  String get formattedDateRange {
    final start = DateFormat('MMM dd').format(startDate.toLocal());
    final end = DateFormat('MMM dd, yyyy').format(endDate.toLocal());

    if (leaveDuration == 'half') {
      final halfType =
      halfDayType == 'first_half' ? 'First Half' : 'Second Half';
      return '$start ($halfType)';
    }

    return '$start - $end';
  }

  /// Full duration display, e.g. "2 days" or "0.5 day (First Half)".
  String get durationDisplay {
    if (leaveDuration == 'half') {
      return '0.5 day (${halfDayType == 'first_half' ? 'First Half' : 'Second Half'})';
    }
    return '$totalDays ${totalDays == 1 ? 'day' : 'days'}';
  }

  /// True if leave is still actionable (pending or approved).
  bool get isCancellable =>
      status == 'pending' || status == 'approved';

  /// True if this is a combo leave (earned via working weekends/holidays).
  bool get isCombo => leaveType.toLowerCase() == 'combo';
}

// ─────────────────────────────────────────────
// LeaveBalance — trimmed to casual + combo
// ─────────────────────────────────────────────
class LeaveBalance {
  final int casual;
  final int combo;

  LeaveBalance({
    required this.casual,
    required this.combo,
  });

  factory LeaveBalance.fromJson(Map<String, dynamic> json) {
    return LeaveBalance(
      casual: _asInt(json['casual']),
      combo: _asInt(json['combo']),
    );
  }

  /// Total paid leave available (casual + combo).
  int get total => casual + combo;

  /// Empty balance.
  static LeaveBalance get zero => LeaveBalance(casual: 0, combo: 0);

  /// Safe int parser — handles int, double, String, null.
  static int _asInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}