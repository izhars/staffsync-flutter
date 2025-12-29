import '../screens/chat_connection_screen.dart';

class ChatAttachment {
  final AttachmentType type;
  final String? url;
  final String? publicId;
  final String fileName;
  final int? fileSize;
  final String? mimeType;
  final String? localPath;
  final Map<String, dynamic>? metadata;

  ChatAttachment({
    required this.type,
    this.url,
    this.publicId,
    required this.fileName,
    this.fileSize,
    this.mimeType,
    this.localPath,
    this.metadata,
  });

  ChatAttachment copyWith({
    AttachmentType? type,
    String? url,
    String? publicId,
    String? fileName,
    int? fileSize,
    String? mimeType,
    String? localPath,
    Map<String, dynamic>? metadata,
  }) {
    return ChatAttachment(
      type: type ?? this.type,
      url: url ?? this.url,
      publicId: publicId ?? this.publicId,
      fileName: fileName ?? this.fileName,
      fileSize: fileSize ?? this.fileSize,
      mimeType: mimeType ?? this.mimeType,
      localPath: localPath ?? this.localPath,
      metadata: metadata ?? this.metadata,
    );
  }

  factory ChatAttachment.fromJson(Map<String, dynamic> json) {
    return ChatAttachment(
      type: _parseAttachmentType(json['type']),
      url: json['url'],
      publicId: json['publicId'],
      fileName: json['filename'] ?? 'File',
      fileSize: json['size'],
      mimeType: json['mimeType'],
      metadata: json['metadata'],
    );
  }

  static AttachmentType _parseAttachmentType(String type) {
    switch (type.toLowerCase()) {
      case 'image':
        return AttachmentType.image;
      case 'video':
        return AttachmentType.video;
      case 'audio':
        return AttachmentType.audio;
      case 'document':
        return AttachmentType.document;
      default:
        return AttachmentType.file;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'url': url,
      'publicId': publicId,
      'filename': fileName,
      'size': fileSize,
      'mimeType': mimeType,
      'metadata': metadata,
    };
  }
}

class ChatMessage {
  final String? id;
  final String text;
  final String fromUserId;
  final DateTime timestamp;
  final bool delivered;
  final bool read;
  final ChatAttachment? attachment;
  final UploadStatus? uploadStatus;
  final String? uploadError;

  MessageStatus get status {
    if (read) return MessageStatus.read;
    if (delivered) return MessageStatus.delivered;
    return MessageStatus.sent;
  }

  ChatMessage({
    this.id,
    required this.text,
    required this.fromUserId,
    required this.timestamp,
    this.delivered = false,
    this.read = false,
    this.attachment,
    this.uploadStatus,
    this.uploadError,
  });

  ChatMessage copyWith({
    String? id,
    String? text,
    String? fromUserId,
    DateTime? timestamp,
    bool? delivered,
    bool? read,
    ChatAttachment? attachment,
    UploadStatus? uploadStatus,
    String? uploadError,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      text: text ?? this.text,
      fromUserId: fromUserId ?? this.fromUserId,
      timestamp: timestamp ?? this.timestamp,
      delivered: delivered ?? this.delivered,
      read: read ?? this.read,
      attachment: attachment ?? this.attachment,
      uploadStatus: uploadStatus ?? this.uploadStatus,
      uploadError: uploadError ?? this.uploadError,
    );
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['_id']?.toString(),
      text: json['text'] ?? '',
      fromUserId: json['from']?.toString() ?? '', // This is the sender's ID
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
      delivered: json['deliveredAt'] != null,
      read: json['readAt'] != null,
      attachment: json['attachment'] != null
          ? ChatAttachment.fromJson(json['attachment'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'fromUserId': fromUserId,
      'timestamp': timestamp.toIso8601String(),
      'delivered': delivered,
      'read': read,
      'attachment': attachment?.toJson(),
      'uploadStatus': uploadStatus?.name,
      'uploadError': uploadError,
    };
  }
}

enum MessageStatus {
  sent,       // Single grey tick
  delivered,  // Double grey ticks
  read        // Double blue ticks
}