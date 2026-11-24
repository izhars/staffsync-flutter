class User {
  final String id;
  final String employeeId;
  final String firstName;
  final String lastName;
  final String fullName;
  final String email;
  final String phone;
  final String role;
  final Department? department;
  final String? designation;
  final DateTime? dateOfJoining;
  final String? employmentType;
  final String status;
  final ReportingManager? reportingManager;
  final String? gender;
  final String? bloodGroup;
  final String? weekendType;
  final DateTime? dateOfBirth;
  final String? maritalStatus;
  final String? pfNumber;
  final String? uanNumber;
  final String? panNumber;
  final List<dynamic> documents;
  final String profilePicture;
  final bool isActive;
  final bool isVerified;
  final CreatedBy? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastLogin;
  final int? daysToAnniversary;
  final SpouseDetails? spouseDetails;
  final Address? address;
  final Salary? salary;
  final BankDetails? bankDetails;
  final LeaveBalance? leaveBalance;
  final EmergencyContact? emergencyContact;
  final Shift? shift; // ✅ NEW
  final DateTime? marriageAnniversary;
  final String? lastSeen;
  final String? fcmToken;
  final List<dynamic> socketIds;
  final List<String> permissions;
  final List<String> socketConnections;
  final int currentConnections;
  final bool isOnline;
  final bool? isOnProbation;
  final int? probationDaysRemaining;

  User({
    required this.id,
    required this.employeeId,
    required this.firstName,
    required this.lastName,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.role,
    this.department,
    this.designation,
    this.dateOfJoining,
    this.employmentType,
    required this.status,
    this.reportingManager,
    this.gender,
    this.bloodGroup,
    this.weekendType,
    this.dateOfBirth,
    this.maritalStatus,
    this.pfNumber,
    this.uanNumber,
    this.panNumber,
    required this.documents,
    required this.profilePicture,
    required this.isActive,
    required this.isVerified,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.lastLogin,
    this.daysToAnniversary,
    this.spouseDetails,
    this.address,
    this.salary,
    this.bankDetails,
    this.leaveBalance,
    this.emergencyContact,
    this.shift, // ✅ NEW
    this.marriageAnniversary,
    this.lastSeen,
    this.fcmToken,
    this.socketIds = const [],
    this.permissions = const [],
    this.socketConnections = const [],
    this.currentConnections = 0,
    this.isOnline = false,
    this.isOnProbation,
    this.probationDaysRemaining,
  });

  String get initials {
    if (firstName.isEmpty && lastName.isEmpty) {
      return email.isNotEmpty ? email[0].toUpperCase() : '?';
    }
    return (firstName.isNotEmpty ? firstName[0] : '') +
        (lastName.isNotEmpty ? lastName[0] : '').toUpperCase();
  }

  factory User.fromJson(Map<String, dynamic> json) {
    // Parse department if it exists
    Department? department;
    if (json['department'] != null && json['department'] is Map) {
      department =
          Department.fromJson(Map<String, dynamic>.from(json['department']));
    }

    // Parse reporting manager
    ReportingManager? reportingManager;
    if (json['reportingManager'] != null && json['reportingManager'] is Map) {
      reportingManager = ReportingManager.fromJson(
          Map<String, dynamic>.from(json['reportingManager']));
    }

    // Parse socket connections - handle both formats
    List<String> socketConnections = [];
    if (json['socketConnections'] is List) {
      socketConnections = List<String>.from(json['socketConnections']);
    }

    // Parse socket IDs
    List<dynamic> socketIds = [];
    if (json['socketIds'] is List) {
      socketIds = json['socketIds'];
    } else if (json['socketConnections'] is List) {
      socketIds = json['socketConnections'];
    }

    // Determine online status
    bool isOnline = json['isOnline'] == true ||
        (json['currentConnections'] ?? 0) > 0 ||
        (json['socketConnections'] is List &&
            (json['socketConnections'] as List).isNotEmpty) ||
        (json['socketIds'] is List &&
            (json['socketIds'] as List).isNotEmpty) ||
        json['lastSeen'] == 'Now';

    // Parse lastSeen as string
    String? lastSeen;
    if (json['lastSeen'] != null) {
      if (json['lastSeen'] is String) {
        lastSeen = json['lastSeen'];
      } else if (json['lastSeen'] is DateTime) {
        lastSeen = json['lastSeen'].toIso8601String();
      }
    }

    return User(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      employeeId: json['employeeId']?.toString() ?? '',
      firstName: json['firstName']?.toString() ?? '',
      lastName: json['lastName']?.toString() ?? '',
      fullName: json['fullName']?.toString() ??
          '${json['firstName'] ?? ''} ${json['lastName'] ?? ''}'.trim(),
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      role: json['role']?.toString() ?? 'employee',
      department: department,
      designation: json['designation']?.toString(),
      dateOfJoining: _tryParseDate(json['dateOfJoining']),
      employmentType: json['employmentType']?.toString(),
      status: json['status']?.toString() ?? '',
      reportingManager: reportingManager,
      gender: json['gender']?.toString(),
      bloodGroup: json['bloodGroup']?.toString(),
      weekendType: json['weekendType']?.toString(),
      dateOfBirth: _tryParseDate(json['dateOfBirth']),
      maritalStatus: json['maritalStatus']?.toString(),
      pfNumber: json['pfNumber']?.toString(),
      uanNumber: json['uanNumber']?.toString(),
      panNumber: json['panNumber']?.toString(),
      documents: json['documents'] ?? [],
      profilePicture: json['profilePicture']?.toString() ?? '',
      isActive: json['isActive'] ?? false,
      isVerified: json['isVerified'] ?? false,
      createdBy: json['createdBy'] != null && json['createdBy'] is Map
          ? CreatedBy.fromJson(Map<String, dynamic>.from(json['createdBy']))
          : null,
      createdAt: _tryParseDate(json['createdAt']) ?? DateTime.now(),
      updatedAt: _tryParseDate(json['updatedAt']) ?? DateTime.now(),
      lastLogin: _tryParseDate(json['lastLogin']),
      daysToAnniversary:
      json['daysToAnniversary'] is int ? json['daysToAnniversary'] : null,
      spouseDetails: json['spouseDetails'] != null && json['spouseDetails'] is Map
          ? SpouseDetails.fromJson(
          Map<String, dynamic>.from(json['spouseDetails']))
          : null,
      address: json['address'] != null && json['address'] is Map
          ? Address.fromJson(Map<String, dynamic>.from(json['address']))
          : null,
      salary: json['salary'] != null && json['salary'] is Map
          ? Salary.fromJson(Map<String, dynamic>.from(json['salary']))
          : null,
      bankDetails: json['bankDetails'] != null && json['bankDetails'] is Map
          ? BankDetails.fromJson(Map<String, dynamic>.from(json['bankDetails']))
          : null,
      leaveBalance: json['leaveBalance'] != null && json['leaveBalance'] is Map
          ? LeaveBalance.fromJson(
          Map<String, dynamic>.from(json['leaveBalance']))
          : null,
      emergencyContact: json['emergencyContact'] != null &&
          json['emergencyContact'] is Map
          ? EmergencyContact.fromJson(
          Map<String, dynamic>.from(json['emergencyContact']))
          : null,
      shift: json['shift'] != null && json['shift'] is Map // ✅ NEW
          ? Shift.fromJson(Map<String, dynamic>.from(json['shift']))
          : null,
      marriageAnniversary: _tryParseDate(json['marriageAnniversary']),
      lastSeen: lastSeen,
      fcmToken: json['fcmToken']?.toString(),
      socketIds: socketIds,
      permissions: json['permissions'] != null
          ? List<String>.from(json['permissions'])
          : [],
      socketConnections: socketConnections,
      currentConnections: (json['currentConnections'] ?? 0) is int
          ? json['currentConnections'] ?? 0
          : 0,
      isOnline: isOnline,
      isOnProbation: json['isOnProbation'] as bool?,
      probationDaysRemaining: (json['probationDaysRemaining'] as num?)?.toInt(),
    );
  }

  factory User.fromEmployeeMap(Map<String, dynamic> map) {
    return User.fromJson(map);
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'employeeId': employeeId,
      'firstName': firstName,
      'lastName': lastName,
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'role': role,
      'department': department?.toJson(),
      'designation': designation,
      'dateOfJoining': dateOfJoining?.toIso8601String(),
      'employmentType': employmentType,
      'status': status,
      'reportingManager': reportingManager?.toJson(),
      'gender': gender,
      'bloodGroup': bloodGroup,
      'weekendType': weekendType,
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'maritalStatus': maritalStatus,
      'pfNumber': pfNumber,
      'uanNumber': uanNumber,
      'panNumber': panNumber,
      'documents': documents,
      'profilePicture': profilePicture,
      'isActive': isActive,
      'isVerified': isVerified,
      'createdBy': createdBy?.toJson(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'lastLogin': lastLogin?.toIso8601String(),
      'daysToAnniversary': daysToAnniversary,
      'spouseDetails': spouseDetails?.toJson(),
      'address': address?.toJson(),
      'salary': salary?.toJson(),
      'bankDetails': bankDetails?.toJson(),
      'leaveBalance': leaveBalance?.toJson(),
      'emergencyContact': emergencyContact?.toJson(),
      'shift': shift?.toJson(), // ✅ NEW
      'marriageAnniversary': marriageAnniversary?.toIso8601String(),
      'lastSeen': lastSeen,
      'fcmToken': fcmToken,
      'socketIds': socketIds,
      'permissions': permissions,
      'socketConnections': socketConnections,
      'currentConnections': currentConnections,
      'isOnline': isOnline,
      'isOnProbation': isOnProbation,
      'probationDaysRemaining': probationDaysRemaining,
    };
  }

  bool get onlineStatus => isOnline;

  String get departmentName => department?.name ?? '';
  String get departmentCode => department?.code ?? '';
  String get departmentDescription => department?.description ?? '';

  static DateTime? _tryParseDate(dynamic value) {
    if (value == null) return null;
    try {
      return DateTime.parse(value.toString());
    } catch (_) {
      return null;
    }
  }

  User copyWith({
    String? id,
    String? employeeId,
    String? firstName,
    String? lastName,
    String? fullName,
    String? email,
    String? phone,
    String? role,
    Department? department,
    String? designation,
    DateTime? dateOfJoining,
    String? employmentType,
    String? status,
    ReportingManager? reportingManager,
    String? gender,
    String? bloodGroup,
    String? weekendType,
    DateTime? dateOfBirth,
    String? maritalStatus,
    String? pfNumber,
    String? uanNumber,
    String? panNumber,
    List<dynamic>? documents,
    String? profilePicture,
    bool? isActive,
    bool? isVerified,
    CreatedBy? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastLogin,
    int? daysToAnniversary,
    SpouseDetails? spouseDetails,
    Address? address,
    Salary? salary,
    BankDetails? bankDetails,
    LeaveBalance? leaveBalance,
    EmergencyContact? emergencyContact,
    Shift? shift, // ✅ NEW
    DateTime? marriageAnniversary,
    String? lastSeen,
    String? fcmToken,
    List<dynamic>? socketIds,
    List<String>? permissions,
    List<String>? socketConnections,
    int? currentConnections,
    bool? isOnline,
    bool? isOnProbation,
    int? probationDaysRemaining,
  }) {
    return User(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      department: department ?? this.department,
      designation: designation ?? this.designation,
      dateOfJoining: dateOfJoining ?? this.dateOfJoining,
      employmentType: employmentType ?? this.employmentType,
      status: status ?? this.status,
      reportingManager: reportingManager ?? this.reportingManager,
      gender: gender ?? this.gender,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      weekendType: weekendType ?? this.weekendType,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      maritalStatus: maritalStatus ?? this.maritalStatus,
      pfNumber: pfNumber ?? this.pfNumber,
      uanNumber: uanNumber ?? this.uanNumber,
      panNumber: panNumber ?? this.panNumber,
      documents: documents ?? this.documents,
      profilePicture: profilePicture ?? this.profilePicture,
      isActive: isActive ?? this.isActive,
      isVerified: isVerified ?? this.isVerified,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastLogin: lastLogin ?? this.lastLogin,
      daysToAnniversary: daysToAnniversary ?? this.daysToAnniversary,
      spouseDetails: spouseDetails ?? this.spouseDetails,
      address: address ?? this.address,
      salary: salary ?? this.salary,
      bankDetails: bankDetails ?? this.bankDetails,
      leaveBalance: leaveBalance ?? this.leaveBalance,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      shift: shift ?? this.shift, // ✅ NEW
      marriageAnniversary: marriageAnniversary ?? this.marriageAnniversary,
      lastSeen: lastSeen ?? this.lastSeen,
      fcmToken: fcmToken ?? this.fcmToken,
      socketIds: socketIds ?? this.socketIds,
      permissions: permissions ?? this.permissions,
      socketConnections: socketConnections ?? this.socketConnections,
      currentConnections: currentConnections ?? this.currentConnections,
      isOnline: isOnline ?? this.isOnline,
      isOnProbation: isOnProbation ?? this.isOnProbation,
      probationDaysRemaining:
      probationDaysRemaining ?? this.probationDaysRemaining,
    );
  }
}

