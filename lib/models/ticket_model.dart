// lib/models/ticket_model.dart

class TicketAttachment {
  final String url;
  final String filename;
  final String originalName;
  final String mimeType;
  final int? size;
  final String? publicId;

  TicketAttachment({
    required this.url,
    this.filename = '',
    this.originalName = '',
    this.mimeType = '',
    this.size,
    this.publicId,
  });

  factory TicketAttachment.fromJson(Map<String, dynamic> json) {
    return TicketAttachment(
      url: json['url']?.toString() ?? '',
      filename: json['filename']?.toString() ?? json['originalName']?.toString() ?? '',
      originalName: json['originalName']?.toString() ?? json['filename']?.toString() ?? '',
      mimeType: json['mimeType']?.toString() ?? '',
      size: (json['size'] as num?)?.toInt(),
      publicId: json['publicId']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'url': url,
    'filename': filename,
    'originalName': originalName,
    'mimeType': mimeType,
    if (size != null) 'size': size,
    if (publicId != null) 'publicId': publicId,
  };
}

class TicketReply {
  final String id;
  final Map<String, dynamic>? sender;
  final String message;
  final List<TicketAttachment> attachments;
  final bool isPrivateNote;
  final DateTime createdAt;

  TicketReply({
    required this.id,
    this.sender,
    required this.message,
    this.attachments = const [],
    this.isPrivateNote = false,
    required this.createdAt,
  });

  String get senderName {
    if (sender == null) return 'Staff';
    final first = sender!['firstName']?.toString() ?? '';
    final last = sender!['lastName']?.toString() ?? '';
    final full = '$first $last'.trim();
    if (full.isNotEmpty) return full;
    return sender!['employeeId']?.toString() ?? 'User';
  }

  String? get senderAvatar => sender?['profilePicture']?.toString();
  String get senderRole => sender?['role']?.toString() ?? 'User';

  factory TicketReply.fromJson(Map<String, dynamic> json) {
    return TicketReply(
      id: json['_id']?.toString() ?? '',
      sender: json['sender'] is Map<String, dynamic> ? json['sender'] : null,
      message: json['message']?.toString() ?? '',
      attachments: (json['attachments'] as List?)
          ?.map((a) => TicketAttachment.fromJson(Map<String, dynamic>.from(a)))
          .toList() ?? [],
      isPrivateNote: json['isPrivateNote'] == true,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    '_id': id,
    'message': message,
    'attachments': attachments.map((a) => a.toJson()).toList(),
    'isPrivateNote': isPrivateNote,
    'createdAt': createdAt.toIso8601String(),
  };
}

class TicketStatusHistory {
  final String status;
  final Map<String, dynamic>? changedBy;
  final String? notes;
  final DateTime changedAt;

  TicketStatusHistory({
    required this.status,
    this.changedBy,
    this.notes,
    required this.changedAt,
  });

  factory TicketStatusHistory.fromJson(Map<String, dynamic> json) {
    return TicketStatusHistory(
      status: json['status']?.toString() ?? '',
      changedBy: json['changedBy'] is Map<String, dynamic> ? json['changedBy'] : null,
      notes: json['notes']?.toString(),
      changedAt: json['changedAt'] != null
          ? DateTime.tryParse(json['changedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'status': status,
    'notes': notes,
    'changedAt': changedAt.toIso8601String(),
  };
}

class TicketModel {
  final String id;
  final String ticketId;
  final Map<String, dynamic>? user;
  final String subject;
  final String category;
  final String priority;
  final String status;
  final String description;
  final List<TicketAttachment> attachments;
  final Map<String, dynamic>? assignedTo;
  final List<TicketReply> replies;
  final List<TicketStatusHistory> statusHistory;
  final DateTime createdAt;
  final DateTime updatedAt;

  TicketModel({
    required this.id,
    required this.ticketId,
    this.user,
    required this.subject,
    required this.category,
    this.priority = 'Medium',
    this.status = 'Open',
    required this.description,
    this.attachments = const [],
    this.assignedTo,
    this.replies = const [],
    this.statusHistory = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  String get displayTicketId => ticketId.isNotEmpty ? ticketId : 'TIC-${id.length >= 6 ? id.substring(id.length - 6).toUpperCase() : id}';

  String get assignedToName {
    if (assignedTo == null) return 'Unassigned';
    final first = assignedTo!['firstName']?.toString() ?? '';
    final last = assignedTo!['lastName']?.toString() ?? '';
    final full = '$first $last'.trim();
    return full.isNotEmpty ? full : 'Support Staff';
  }

  factory TicketModel.fromJson(Map<String, dynamic> json) {
    return TicketModel(
      id: json['_id']?.toString() ?? '',
      ticketId: json['ticketId']?.toString() ?? '',
      user: json['user'] is Map<String, dynamic> ? json['user'] : null,
      subject: json['subject']?.toString() ?? '',
      category: json['category']?.toString() ?? 'Other',
      priority: json['priority']?.toString() ?? 'Medium',
      status: json['status']?.toString() ?? 'Open',
      description: json['description']?.toString() ?? json['message']?.toString() ?? '',
      attachments: (json['attachments'] as List?)
          ?.map((a) => TicketAttachment.fromJson(Map<String, dynamic>.from(a)))
          .toList() ?? [],
      assignedTo: json['assignedTo'] is Map<String, dynamic> ? json['assignedTo'] : null,
      replies: (json['replies'] as List?)
          ?.map((r) => TicketReply.fromJson(Map<String, dynamic>.from(r)))
          .toList() ?? [],
      statusHistory: (json['statusHistory'] as List?)
          ?.map((s) => TicketStatusHistory.fromJson(Map<String, dynamic>.from(s)))
          .toList() ?? [],
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    '_id': id,
    'ticketId': ticketId,
    'subject': subject,
    'category': category,
    'priority': priority,
    'status': status,
    'description': description,
    'attachments': attachments.map((a) => a.toJson()).toList(),
    'replies': replies.map((r) => r.toJson()).toList(),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };
}
