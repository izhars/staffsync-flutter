class Expense {
  final String? id;
  final String employeeId;
  final double amount;
  final String description;
  final String categoryId;
  final String? categoryName;
  final DateTime date;
  final String? receiptPath;
  final String status; // draft, submitted, approved, rejected
  final DateTime? submittedAt;
  final DateTime? approvedAt;
  final DateTime? rejectedAt;
  final String? approvedByName;
  final String? rejectedByName;
  final String? approvalComments;
  final String? rejectionReason;
  final String? hrComments;
  final DateTime createdAt;
  final DateTime updatedAt;

  Expense({
    this.id,
    required this.employeeId,
    required this.amount,
    required this.description,
    required this.categoryId,
    this.categoryName,
    required this.date,
    this.receiptPath,
    this.status = 'draft',
    this.submittedAt,
    this.approvedAt,
    this.rejectedAt,
    this.approvedByName,
    this.rejectedByName,
    this.approvalComments,
    this.rejectionReason,
    this.hrComments,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['_id'] ?? json['id'],
      employeeId: json['employee'] is Map
          ? json['employee']['_id'] ?? json['employee']['id']
          : json['employee'].toString(),
      amount: json['amount'] is int
          ? (json['amount'] as int).toDouble()
          : json['amount']?.toDouble() ?? 0.0,
      description: json['description'] ?? '',
      categoryId: json['category'] is Map
          ? json['category']['_id'] ?? json['category']['id']
          : json['category'].toString(),
      categoryName: json['category'] is Map
          ? json['category']['name']
          : null,
      date: json['date'] != null
          ? DateTime.parse(json['date']).toLocal()
          : DateTime.now(),
      receiptPath: json['receipt'],
      status: json['status'] ?? 'draft',
      submittedAt: json['submittedAt'] != null
          ? DateTime.parse(json['submittedAt']).toLocal()
          : null,
      approvedAt: json['approvedAt'] != null
          ? DateTime.parse(json['approvedAt']).toLocal()
          : null,
      rejectedAt: json['rejectedAt'] != null
          ? DateTime.parse(json['rejectedAt']).toLocal()
          : null,
      approvedByName: json['approvedBy'] is Map
          ? json['approvedBy']['name']
          : null,
      rejectedByName: json['rejectedBy'] is Map
          ? json['rejectedBy']['name']
          : null,
      approvalComments: json['approvalComments'],
      rejectionReason: json['rejectionReason'],
      hrComments: json['hrComments'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt']).toLocal()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt']).toLocal()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'amount': amount,
      'description': description,
      'category': categoryId,
      'date': date.toIso8601String(),
      if (receiptPath != null) 'receipt': receiptPath,
      'status': status,
    };
  }

  Expense copyWith({
    String? id,
    String? employeeId,
    double? amount,
    String? description,
    String? categoryId,
    String? categoryName,
    DateTime? date,
    String? receiptPath,
    String? status,
    DateTime? submittedAt,
    DateTime? approvedAt,
    DateTime? rejectedAt,
    String? approvedByName,
    String? rejectedByName,
    String? approvalComments,
    String? rejectionReason,
    String? hrComments,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Expense(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      date: date ?? this.date,
      receiptPath: receiptPath ?? this.receiptPath,
      status: status ?? this.status,
      submittedAt: submittedAt ?? this.submittedAt,
      approvedAt: approvedAt ?? this.approvedAt,
      rejectedAt: rejectedAt ?? this.rejectedAt,
      approvedByName: approvedByName ?? this.approvedByName,
      rejectedByName: rejectedByName ?? this.rejectedByName,
      approvalComments: approvalComments ?? this.approvalComments,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      hrComments: hrComments ?? this.hrComments,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isDraft => status == 'draft';
  bool get isSubmitted => status == 'submitted';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';
  bool get isEditable => isDraft || (isRejected && hrComments != null);

  String get formattedAmount => '₹${amount.toStringAsFixed(2)}';

  String get formattedDate {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final expenseDay = DateTime(date.year, date.month, date.day);

    if (expenseDay == today) {
      return 'Today';
    } else if (expenseDay == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  String get statusText {
    switch (status) {
      case 'draft':
        return 'Draft';
      case 'submitted':
        return 'Pending Approval';
      case 'approved':
        return 'Approved';
      case 'rejected':
        return 'Rejected';
      default:
        return 'Unknown';
    }
  }

  int get statusColor {
    switch (status) {
      case 'draft':
        return 0xFFF59E0B; // Amber
      case 'submitted':
        return 0xFF3B82F6; // Blue
      case 'approved':
        return 0xFF10B981; // Green
      case 'rejected':
        return 0xFFEF4444; // Red
      default:
        return 0xFF6B7280; // Gray
    }
  }
}


class Category {
  final String id;
  final String name;

  Category({required this.id, required this.name});

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['_id'], // <-- important: use _id from backend
      name: json['name'],
    );
  }
}