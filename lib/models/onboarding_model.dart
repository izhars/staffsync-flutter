class OnboardingModel {
  final String id;
  final String status;         // pending | in-progress | completed | cancelled
  final int progress;          // 0..100
  final DateTime? startDate;
  final DateTime? targetCompletionDate;
  final List<ChecklistItemModel> checklist;
  final List<DocumentModel> documents;
  final List<LinkedTaskModel> tasks;
  final EmployeeModel? employee;

  OnboardingModel({
    required this.id,
    required this.status,
    required this.progress,
    this.startDate,
    this.targetCompletionDate,
    required this.checklist,
    required this.documents,
    required this.tasks,
    this.employee,
  });

  factory OnboardingModel.fromJson(Map<String, dynamic> j) {
    return OnboardingModel(
      id: j['_id'] ?? '',
      status: j['status'] ?? 'pending',
      progress: j['progress'] is num
          ? (j['progress'] as num).toInt()
          : 0,
      startDate: j['startDate'] != null
          ? DateTime.tryParse(j['startDate'])
          : null,
      targetCompletionDate: j['targetCompletionDate'] != null
          ? DateTime.tryParse(j['targetCompletionDate'])
          : null,
      checklist: (j['checklist'] as List? ?? [])
          .map((e) => ChecklistItemModel.fromJson(e))
          .toList(),
      documents: (j['documents'] as List? ?? [])
          .map((e) => DocumentModel.fromJson(e))
          .toList(),
      tasks: (j['taskIds'] as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .map((e) => LinkedTaskModel.fromJson(e))
          .toList(),
      employee: j['employee'] is Map
          ? EmployeeModel.fromJson(j['employee'])
          : null,
    );
  }

  /// Document item ke checklist category 'document' hain — HR verify karta hai,
  /// employee upload karta hai. Ye helper usi ko represent karta hai.
  List<ChecklistItemModel> get documentChecklist =>
      checklist.where((c) => c.category == 'document').toList();

  List<ChecklistItemModel> get taskChecklist =>
      checklist.where((c) => c.category == 'task').toList();
}

class ChecklistItemModel {
  final String key;
  final String label;
  final String category; // 'document' | 'task'
  final bool required;
  final bool completed;
  final DateTime? completedAt;
  final String? taskId;

  ChecklistItemModel({
    required this.key,
    required this.label,
    required this.category,
    required this.required,
    required this.completed,
    this.completedAt,
    this.taskId,
  });

  factory ChecklistItemModel.fromJson(Map<String, dynamic> j) =>
      ChecklistItemModel(
        key: j['key'] ?? '',
        label: j['label'] ?? '',
        category: j['category'] ?? 'task',
        required: j['required'] == true,
        completed: j['completed'] == true,
        completedAt: j['completedAt'] != null
            ? DateTime.tryParse(j['completedAt'])
            : null,
        taskId: j['taskId']?.toString(),
      );
}

class DocumentModel {
  final String id;
  final String type;
  final String fileName;
  final String fileUrl;
  final int? fileSize;
  final String? mimeType;
  final bool verified;
  final String? notes;
  final DateTime? uploadedAt;

  DocumentModel({
    required this.id,
    required this.type,
    required this.fileName,
    required this.fileUrl,
    this.fileSize,
    this.mimeType,
    required this.verified,
    this.notes,
    this.uploadedAt,
  });

  factory DocumentModel.fromJson(Map<String, dynamic> j) => DocumentModel(
    id: j['_id'] ?? '',
    type: j['type'] ?? 'other',
    fileName: j['fileName'] ?? '',
    fileUrl: j['fileUrl'] ?? '',
    fileSize: (j['fileSize'] is num)
        ? (j['fileSize'] as num).toInt()
        : null,
    mimeType: j['mimeType'],
    verified: j['verified'] == true,
    notes: j['notes'],
    uploadedAt: (j['uploadedAt'] ?? j['createdAt']) != null
        ? DateTime.tryParse(j['uploadedAt'] ?? j['createdAt'])
        : null,
  );
}

class LinkedTaskModel {
  final String id;
  final String title;
  final String category;
  final String status;
  final DateTime? dueDate;
  final String assigneeName;

  LinkedTaskModel({
    required this.id,
    required this.title,
    required this.category,
    required this.status,
    this.dueDate,
    required this.assigneeName,
  });

  factory LinkedTaskModel.fromJson(Map<String, dynamic> j) {
    final a = j['assignee'];
    final assigneeName = a is Map
        ? '${a['firstName'] ?? ''} ${a['lastName'] ?? ''}'.trim()
        : '';
    return LinkedTaskModel(
      id: j['_id'] ?? '',
      title: j['title'] ?? '',
      category: j['category'] ?? '',
      status: j['status'] ?? 'pending',
      dueDate:
      j['dueDate'] != null ? DateTime.tryParse(j['dueDate']) : null,
      assigneeName: assigneeName,
    );
  }
}

class EmployeeModel {
  final String firstName;
  final String lastName;
  final String employeeId;
  final String email;

  EmployeeModel({
    required this.firstName,
    required this.lastName,
    required this.employeeId,
    required this.email,
  });

  factory EmployeeModel.fromJson(Map<String, dynamic> j) => EmployeeModel(
    firstName: j['firstName'] ?? '',
    lastName: j['lastName'] ?? '',
    employeeId: j['employeeId'] ?? '',
    email: j['email'] ?? '',
  );

  String get fullName => '$firstName $lastName'.trim();
}