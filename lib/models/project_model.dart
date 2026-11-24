// models/project_model.dart
import 'package:staffsync/models/role_model.dart';

class Project {
  final String id;
  final String name;
  final String code;
  final String description;
  final DateTime startDate;
  final DateTime endDate;
  final String status;
  final double budgetAllocated;
  final double budgetSpent;
  final String currency;
  final List<String> tags;
  final Manager manager;
  final List<TeamMember> teamMembers;
  final int duration;
  final double budgetUtilization;
  final int progress;
  final String priority;
  final DateTime createdAt;
  final DateTime updatedAt;

  Project({
    required this.id,
    required this.name,
    required this.code,
    required this.description,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.budgetAllocated,
    required this.budgetSpent,
    required this.currency,
    required this.tags,
    required this.manager,
    required this.teamMembers,
    required this.duration,
    required this.budgetUtilization,
    this.progress = 0,
    this.priority = 'medium',
    required this.createdAt,
    required this.updatedAt,
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      code: json['code'] ?? '',
      description: json['description'] ?? '',
      startDate: DateTime.parse(json['startDate'] ?? DateTime.now().toIso8601String()),
      endDate: DateTime.parse(json['endDate'] ?? DateTime.now().toIso8601String()),
      status: json['status'] ?? 'planning',
      budgetAllocated: json['budget'] is Map
          ? (json['budget']['allocated'] ?? 0.0).toDouble()
          : 0.0,
      budgetSpent: json['budget'] is Map
          ? (json['budget']['spent'] ?? 0.0).toDouble()
          : 0.0,
      currency: json['budget'] is Map
          ? json['budget']['currency'] ?? 'USD'
          : 'USD',
      tags: List<String>.from(json['tags'] ?? []),
      manager: Manager.fromJson(json['manager'] is Map ? json['manager'] : {'_id': '', 'fullName': 'Unknown'}),
      teamMembers: json['teamMembers'] is List
          ? List<TeamMember>.from(json['teamMembers'].map((x) => TeamMember.fromJson(x)))
          : [],
      duration: json['duration'] ?? 0,
      budgetUtilization: (json['budgetUtilization'] ?? 0.0).toDouble(),
      progress: (json['progress'] ?? 0) is int
          ? json['progress'] ?? 0
          : (json['progress'] as num?)?.toInt() ?? 0,
      priority: json['priority'] ?? 'medium',
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}

class Manager {
  final String id;
  final String fullName;
  final String? firstName;
  final String? lastName;
  final String? email;

  Manager({
    required this.id,
    required this.fullName,
    this.firstName,
    this.lastName,
    this.email,
  });

  factory Manager.fromJson(Map<String, dynamic> json) {
    return Manager(
      id: json['_id'] ?? json['id'] ?? '',
      fullName: json['fullName'] ?? '${json['firstName'] ?? ''} ${json['lastName'] ?? ''}'.trim(),
      firstName: json['firstName'],
      lastName: json['lastName'],
      email: json['email'],
    );
  }
}

class TeamMember {
  final String id;
  final Employee employee;
  final ProjectRole role;
  final int allocation;
  final DateTime startDate;
  final bool isActive;
  final List<Responsibility>? responsibilities;

  TeamMember({
    required this.id,
    required this.employee,
    required this.role,
    required this.allocation,
    required this.startDate,
    required this.isActive,
    this.responsibilities,
  });

  factory TeamMember.fromJson(Map<String, dynamic> json) {
    return TeamMember(
      id: json['_id'] ?? json['id'] ?? '',
      employee: Employee.fromJson(json['employee'] is Map ? json['employee'] : {}),
      role: ProjectRole.fromJson(json['role'] is Map ? json['role'] : {}),
      allocation: json['allocation'] ?? 0,
      startDate: DateTime.parse(json['startDate'] ?? DateTime.now().toIso8601String()),
      isActive: json['isActive'] ?? true,
      responsibilities: json['responsibilities'] is List
          ? List<Responsibility>.from(
        json['responsibilities'].map((x) => Responsibility.fromJson(x)),
      )
          : null,
    );
  }
}

class Employee {
  final String id;
  final String fullName;

  Employee({required this.id, required this.fullName});

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: json['_id'] ?? json['id'] ?? '',
      fullName: json['fullName'] ?? '${json['firstName'] ?? ''} ${json['lastName'] ?? ''}'.trim(),
    );
  }
}

