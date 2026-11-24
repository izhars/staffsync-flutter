// lib/models/employee.dart

class Employee {
  // ---------- Core identity ----------
  final String id;            // maps to MongoDB _id
  final String employeeId;    // human-readable HR code, e.g. SCAIPLH005
  final String firstName;
  final String lastName;
  final String name;          // legacy / fallback display name

  // ---------- Contact ----------
  final String email;
  final String phone;

  // ---------- Role / org ----------
  final String role;          // e.g. employee, manager, hr_admin, finance
  final String position;      // rarely populated by backend, kept for legacy
  final String designation;   // e.g. Android Developer
  final String departmentId;  // dept _id (from department._id)
  final String department;    // dept name (from department.name)

  // ---------- Media ----------
  final String? profilePicture;

  // ---------- Dates ----------
  final DateTime hireDate;    // maps to dateOfJoining

  // ---------- Push tokens ----------
  final List<String> fcmToken; // backend sends [] | [..] | null

  // ---------- Status flags ----------
  final bool isActive;
  final bool isAvailable;

  const Employee({
    required this.id,
    required this.employeeId,
    required this.firstName,
    required this.lastName,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    required this.position,
    required this.designation,
    required this.departmentId,
    required this.department,
    this.profilePicture,
    required this.hireDate,
    this.fcmToken = const [],
    required this.isActive,
    required this.isAvailable,
  });

  // ============================================================
  //  JSON -> Employee  (matches the real StaffSync API payload)
  // ============================================================
  factory Employee.fromJson(Map<String, dynamic> json) {
    final dept = json['department'];
    final departmentName =
    dept is Map ? _str(dept['name']) ?? '' : _str(dept) ?? '';
    final departmentId =
    dept is Map ? _str(dept['_id']) ?? '' : _str(json['department_id']) ?? '';

    return Employee(
      // Mongo uses _id; accept either
      id: _str(json['_id']) ?? _str(json['id']) ?? '',
      employeeId: _str(json['employeeId']) ?? '',
      firstName: _str(json['firstName']) ?? '',
      lastName: _str(json['lastName']) ?? '',
      name: _str(json['name']) ?? '',
      email: _str(json['email']) ?? '',
      phone: _str(json['phone']) ?? '',
      role: _str(json['role']) ?? '',
      position: _str(json['position']) ?? '',
      designation: _str(json['designation']) ?? '',
      departmentId: departmentId,
      department: departmentName,
      profilePicture: _str(json['profilePicture']),
      hireDate: _date(json['dateOfJoining']) ??
          _date(json['hire_date']) ??
          DateTime.now(),
      fcmToken: _strList(json['fcmToken']),
      isActive: json['isActive'] ?? json['is_active'] ?? true,
      isAvailable: json['isAvailable'] ?? true,
    );
  }

  // ============================================================
  //  Employee -> JSON
  // ============================================================
  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'employeeId': employeeId,
      'firstName': firstName,
      'lastName': lastName,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
      'position': position,
      'designation': designation,
      'department_id': departmentId,
      'department': department,
      'profilePicture': profilePicture,
      'dateOfJoining': hireDate.toIso8601String(),
      'fcmToken': fcmToken,
      'isActive': isActive,
      'isAvailable': isAvailable,
    };
  }

  // ============================================================
  //  Getters
  // ============================================================

  /// Full display name — never blank, falls back to `name`
  String get fullName {
    if (firstName.isNotEmpty || lastName.isNotEmpty) {
      return '$firstName $lastName'.trim();
    }
    return name;
  }

  /// First token, or null — convenience for code that expected `String?`
  String? get primaryFcmToken =>
      fcmToken.isNotEmpty ? fcmToken.first : null;

  // ============================================================
  //  Minimal / safe fallback constructor
  // ============================================================
  factory Employee.minimal({
    required String id,
    String firstName = '',
    String lastName = '',
    String name = '',
    String employeeId = '',
    bool isActive = true,
    bool isAvailable = true,
  }) {
    return Employee(
      id: id,
      employeeId: employeeId,
      firstName: firstName,
      lastName: lastName,
      name: name,
      email: '',
      phone: '',
      role: '',
      position: '',
      designation: '',
      departmentId: '',
      department: '',
      hireDate: DateTime.now(),
      fcmToken: const [],
      isActive: isActive,
      isAvailable: isAvailable,
    );
  }

  // ============================================================
  //  copyWith (optional, handy for state updates)
  // ============================================================
  Employee copyWith({
    String? id,
    String? employeeId,
    String? firstName,
    String? lastName,
    String? name,
    String? email,
    String? phone,
    String? role,
    String? position,
    String? designation,
    String? departmentId,
    String? department,
    String? profilePicture,
    DateTime? hireDate,
    List<String>? fcmToken,
    bool? isActive,
    bool? isAvailable,
  }) {
    return Employee(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      position: position ?? this.position,
      designation: designation ?? this.designation,
      departmentId: departmentId ?? this.departmentId,
      department: department ?? this.department,
      profilePicture: profilePicture ?? this.profilePicture,
      hireDate: hireDate ?? this.hireDate,
      fcmToken: fcmToken ?? this.fcmToken,
      isActive: isActive ?? this.isActive,
      isAvailable: isAvailable ?? this.isAvailable,
    );
  }

  // ============================================================
  //  Defensive helpers
  // ============================================================

  /// Converts anything (String / num / bool / null) to String?
  static String? _str(dynamic v) {
    if (v == null) return null;
    if (v is String) return v.isEmpty ? null : v;
    if (v is num || v is bool) return v.toString();
    return v.toString();
  }

  /// Converts anything to List<String> — never throws.
  static List<String> _strList(dynamic v) {
    if (v == null) return const [];
    if (v is List) {
      return v
          .map((e) => e?.toString() ?? '')
          .where((e) => e.isNotEmpty)
          .toList();
    }
    if (v is String) return v.isEmpty ? const [] : [v];
    return const [];
  }

  /// Safe DateTime parse — returns null on failure.
  static DateTime? _date(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    return DateTime.tryParse(v.toString());
  }
}