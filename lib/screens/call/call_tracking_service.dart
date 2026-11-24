import 'package:staffsync/services/network_service.dart';

class CallTrackingService {
  final NetworkService _network = NetworkService();

  /// Track any call interaction
  Future<Map<String, dynamic>> trackCallInteraction({
    required String receiverId,
    required String callStatus, // 'started', 'accepted', 'declined', 'ended', 'missed'
    String callType = 'audio',
    int duration = 0,
  }) async {
    try {
      print('📞 [trackCallInteraction] receiver: $receiverId, status: $callStatus, type: $callType');

      final response = await _network.post(
        '/employee-interactions/track-call',
        {
          'receiverId': receiverId,
          'callType': callType,
          'callStatus': callStatus,
          'duration': duration, // ✅ Use 'duration' not 'callDuration'
        },
      );

      print('✅ Call interaction tracked: $callStatus');
      return response;
    } catch (e) {
      print('❌ Error tracking call interaction: $e');
      rethrow;
    }
  }

  /// Track call end specifically
  Future<Map<String, dynamic>> trackCallEnd({
    required String receiverId,
    int callDuration = 0,
  }) async {
    try {
      print('📞 [trackCallEnd] receiver: $receiverId, duration: ${callDuration}s');

      final response = await _network.post(
        '/employee-interactions/track-call-end',
        {
          'receiverId': receiverId,
          'callDuration': callDuration, // ✅ Correct parameter name
        },
      );

      print('✅ Call end tracked');
      return response;
    } catch (e) {
      print('❌ Error tracking call end: $e');
      rethrow;
    }
  }
}