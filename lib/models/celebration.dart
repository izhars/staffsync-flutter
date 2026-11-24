class Employee {
  final String id;
  final String employeeId;
  final String firstName;
  final String lastName;
  final String fullName;
  final String email;
  final String department;
  final String designation;
  final String? dateOfBirth;
  final String? marriageAnniversary;
  final String? dateOfJoining;
  final String? maritalStatus;
  final int? yearsOfService;

  Employee({
    required this.id,
    required this.employeeId,
    required this.firstName,
    required this.lastName,
    required this.fullName,
    required this.email,
    required this.department,
    required this.designation,
    this.dateOfBirth,
    this.marriageAnniversary,
    this.dateOfJoining,
    this.maritalStatus,
    this.yearsOfService,
  });

  String get initials {
    final f = firstName.trim();
    final l = lastName.trim();
    if (f.isEmpty && l.isEmpty) return '?';
    if (f.isEmpty) return l[0].toUpperCase();
    if (l.isEmpty) return f[0].toUpperCase();
    return '${f[0]}${l[0]}'.toUpperCase();
  }

  factory Employee.fromJson(Map<String, dynamic> j) {
    final dept = j['department'];
    return Employee(
      id: j['_id']?.toString() ?? j['id']?.toString() ?? '',
      employeeId: j['employeeId']?.toString() ?? '',
      firstName: j['firstName']?.toString() ?? '',
      lastName: j['lastName']?.toString() ?? '',
      fullName: j['fullName']?.toString() ??
          '${j['firstName'] ?? ''} ${j['lastName'] ?? ''}'.trim(),
      email: j['email']?.toString() ?? '',
      department: dept is Map
          ? (dept['name']?.toString() ?? '')
          : (dept?.toString() ?? ''),
      designation: j['designation']?.toString() ?? '',
      dateOfBirth: j['dateOfBirth']?.toString(),
      marriageAnniversary: j['marriageAnniversary']?.toString(),
      dateOfJoining: j['dateOfJoining']?.toString(),
      maritalStatus: j['maritalStatus']?.toString(),
      yearsOfService: j['yearsOfService'] is int
          ? j['yearsOfService'] as int
          : int.tryParse('${j['yearsOfService']}'),
    );
  }
}

class UpcomingEvent {
  final String id;
  final String employeeId;
  final String firstName;
  final String lastName;
  final String fullName;
  final String email;
  final String department;
  final String designation;
  final String celebrationDate;
  final int daysUntil;
  final int? yearsOfService;
  final String? maritalStatus;

  UpcomingEvent({
    required this.id,
    required this.employeeId,
    required this.firstName,
    required this.lastName,
    required this.fullName,
    required this.email,
    required this.department,
    required this.designation,
    required this.celebrationDate,
    required this.daysUntil,
    this.yearsOfService,
    this.maritalStatus,
  });

  String get initials {
    final f = firstName.trim();
    final l = lastName.trim();
    if (f.isEmpty && l.isEmpty) return '?';
    if (f.isEmpty) return l[0].toUpperCase();
    if (l.isEmpty) return f[0].toUpperCase();
    return '${f[0]}${l[0]}'.toUpperCase();
  }

  factory UpcomingEvent.fromJson(Map<String, dynamic> j) {
    final dept = j['department'];
    return UpcomingEvent(
      id: j['_id']?.toString() ?? j['id']?.toString() ?? '',
      employeeId: j['employeeId']?.toString() ?? '',
      firstName: j['firstName']?.toString() ?? '',
      lastName: j['lastName']?.toString() ?? '',
      fullName: j['fullName']?.toString() ??
          '${j['firstName'] ?? ''} ${j['lastName'] ?? ''}'.trim(),
      email: j['email']?.toString() ?? '',
      department: dept is Map
          ? (dept['name']?.toString() ?? '')
          : (dept?.toString() ?? ''),
      designation: j['designation']?.toString() ?? '',
      celebrationDate: j['celebrationDate']?.toString() ?? '',
      daysUntil: j['daysUntil'] is int
          ? j['daysUntil'] as int
          : int.tryParse('${j['daysUntil']}') ?? 0,
      yearsOfService: j['yearsOfService'] is int
          ? j['yearsOfService'] as int
          : int.tryParse('${j['yearsOfService']}'),
      maritalStatus: j['maritalStatus']?.toString(),
    );
  }
}