class Expense {
  final String id;
  final double amount;
  final String? remark;
  final DateTime date;
  final Map<String, dynamic>? recordedBy;

  Expense({
    required this.id,
    required this.amount,
    this.remark,
    required this.date,
    this.recordedBy,
  });

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'] ?? json['_id'] ?? '',
      amount: (json['amount'] as num).toDouble(),
      remark: json['remark'],
      date: DateTime.parse(json['date']),
      recordedBy: json['recordedBy'],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Project Chat & Tasks Models
// ─────────────────────────────────────────────────────────────

class ProjectMessage {
  final String id;
  final String projectId;
  final String senderId;
  final String senderName;
  final String? senderAvatar;
  final String text;
  final List<ProjectAttachment> attachments;
  final DateTime createdAt;

  ProjectMessage({
    required this.id,
    required this.projectId,
    required this.senderId,
    required this.senderName,
    this.senderAvatar,
    required this.text,
    required this.attachments,
    required this.createdAt,
  });

  factory ProjectMessage.fromJson(Map<String, dynamic> json) {
    final sender = json['sender'];
    String sId = '';
    String sName = 'Member';
    String? sAvatar;
    if (sender is Map) {
      sId = sender['_id'] ?? sender['id'] ?? '';
      sName = '${sender['firstName'] ?? ''} ${sender['lastName'] ?? ''}'.trim();
      if (sName.isEmpty) sName = sender['email'] ?? 'Member';
      if (sender['profilePicture'] is Map) {
        sAvatar = sender['profilePicture']['url'];
      }
    } else if (sender is String) {
      sId = sender;
    }

    final attList = json['attachments'] is List
        ? (json['attachments'] as List)
            .map((a) => ProjectAttachment.fromJson(a is Map<String, dynamic> ? a : {}))
            .toList()
        : <ProjectAttachment>[];

    return ProjectMessage(
      id: json['_id'] ?? json['id'] ?? '',
      projectId: json['project'] is Map ? (json['project']['_id'] ?? '') : (json['project'] ?? ''),
      senderId: sId,
      senderName: sName,
      senderAvatar: sAvatar,
      text: json['text'] ?? '',
      attachments: attList,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }
}

class ProjectAttachment {
  final String url;
  final String name;
  final String type;
  final int size;

  ProjectAttachment({
    required this.url,
    required this.name,
    required this.type,
    required this.size,
  });

  factory ProjectAttachment.fromJson(Map<String, dynamic> json) {
    return ProjectAttachment(
      url: json['url'] ?? '',
      name: json['name'] ?? '',
      type: json['type'] ?? 'file',
      size: (json['size'] ?? 0) is int ? json['size'] ?? 0 : (json['size'] as num?)?.toInt() ?? 0,
    );
  }
}

class ProjectTaskItem {
  final String id;
  final String title;
  final String description;
  final String status;
  final String priority;
  final String assigneeName;
  final String assigneeId;
  final DateTime? dueDate;

  ProjectTaskItem({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.priority,
    required this.assigneeName,
    required this.assigneeId,
    this.dueDate,
  });

  factory ProjectTaskItem.fromJson(Map<String, dynamic> json) {
    final assignee = json['assignee'];
    String aName = 'Unassigned';
    String aId = '';
    if (assignee is Map) {
      aId = assignee['_id'] ?? assignee['id'] ?? '';
      aName = '${assignee['firstName'] ?? ''} ${assignee['lastName'] ?? ''}'.trim();
      if (aName.isEmpty) aName = assignee['email'] ?? 'Member';
    } else if (assignee is String) {
      aId = assignee;
    }

    return ProjectTaskItem(
      id: json['_id'] ?? json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      status: json['status'] ?? 'open',
      priority: json['priority'] ?? 'medium',
      assigneeName: aName,
      assigneeId: aId,
      dueDate: json['dueDate'] != null ? DateTime.tryParse(json['dueDate']) : null,
    );
  }
}
