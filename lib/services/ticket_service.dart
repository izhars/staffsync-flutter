// lib/services/ticket_service.dart
import '../models/ticket_model.dart';
import 'api_endpoints.dart';
import 'api_exception.dart';
import 'network_service.dart';

class TicketService {
  static final TicketService _instance = TicketService._internal();
  factory TicketService() => _instance;
  TicketService._internal();

  final NetworkService _networkService = NetworkService();

  /// Create a new support ticket
  Future<TicketModel> createTicket({
    required String subject,
    required String category,
    required String priority,
    required String description,
    List<Map<String, dynamic>> attachments = const [],
  }) async {
    try {
      final response = await _networkService.post(
        '/${ApiEndpoints.tickets}',
        {
          'subject': subject.trim(),
          'category': category,
          'priority': priority,
          'description': description.trim(),
          'attachments': attachments,
        },
      );

      final data = response['data'] ?? response['ticket'] ?? response;
      return TicketModel.fromJson(Map<String, dynamic>.from(data));
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(statusCode: 500, message: 'Failed to create ticket: $e');
    }
  }

  /// Get the current employee's tickets
  Future<List<TicketModel>> getMyTickets({
    int page = 1,
    int limit = 50,
    String? status,
    String? category,
    String? search,
  }) async {
    try {
      final query = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
        if (status != null && status != 'all' && status.isNotEmpty) 'status': status,
        if (category != null && category != 'all' && category.isNotEmpty) 'category': category,
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      };

      final response = await _networkService.get(
        '/${ApiEndpoints.myTickets}',
        query: query,
      );

      final dynamic list = response['data'] ?? response['tickets'] ?? [];
      if (list is List) {
        return list
            .map((item) => TicketModel.fromJson(Map<String, dynamic>.from(item)))
            .toList();
      }
      return [];
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(statusCode: 500, message: 'Failed to fetch tickets: $e');
    }
  }

  /// Get ticket details with full reply thread
  Future<TicketModel> getTicketDetails(String ticketId) async {
    try {
      final response = await _networkService.get(
        '/${ApiEndpoints.tickets}/$ticketId',
      );

      final data = response['data'] ?? response['ticket'] ?? response;
      return TicketModel.fromJson(Map<String, dynamic>.from(data));
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(statusCode: 500, message: 'Failed to load ticket details: $e');
    }
  }

  /// Add a reply message to a ticket
  Future<TicketModel> addReply({
    required String ticketId,
    required String message,
    List<Map<String, dynamic>> attachments = const [],
  }) async {
    try {
      final response = await _networkService.post(
        '/${ApiEndpoints.tickets}/$ticketId/replies',
        {
          'message': message.trim(),
          'attachments': attachments,
        },
      );

      final data = response['data'] ?? response['ticket'] ?? response;
      return TicketModel.fromJson(Map<String, dynamic>.from(data));
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(statusCode: 500, message: 'Failed to post reply: $e');
    }
  }

  /// Update ticket status (e.g. Employee reopening or closing their ticket)
  Future<TicketModel> updateStatus({
    required String ticketId,
    required String status,
    String? notes,
  }) async {
    try {
      final response = await _networkService.patch(
        '/${ApiEndpoints.tickets}/$ticketId/status',
        {
          'status': status,
          if (notes != null && notes.isNotEmpty) 'notes': notes,
        },
      );

      final data = response['data'] ?? response['ticket'] ?? response;
      return TicketModel.fromJson(Map<String, dynamic>.from(data));
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(statusCode: 500, message: 'Failed to update ticket status: $e');
    }
  }
}