class Department {
  final String id;
  final String name;
  final String code;
  final String description;

  Department({
    required this.id,
    required this.name,
    required this.code,
    required this.description,
  });

  factory Department.fromJson(Map<String, dynamic> json) {
    return Department(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      code: json['code'] ?? '',
      description: json['description'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'code': code,
      'description': description,
    };
  }
}

class CreatedBy {
  final String id;
  final String firstName;
  final String lastName;
  final String fullName;
  final int? daysToAnniversary;

  CreatedBy({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.fullName,
    this.daysToAnniversary,
  });

  factory CreatedBy.fromJson(Map<String, dynamic> json) {
    return CreatedBy(
      id: json['_id'] ?? json['id'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      fullName: json['fullName'] ?? '',
      daysToAnniversary: json['daysToAnniversary'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'firstName': firstName,
      'lastName': lastName,
      'fullName': fullName,
      'daysToAnniversary': daysToAnniversary,
    };
  }
}

class SpouseDetails {
  final bool isWorking;

  SpouseDetails({required this.isWorking});

  factory SpouseDetails.fromJson(Map<String, dynamic> json) {
    return SpouseDetails(
      isWorking: json['isWorking'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isWorking': isWorking,
    };
  }
}

// ---------- Salary ----------
class Salary {
  final double? basic;
  final double? hra;
  final double? medicalConveyance;
  final double? conveyanceAllowance;
  final double? specialAllowance;
  final double? grossSalary;
  final double? employerEPF;
  final double? costToCompany;
  final double? employeeEPF;
  final double? gratuity;
  final double? benevolentFund;
  final double? netSalary;
  final String? currency;
  final String? payFrequency;

  Salary({
    this.basic,
    this.hra,
    this.medicalConveyance,
    this.conveyanceAllowance,
    this.specialAllowance,
    this.grossSalary,
    this.employerEPF,
    this.costToCompany,
    this.employeeEPF,
    this.gratuity,
    this.benevolentFund,
    this.netSalary,
    this.currency,
    this.payFrequency,
  });

  factory Salary.fromJson(Map<String, dynamic> j) => Salary(
    basic: (j['basic'] as num?)?.toDouble(),
    hra: (j['hra'] as num?)?.toDouble(),
    medicalConveyance: (j['medicalConveyance'] as num?)?.toDouble(),
    conveyanceAllowance: (j['conveyanceAllowance'] as num?)?.toDouble(),
    specialAllowance: (j['specialAllowance'] as num?)?.toDouble(),
    grossSalary: (j['grossSalary'] as num?)?.toDouble(),
    employerEPF: (j['employerEPF'] as num?)?.toDouble(),
    costToCompany: (j['costToCompany'] as num?)?.toDouble(),
    employeeEPF: (j['employeeEPF'] as num?)?.toDouble(),
    gratuity: (j['gratuity'] as num?)?.toDouble(),
    benevolentFund: (j['benevolentFund'] as num?)?.toDouble(),
    netSalary: (j['netSalary'] as num?)?.toDouble(),
    currency: j['currency'] as String?,
    payFrequency: j['payFrequency'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'basic': basic,
    'hra': hra,
    'medicalConveyance': medicalConveyance,
    'conveyanceAllowance': conveyanceAllowance,
    'specialAllowance': specialAllowance,
    'grossSalary': grossSalary,
    'employerEPF': employerEPF,
    'costToCompany': costToCompany,
    'employeeEPF': employeeEPF,
    'gratuity': gratuity,
    'benevolentFund': benevolentFund,
    'netSalary': netSalary,
    'currency': currency,
    'payFrequency': payFrequency,
  };
}

// ---------- LeaveBalance (only casual + combo) ----------
class LeaveBalance {
  final int? casual;
  final int? combo;

  LeaveBalance({this.casual, this.combo});

  factory LeaveBalance.fromJson(Map<String, dynamic> j) => LeaveBalance(
    casual: (j['casual'] as num?)?.toInt(),
    combo: (j['combo'] as num?)?.toInt(),
  );

  Map<String, dynamic> toJson() => {
    'casual': casual,
    'combo': combo,
  };
}

// ---------- BankDetails ----------
class BankDetails {
  final String? accountNumber;
  final String? bankName;
  final String? ifscCode;
  final String? accountHolderName;

  BankDetails({
    this.accountNumber,
    this.bankName,
    this.ifscCode,
    this.accountHolderName,
  });

  factory BankDetails.fromJson(Map<String, dynamic> j) => BankDetails(
    accountNumber: j['accountNumber'] as String?,
    bankName: j['bankName'] as String?,
    ifscCode: j['ifscCode'] as String?,
    accountHolderName: j['accountHolderName'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'accountNumber': accountNumber,
    'bankName': bankName,
    'ifscCode': ifscCode,
    'accountHolderName': accountHolderName,
  };
}

// ---------- Address ----------
class Address {
  final String? street;
  final String? city;
  final String? state;
  final String? country;
  final String? postalCode;

  Address({
    this.street,
    this.city,
    this.state,
    this.country,
    this.postalCode,
  });

  factory Address.fromJson(Map<String, dynamic> j) => Address(
    street: j['street'] as String?,
    city: j['city'] as String?,
    state: j['state'] as String?,
    country: j['country'] as String?,
    postalCode: j['postalCode'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'street': street,
    'city': city,
    'state': state,
    'country': country,
    'postalCode': postalCode,
  };
}

// ---------- Shift ----------
class Shift {
  final String? id;
  final String? name;
  final String? code;
  final String? startTime;
  final String? endTime;
  final int? breakDuration;
  final int? gracePeriod;
  final String? displayTiming;

  Shift({
    this.id,
    this.name,
    this.code,
    this.startTime,
    this.endTime,
    this.breakDuration,
    this.gracePeriod,
    this.displayTiming,
  });

  factory Shift.fromJson(Map<String, dynamic> j) => Shift(
    id: j['_id'] as String? ?? j['id'] as String?,
    name: j['name'] as String?,
    code: j['code'] as String?,
    startTime: j['startTime'] as String?,
    endTime: j['endTime'] as String?,
    breakDuration: (j['breakDuration'] as num?)?.toInt(),
    gracePeriod: (j['gracePeriod'] as num?)?.toInt(),
    displayTiming: j['displayTiming'] as String?,
  );

  Map<String, dynamic> toJson() => {
    '_id': id,
    'name': name,
    'code': code,
    'startTime': startTime,
    'endTime': endTime,
    'breakDuration': breakDuration,
    'gracePeriod': gracePeriod,
    'displayTiming': displayTiming,
  };
}

class ReportingManager {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String profilePicture;
  final String fullName;
  final int? daysToAnniversary;

  ReportingManager({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.profilePicture,
    required this.fullName,
    this.daysToAnniversary,
  });

  factory ReportingManager.fromJson(Map<String, dynamic> json) {
    return ReportingManager(
      id: json['_id'] ?? json['id'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      email: json['email'] ?? '',
      profilePicture: json['profilePicture'] ?? '',
      fullName: json['fullName'] ?? '',
      daysToAnniversary: json['daysToAnniversary'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'profilePicture': profilePicture,
      'fullName': fullName,
      'daysToAnniversary': daysToAnniversary,
    };
  }
}

class EmergencyContact {
  final String name;
  final String phone;

  EmergencyContact({
    required this.name,
    required this.phone,
  });

  factory EmergencyContact.fromJson(Map<String, dynamic> json) {
    return EmergencyContact(
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'phone': phone,
    };
  }
}