class CelebrationBucket {
  final int count;
  final int total;
  final int page;
  final int pages;
  final List<Employee> data;

  CelebrationBucket({
    required this.count,
    required this.total,
    required this.page,
    required this.pages,
    required this.data,
  });

  factory CelebrationBucket.fromJson(Map<String, dynamic> j) {
    int asInt(dynamic v) => v is int ? v : int.tryParse('$v') ?? 0;
    return CelebrationBucket(
      count: asInt(j['count']),
      total: asInt(j['total']),
      page: asInt(j['page']),
      pages: asInt(j['pages']),
      data: (j['data'] as List? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(Employee.fromJson)
          .toList(),
    );
  }
}

class UpcomingBucket {
  final List<UpcomingEvent> data;

  UpcomingBucket({required this.data});

  factory UpcomingBucket.fromJson(Map<String, dynamic> j) {
    return UpcomingBucket(
      data: (j['data'] as List? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(UpcomingEvent.fromJson)
          .toList(),
    );
  }
}

class TodayCelebrations {
  final CelebrationBucket birthdays;
  final CelebrationBucket marriageAnniversaries;
  final CelebrationBucket workAnniversaries;

  TodayCelebrations({
    required this.birthdays,
    required this.marriageAnniversaries,
    required this.workAnniversaries,
  });

  factory TodayCelebrations.fromJson(Map<String, dynamic> j) {
    return TodayCelebrations(
      birthdays: CelebrationBucket.fromJson(
          (j['birthdays'] as Map<String, dynamic>?) ?? const {}),
      marriageAnniversaries: CelebrationBucket.fromJson(
          (j['marriageAnniversaries'] as Map<String, dynamic>?) ?? const {}),
      workAnniversaries: CelebrationBucket.fromJson(
          (j['workAnniversaries'] as Map<String, dynamic>?) ?? const {}),
    );
  }
}

class UpcomingCelebrations {
  final List<UpcomingEvent> birthdays;
  final List<UpcomingEvent> marriageAnniversaries;
  final List<UpcomingEvent> workAnniversaries;

  UpcomingCelebrations({
    required this.birthdays,
    required this.marriageAnniversaries,
    required this.workAnniversaries,
  });

  factory UpcomingCelebrations.fromJson(Map<String, dynamic> j) {
    List<UpcomingEvent> list(dynamic v) => (v as List? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(UpcomingEvent.fromJson)
        .toList();
    return UpcomingCelebrations(
      birthdays: list(j['birthdays']),
      marriageAnniversaries: list(j['marriageAnniversaries']),
      workAnniversaries: list(j['workAnniversaries']),
    );
  }
}

class TodayData {
  final TodayCelebrations today;
  TodayData({required this.today});
  factory TodayData.fromJson(Map<String, dynamic> j) => TodayData(
    today: TodayCelebrations.fromJson(
        (j['today'] as Map<String, dynamic>?) ?? const {}),
  );
}

class UpcomingData {
  final UpcomingCelebrations upcoming;
  final int page;
  final int limit;

  UpcomingData({
    required this.upcoming,
    required this.page,
    required this.limit,
  });

  factory UpcomingData.fromJson(Map<String, dynamic> j) => UpcomingData(
    upcoming: UpcomingCelebrations.fromJson(
        (j['upcoming'] as Map<String, dynamic>?) ?? const {}),
    page: j['page'] is int ? j['page'] : int.tryParse('${j['page']}') ?? 1,
    limit:
    j['limit'] is int ? j['limit'] : int.tryParse('${j['limit']}') ?? 10,
  );
}
class CelebrationResponse {
  final bool success;
  final TodayData data;
  CelebrationResponse({required this.success, required this.data});
  factory CelebrationResponse.fromJson(Map<String, dynamic> j) =>
      CelebrationResponse(
        success: j['success'] == true,
        data: TodayData.fromJson(
            (j['data'] as Map<String, dynamic>?) ?? const {}),
      );
}

class UpcomingResponse {
  final bool success;
  final UpcomingData data;

