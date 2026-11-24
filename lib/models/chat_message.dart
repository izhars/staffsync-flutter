class Message {
  String id;
  String senderId;
  String senderName;
  String senderRole;
  String senderAvatar;
  String toUserId;
  String text;
  DateTime timestamp;

  /// 'sending', 'sent', 'delivered', 'read', 'error'
  String status;

  /// 'text', 'image', 'file'
  String messageType;

  Map<String, dynamic>? attachment;
  DateTime? deliveredAt;
  DateTime? readAt;
  String? conversationId;
  Map<String, dynamic>? metadata;

  /// 🆕 Local image before upload
  String? localImagePath;

  /// 🆕 Upload tracking
  String? uploadTaskId;
  double? uploadProgress; // 0.0 → 1.0

  Message({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.senderRole,
    required this.senderAvatar,
    required this.toUserId,
    required this.text,
    required this.timestamp,
    required this.status,
    required this.messageType,
    this.attachment,
    this.deliveredAt,
    this.readAt,
    this.conversationId,
    this.metadata,
    this.localImagePath,
    this.uploadTaskId,
    this.uploadProgress,
  });

  // ======================
  // 🧠 Smart getters
  // ======================

  bool get hasLocalImage =>
      localImagePath != null && localImagePath!.isNotEmpty;

  bool get isImage => messageType == 'image';

  bool get isUploading => status == 'sending';

  bool get hasUploadError => status == 'error';

  bool get isImageReady =>
      isImage &&
          attachment?['url']?.isNotEmpty == true &&
          !isUploading;

  // ======================
  // 🔁 copyWith (THE FIX)
  // ======================

  Message copyWith({
    String? id,
    String? senderId,
    String? senderName,
    String? senderRole,
    String? senderAvatar,
    String? toUserId,
    String? text,
    DateTime? timestamp,
    String? status,
    String? messageType,
    Map<String, dynamic>? attachment,
    DateTime? deliveredAt,
    DateTime? readAt,
    String? conversationId,
    Map<String, dynamic>? metadata,
    String? localImagePath,
    String? uploadTaskId,
    double? uploadProgress,
  }) {
    return Message(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderRole: senderRole ?? this.senderRole,
      senderAvatar: senderAvatar ?? this.senderAvatar,
      toUserId: toUserId ?? this.toUserId,
      text: text ?? this.text,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      messageType: messageType ?? this.messageType,
      attachment: attachment ?? this.attachment,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      readAt: readAt ?? this.readAt,
      conversationId: conversationId ?? this.conversationId,
      metadata: metadata ?? this.metadata,
      localImagePath: localImagePath ?? this.localImagePath,
      uploadTaskId: uploadTaskId ?? this.uploadTaskId,
      uploadProgress: uploadProgress ?? this.uploadProgress,
    );
  }

  // ======================
  // 🔁 From JSON
  // ======================

  factory Message.fromJson(Map<String, dynamic> json) {
    final id =
    (json['_id'] ?? json['id'] ?? DateTime.now().millisecondsSinceEpoch)
        .toString();

    final senderId = json['sender'] is Map
        ? json['sender']['_id']?.toString() ?? ''
        : (json['senderId'] ?? json['sender'] ?? '').toString();

    final toUserId = (json['to'] ?? json['toUserId'] ?? '').toString();

    DateTime timestamp;
    if (json['timestamp'] is String) {
      timestamp = DateTime.parse(json['timestamp']);
    } else if (json['timestamp'] != null) {
      timestamp = DateTime.fromMillisecondsSinceEpoch(json['timestamp']);
    } else if (json['createdAt'] is String) {
      timestamp = DateTime.parse(json['createdAt']);
    } else {
      timestamp = DateTime.now();
    }

    String senderName = '';
    if (json['senderName'] != null) {
      senderName = json['senderName'];
    } else if (json['sender'] is Map) {
      final first = json['sender']['firstName'] ?? '';
      final last = json['sender']['lastName'] ?? '';
      senderName = '$first $last'.trim();
    }

    return Message(
      id: id,
      senderId: senderId,
      senderName: senderName,
      senderRole: json['senderRole'] ??
          (json['sender'] is Map ? json['sender']['role'] : ''),
      senderAvatar: json['senderAvatar'] ??
          (json['sender'] is Map
              ? json['sender']['profilePicture']
              : '/default-avatar.png'),
      toUserId: toUserId,
      text: json['text'] ?? '',
      timestamp: timestamp,
      status: json['status'] ?? 'received',
      messageType: json['messageType'] ?? 'text',
      attachment: json['attachment'],
      deliveredAt: json['deliveredAt'] != null
          ? DateTime.parse(json['deliveredAt'])
          : null,
      readAt:
      json['readAt'] != null ? DateTime.parse(json['readAt']) : null,
      conversationId: json['conversationId']?.toString(),
      metadata: json['metadata'] is Map
          ? Map<String, dynamic>.from(json['metadata'])
          : null,
      uploadTaskId: json['uploadTaskId'],
      uploadProgress: (json['uploadProgress'] as num?)?.toDouble(),
      localImagePath: json['localImagePath'],
    );
  }

  // ======================
  // 🔁 To JSON
  // ======================

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderId': senderId,
      'senderName': senderName,
      'senderRole': senderRole,
      'senderAvatar': senderAvatar,
      'toUserId': toUserId,
      'text': text,
      'timestamp': timestamp.toIso8601String(),
      'status': status,
      'messageType': messageType,
      'attachment': attachment,
      'deliveredAt': deliveredAt?.toIso8601String(),
      'readAt': readAt?.toIso8601String(),
      'conversationId': conversationId,
      'metadata': metadata,
      'uploadTaskId': uploadTaskId,
      'uploadProgress': uploadProgress,
      'localImagePath': localImagePath,
    };
  }
}



// lib/models/conversation.dart
class Conversation {
  String id;
  String name;
  String type; // 'direct', 'group'
  List<dynamic> participants;
  Map<String, dynamic>? lastMessage;
  int messageCount;
  int unreadCount;
  DateTime updatedAt;
  DateTime createdAt;
  Map<String, dynamic>? otherParticipant;

  Conversation({
    required this.id,
    required this.name,
    required this.type,
    required this.participants,
    this.lastMessage,
    required this.messageCount,
    required this.unreadCount,
    required this.updatedAt,
    required this.createdAt,
    this.otherParticipant,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'] ?? json['_id'] ?? '',
      name: json['name'] ?? '',
      type: json['type'] ?? 'direct',
      participants: json['participants'] ?? [],
      lastMessage: json['lastMessage'],
      messageCount: json['messageCount'] ?? 0,
      unreadCount: json['unreadCount'] ?? 0,
      updatedAt: DateTime.parse(json['updatedAt']),
      createdAt: DateTime.parse(json['createdAt']),
      otherParticipant: json['otherParticipant'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'participants': participants,
      'lastMessage': lastMessage,
      'messageCount': messageCount,
      'unreadCount': unreadCount,
      'updatedAt': updatedAt.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'otherParticipant': otherParticipant,
    };
  }
}
