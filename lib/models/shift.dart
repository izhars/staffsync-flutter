class MyShiftResponse {
  final Shift shift;
  final DateTime? assignedAt;
  final String weekendType;
  final List<String> workingDays;
  final List<String> weekendDays;

  const MyShiftResponse({
    required this.shift,
    required this.assignedAt,
    required this.weekendType,
    required this.workingDays,
    required this.weekendDays,
  });

  factory MyShiftResponse.fromJson(Map<String, dynamic> json) {
    return MyShiftResponse(
      shift: Shift.fromJson(
        (json['shift'] as Map<String, dynamic>?) ?? const {},
      ),
      assignedAt: json['assignedAt'] != null
          ? DateTime.tryParse(json['assignedAt'] as String)
          : null,
      weekendType: (json['weekendType'] as String?) ?? '',
      workingDays: (json['workingDays'] as List<dynamic>? ?? const [])
          .whereType<String>()
          .toList(growable: false),
      weekendDays: (json['weekendDays'] as List<dynamic>? ?? const [])
          .whereType<String>()
          .toList(growable: false),
    );
  }
}

class Shift {
  final String id;
  final String name;
  final String code;
  final String description;
  final String startTime;
  final String endTime;
  final int breakDuration;
  final int gracePeriod;
  final int halfDayThreshold;
  final int earlyLeaveGrace;
  final String type;
  final bool isNightShift;
  final num nightShiftAllowance;
  final int durationMinutes;
  final String durationHours;
  final String displayTiming;

  const Shift({
    required this.id,
    required this.name,
    required this.code,
    required this.description,
    required this.startTime,
    required this.endTime,
    required this.breakDuration,
    required this.gracePeriod,
    required this.halfDayThreshold,
    required this.earlyLeaveGrace,
    required this.type,
    required this.isNightShift,
    required this.nightShiftAllowance,
    required this.durationMinutes,
    required this.durationHours,
    required this.displayTiming,
  });

  factory Shift.fromJson(Map<String, dynamic> json) {
    return Shift(
      id: (json['id'] ?? json['_id'] ?? '') as String,
      name: (json['name'] as String?) ?? '',
      code: (json['code'] as String?) ?? '',
      description: (json['description'] as String?) ?? '',
      startTime: (json['startTime'] as String?) ?? '',
      endTime: (json['endTime'] as String?) ?? '',
      breakDuration: (json['breakDuration'] as num?)?.toInt() ?? 0,
      gracePeriod: (json['gracePeriod'] as num?)?.toInt() ?? 0,
      halfDayThreshold: (json['halfDayThreshold'] as num?)?.toInt() ?? 0,
      earlyLeaveGrace: (json['earlyLeaveGrace'] as num?)?.toInt() ?? 0,
      type: (json['type'] as String?) ?? 'fixed',
      isNightShift: (json['isNightShift'] as bool?) ?? false,
      nightShiftAllowance: (json['nightShiftAllowance'] as num?) ?? 0,
      durationMinutes: (json['durationMinutes'] as num?)?.toInt() ?? 0,
      durationHours: (json['durationHours'] as String?) ?? '0.00',
      displayTiming: (json['displayTiming'] as String?) ?? '',
    );
  }
}