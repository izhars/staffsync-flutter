// models/role_model.dart
import 'package:staffsync/models/project_model.dart';

class ProjectRole {
  final String id;
  final String name;
  final String code;
  final String description;
  final int level;
  final String reportsTo;
  final Map<String, bool> permissions;
  final List<Responsibility> responsibilities;
  final bool isSystemRole;
  final bool isActive;
  final Manager createdBy;
  final DateTime createdAt;

  ProjectRole({
    required this.id,
    required this.name,
    required this.code,
    required this.description,
    required this.level,
    this.reportsTo = 'Project Manager',
    required this.permissions,
    required this.responsibilities,
    required this.isSystemRole,
    required this.isActive,
    required this.createdBy,
    required this.createdAt,
  });

  factory ProjectRole.fromJson(Map<String, dynamic> json) {
    // Handle permissions - ensure it's a Map<String, bool>
    final permissionsJson = json['permissions'] ?? {};
    final Map<String, bool> permissions = {};

    if (permissionsJson is Map) {
      permissionsJson.forEach((key, value) {
        if (key is String && value is bool) {
          permissions[key] = value;
        }
      });
    }

    return ProjectRole(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      code: json['code'] ?? '',
      description: json['description'] ?? '',
      level: json['level'] ?? 1,
      reportsTo: json['reportsTo'] ?? 'Project Manager',
      permissions: permissions, // Use the properly parsed permissions
      responsibilities: json['defaultResponsibilities'] is List
          ? List<Responsibility>.from(
        json['defaultResponsibilities'].map((x) => Responsibility.fromJson(x)),
      )
          : [],
      isSystemRole: json['isSystemRole'] ?? false,
      isActive: json['isActive'] ?? true,
      createdBy: Manager.fromJson(json['createdBy'] is Map ? json['createdBy'] : {}),
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}

class Responsibility {
  String title;
  String description;
  String category;

  Responsibility({
    required this.title,
    required this.description,
    required this.category,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'category': category,
    };
  }

  factory Responsibility.fromJson(Map<String, dynamic> json) {
    return Responsibility(
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? '',
    );
  }
}