import 'package:flutter/material.dart';

class GroupParticipant {
  final String id;
  final String userId;
  final String role; // 'owner', 'admin', 'member'
  final DateTime joinedAt;
  final bool isActive;
  final Map<String, dynamic> notificationSettings;
  final Map<String, dynamic> user;

  GroupParticipant({
    required this.id,
    required this.userId,
    required this.role,
    required this.joinedAt,
    required this.isActive,
    required this.notificationSettings,
    required this.user,
  });

  factory GroupParticipant.fromJson(Map<String, dynamic> json) {
    return GroupParticipant(
      id: json['_id'] ?? json['id'] ?? '',
      userId: json['user']?['_id'] ?? '',
      role: json['role'] ?? 'member',
      joinedAt: DateTime.parse(json['joinedAt']),
      isActive: json['isActive'] ?? true,
      notificationSettings: Map<String, dynamic>.from(json['notificationSettings'] ?? {}),
      user: Map<String, dynamic>.from(json['user'] ?? {}),
    );
  }

  String get fullName {
    final firstName = user['firstName'] ?? '';
    final lastName = user['lastName'] ?? '';
    if (firstName.isNotEmpty && lastName.isNotEmpty) {
      return '$firstName $lastName';
    }
    return firstName.isNotEmpty ? firstName : user['email'] ?? '';
  }

  String get email => user['email'] ?? '';
  String get profilePicture => user['profilePicture'] ?? '';
  String get userRole => user['role'] ?? '';
}

class GroupSettings {
  final bool isPublic;
  final bool approvalRequired;
  final bool allowMedia;
  final bool allowReactions;
  final bool allowEditing;
  final int maxParticipants;

  GroupSettings({
    required this.isPublic,
    required this.approvalRequired,
    required this.allowMedia,
    required this.allowReactions,
    required this.allowEditing,
    required this.maxParticipants,
  });

  factory GroupSettings.fromJson(Map<String, dynamic> json) {
    return GroupSettings(
      isPublic: json['isPublic'] ?? false,
      approvalRequired: json['approvalRequired'] ?? false,
      allowMedia: json['allowMedia'] ?? true,
      allowReactions: json['allowReactions'] ?? true,
      allowEditing: json['allowEditing'] ?? true,
      maxParticipants: json['maxParticipants'] ?? 100,
    );
  }
}

class Group {
  final String id;
  final String name;
  final String description;
  final String type;
  final bool isDirect;
  final bool isArchived;
  final List<GroupParticipant> participants;
  final List<dynamic> directParticipants;
  final List<dynamic> tags;
  final GroupSettings settings;
  final Map<String, dynamic> createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int messageCount;
  final int unreadCount;
  final GroupAvatar avatar;
  List<Map<String, dynamic>> admins;

  Group({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.isDirect,
    required this.isArchived,
    required this.participants,
    required this.directParticipants,
    required this.tags,
    required this.settings,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    required this.messageCount,
    required this.unreadCount,
    required this.avatar, // 👈 ADD
    required this.admins,
  });

  factory Group.fromJson(Map<String, dynamic> json) {
    // Extract participants
    final participants = (json['participants'] as List? ?? []).map((p) {
      return GroupParticipant.fromJson(Map<String, dynamic>.from(p));
    }).toList();

    // Extract admins - both owner and admin roles
    final admins = <Map<String, dynamic>>[];

    for (var participant in participants) {
      if (participant.role == 'owner' || participant.role == 'admin') {
        admins.add({
          '_id': participant.userId,
          'firstName': participant.user['firstName'],
          'lastName': participant.user['lastName'],
          'email': participant.user['email'],
          'role': participant.role,
        });
      }
    }

    // Handle createdBy field (could be string or object)
    Map<String, dynamic> createdByData;
    if (json['createdBy'] is Map) {
      createdByData = Map<String, dynamic>.from(json['createdBy']);
    } else {
      createdByData = {
        '_id': json['createdBy']?.toString() ?? '',
        'firstName': '',
        'lastName': ''
      };
    }

    return Group(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      type: json['type'] ?? 'group',
      isDirect: json['isDirect'] ?? false,
      isArchived: json['isArchived'] ?? false,
      participants: participants,
      directParticipants: json['directParticipants'] ?? [],
      tags: json['tags'] ?? [],
      settings: GroupSettings.fromJson(Map<String, dynamic>.from(json['settings'] ?? {})),
      createdBy: createdByData,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      messageCount: json['messageCount'] ?? 0,
      unreadCount: json['unreadCount'] ?? 0,
      avatar: GroupAvatar.fromJson(
        json['avatar'] as Map<String, dynamic>?,
      ),
      admins: admins,
    );
  }

  // Helper getters
  int get memberCount => participants.length;
  bool get isPublic => settings.isPublic;

  // Check if current user is admin
  bool get isAdmin {
    if (currentUserId == null) return false;
    return admins.any((admin) => admin['_id'] == currentUserId);
  }

  // Check if current user is owner
  bool get isOwner {
    if (currentUserId == null) return false;
    return participants.any((p) =>
    p.userId == currentUserId && p.role == 'owner'
    );
  }

  // This should be set based on current logged in user
  String? currentUserId;

  List<GroupParticipant> get activeParticipants =>
      participants.where((p) => p.isActive).toList();

  // Get current user's participant info
  GroupParticipant? get currentUserParticipant {
    if (currentUserId == null) return null;
    return participants.firstWhere(
          (p) => p.userId == currentUserId,
      orElse: () => GroupParticipant.fromJson({}),
    );
  }

  // Get creator name
  String get creatorName {
    final firstName = createdBy['firstName'] ?? '';
    final lastName = createdBy['lastName'] ?? '';
    if (firstName.isNotEmpty && lastName.isNotEmpty) {
      return '$firstName $lastName';
    }
    return firstName.isNotEmpty ? firstName : createdBy['email'] ?? 'Unknown';
  }
}

class GroupAvatar {
  final String url;
  final String publicId;

  GroupAvatar({
    required this.url,
    required this.publicId,
  });

  factory GroupAvatar.fromJson(Map<String, dynamic>? json) {
    return GroupAvatar(
      url: json?['url'] ?? 'https://i.pravatar.cc/300',
      publicId: json?['publicId'] ?? '',
    );
  }
}