  UpcomingResponse({required this.success, required this.data});

  factory UpcomingResponse.fromJson(Map<String, dynamic> j) =>
      UpcomingResponse(
        success: j['success'] == true,
        data: UpcomingData.fromJson(
            (j['data'] as Map<String, dynamic>?) ?? const {}),
      );
}

// ═══════════════════════════════════════════════════════════════
// REGARDS MODELS
// ═══════════════════════════════════════════════════════════════

class RegardUser {
  final String? employeeId;
  final String fullName;
  final String designation;
  final String department;
  final String? avatarInitial;

  RegardUser({
    this.employeeId,
    required this.fullName,
    this.designation = '',
    this.department = '',
    this.avatarInitial,
  });

  factory RegardUser.fromJson(Map<String, dynamic> json) {
    final first = json['firstName']?.toString() ?? '';
    final last = json['lastName']?.toString() ?? '';
    final full = json['fullName']?.toString();
    final dept = json['department'];
    return RegardUser(
      employeeId: json['employeeId']?.toString(),
      fullName: (full != null && full.trim().isNotEmpty)
          ? full
          : [first, last].where((s) => s.trim().isNotEmpty).join(' '),
      designation: json['designation']?.toString() ?? '',
      department: dept is Map ? (dept['name']?.toString() ?? '') : '',
      avatarInitial: first.isNotEmpty ? first[0].toUpperCase() : null,
    );
  }
}

class RegardItem {
  final String id;
  final RegardUser? from;
  final RegardUser? to;
  final String celebrationType; // birthday | marriage | work
  final String celebrationDate;
  final String message;
  final String status;
  final DateTime? readAt;
  final DateTime? createdAt;

  RegardItem({
    required this.id,
    this.from,
    this.to,
    required this.celebrationType,
    required this.celebrationDate,
    required this.message,
    required this.status,
    this.readAt,
    this.createdAt,
  });

  bool get isUnread => readAt == null && status != 'failed';

  RegardItem copyWith({DateTime? readAt}) => RegardItem(
    id: id,
    from: from,
    to: to,
    celebrationType: celebrationType,
    celebrationDate: celebrationDate,
    message: message,
    status: status,
    readAt: readAt ?? this.readAt,
    createdAt: createdAt,
  );

  factory RegardItem.fromJson(Map<String, dynamic> j) {
    DateTime? parse(dynamic v) =>
        v == null ? null : DateTime.tryParse(v.toString());
    return RegardItem(
      id: j['_id']?.toString() ?? j['id']?.toString() ?? '',
      from: j['from'] is Map<String, dynamic>
          ? RegardUser.fromJson(j['from'])
          : null,
      to: j['to'] is Map<String, dynamic>
          ? RegardUser.fromJson(j['to'])
          : null,
      celebrationType: j['celebrationType']?.toString() ?? 'birthday',
      celebrationDate: j['celebrationDate']?.toString() ?? '',
      message: j['message']?.toString() ?? '',
      status: j['status']?.toString() ?? 'pending',
      readAt: parse(j['readAt']),
      createdAt: parse(j['createdAt']),
    );
  }
}

class RegardBucket {
  final int count;
  final int total;
  final int page;
  final int pages;
  final List<RegardItem> data;

  RegardBucket({
    required this.count,
    required this.total,
    required this.page,
    required this.pages,
    required this.data,
  });

  factory RegardBucket.fromJson(Map<String, dynamic> j) {
    int asInt(dynamic v) => v is int ? v : int.tryParse('$v') ?? 0;
    return RegardBucket(
      count: asInt(j['count']),
      total: asInt(j['total']),
      page: asInt(j['page']),
      pages: asInt(j['pages']),
      data: (j['data'] as List? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(RegardItem.fromJson)
          .toList(),
    );
  }

  static RegardBucket empty() =>
      RegardBucket(count: 0, total: 0, page: 1, pages: 0, data: const []);
}