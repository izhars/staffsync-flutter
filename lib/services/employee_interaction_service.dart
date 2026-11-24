
import 'network_service.dart';

class EmployeeInteractionService {
  static final NetworkService _network = NetworkService();

  static Future<EmployeeInteractionPage> fetchHistory({
    int page = 1,
    int limit = 10,
  }) async {
    final response = await _network.get(
      '/employee-interactions/history?page=$page&limit=$limit',
    );

    final List list = response['interactions'] ?? [];
    final pagination = response['pagination'] ?? {};

    return EmployeeInteractionPage(
      interactions: list
          .map((e) => EmployeeInteraction.fromJson(
        Map<String, dynamic>.from(e),
      ))
          .toList(),
      hasMore: pagination['hasMore'] ?? false,
      currentPage: pagination['page'] ?? page,
      limit: pagination['limit'] ?? limit,
      offset: pagination['offset'] ?? 0,
      count: pagination['count'] ?? list.length,
      hasNextPage: pagination['hasNextPage'] ?? false,
      hasPrevPage: pagination['hasPrevPage'] ?? false,
      nextPage: pagination['nextPage'],
      prevPage: pagination['prevPage'],
    );
  }
}

class EmployeeInteractionPage {
  final List<EmployeeInteraction> interactions;
  final bool hasMore;
  final int currentPage;
  final int limit;
  final int offset;
  final int count;
  final bool hasNextPage;
  final bool hasPrevPage;
  final int? nextPage;
  final int? prevPage;

  EmployeeInteractionPage({
    required this.interactions,
    required this.hasMore,
    required this.currentPage,
    required this.limit,
    required this.offset,
    required this.count,
    required this.hasNextPage,
    required this.hasPrevPage,
    this.nextPage,
    this.prevPage,
  });
}

class EmployeeInteraction {
  final String id;
  final String type;
  final String readableType;

  final String senderId;
  final String senderName;
  final String senderProfilePicture;

  final String receiverId;
  final String receiverName;
  final String receiverProfilePicture;

  final bool isIncoming;
  final bool isOutgoing;
  final bool notificationSent;

  final DateTime timestamp;
  final DateTime createdAt;

  // Call metadata
  final String? callType;
  final String? callStatus;
  final int? durationSeconds;
  final DateTime? endedAt;
  final DateTime? metadataTimestamp;

  EmployeeInteraction({
    required this.id,
    required this.type,
    required this.readableType,
    required this.senderId,
    required this.senderName,
    required this.senderProfilePicture,
    required this.receiverId,
    required this.receiverName,
    required this.receiverProfilePicture,
    required this.isIncoming,
    required this.isOutgoing,
    required this.notificationSent,
    required this.timestamp,
    required this.createdAt,
    this.callType,
    this.callStatus,
    this.durationSeconds,
    this.endedAt,
    this.metadataTimestamp,
  });

  // Other person's details
  String get counterpartName =>
      isIncoming ? senderName : receiverName;

  String get counterpartProfilePicture =>
      isIncoming ? senderProfilePicture : receiverProfilePicture;

  String get counterpartId =>
      isIncoming ? senderId : receiverId;

  factory EmployeeInteraction.fromJson(
      Map<String, dynamic> json,
      ) {
    final sender = Map<String, dynamic>.from(
      json['sender'] ?? {},
    );

    final receiver = Map<String, dynamic>.from(
      json['receiver'] ?? {},
    );

    final metadata = Map<String, dynamic>.from(
      json['metadata'] ?? {},
    );

    return EmployeeInteraction(
      id: json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      readableType: json['readableType']?.toString() ?? '',

      senderId: sender['id']?.toString() ?? '',
      senderName: sender['name']?.toString() ?? '',
      senderProfilePicture:
      sender['profilePicture']?.toString() ?? '',

      receiverId: receiver['id']?.toString() ?? '',
      receiverName: receiver['name']?.toString() ?? '',
      receiverProfilePicture:
      receiver['profilePicture']?.toString() ?? '',

      isIncoming: json['isIncoming'] == true,
      isOutgoing: json['isOutgoing'] == true,
      notificationSent: json['notificationSent'] == true,

      timestamp: DateTime.tryParse(
        json['timestamp']?.toString() ?? '',
      ) ??
          DateTime.now(),

      createdAt: DateTime.tryParse(
        json['createdAt']?.toString() ?? '',
      ) ??
          DateTime.now(),

      callType: metadata['callType']?.toString(),
      callStatus: metadata['callStatus']?.toString(),

      durationSeconds:
      (metadata['duration'] as num?)?.toInt(),

      endedAt: metadata['endedAt'] != null
          ? DateTime.tryParse(metadata['endedAt'].toString())
          : null,

      metadataTimestamp: metadata['timestamp'] != null
          ? DateTime.tryParse(metadata['timestamp'].toString())
          : null,
    );
  }
}
