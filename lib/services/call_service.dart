import 'package:flutter/cupertino.dart';
import '../screens/call/call_tracking_service.dart';
import 'network_service.dart';

class CallService {
  final NetworkService _network = NetworkService();
  final CallTrackingService _callTracking = CallTrackingService();

  /// 🔹 Start a new call
  Future<Map<String, dynamic>> startCall(
      String receiverId,
      String callType, // 'audio' or 'video'
      ) async {
    try {
      debugPrint('📡 [startCall] Starting $callType call to $receiverId');

      final response = await _network.post(
        '/calls/start',
        {
          'receiverId': receiverId,
          'type': callType,
        },
      );

      debugPrint('📡 [startCall] Response: $response');

      if (response['success'] != true || response['callId'] == null) {
        throw Exception(response['error'] ?? 'Failed to start call');
      }

      return {
        'callId': response['callId'],
        'roomId': response['roomId'],
        'type': response['type'],
        'success': true,
      };
    } catch (e, stackTrace) {
      debugPrint('⚠️ [startCall] Exception: $e\n$stackTrace');
      rethrow;
    }
  }

  /// 🔹 Accept an incoming call
  Future<bool> acceptCall(String callId) async {
    try {
      debugPrint('✅ [acceptCall] Accepting call: $callId');

      final response = await _network.post("/calls/accept", {
        'callId': callId,
        'timestamp': DateTime.now().toIso8601String(),
      });

      debugPrint('📡 [acceptCall] Response: $response');

      if (response.containsKey('error')) {
        debugPrint('⚠️ [acceptCall] Failed: ${response['error']}');
        return false;
      }

      if (response['success'] == true) {
        debugPrint('✅ [acceptCall] Successfully accepted call');
        return true;
      }

      debugPrint('⚠️ [acceptCall] Unexpected response format');
      return false;
    } catch (e) {
      debugPrint('❌ [acceptCall] Error: $e');
      return false;
    }
  }

  /// 🔹 Decline an incoming call
  Future<bool> declineCall(String callId, {String reason = 'user_declined'}) async {
    try {
      debugPrint('❌ [declineCall] Declining call: $callId');

      final response = await _network.post("/calls/decline", {
        'callId': callId,
        'timestamp': DateTime.now().toIso8601String(),
        'reason': reason,
      });

      debugPrint('📡 [declineCall] Response: $response');

      if (response['success'] == true) {
        debugPrint('✅ [declineCall] Successfully declined call');
        return true;
      }

      debugPrint('⚠️ [declineCall] Failed: ${response['error']}');
      return false;
    } catch (e) {
      debugPrint('❌ [declineCall] Error: $e');
      return false;
    }
  }

  /// 🔹 End an ongoing call
  Future<bool> endCall(String callId, {String? reason}) async {
    try {
      debugPrint('📞 [endCall] Ending call: $callId');

      final Map<String, dynamic> payload = {
        'callId': callId,
        'timestamp': DateTime.now().toIso8601String(),
      };

      if (reason != null) {
        payload['reason'] = reason;
      }

      final response = await _network.post("/calls/end", payload);

      debugPrint('📡 [endCall] Response: $response');

      if (response['success'] == true) {
        debugPrint('✅ [endCall] Successfully ended call');
        return true;
      }

      debugPrint('⚠️ [endCall] Failed: ${response['error']}');
      return false;
    } catch (e) {
      debugPrint('❌ [endCall] Error: $e');
      return false;
    }
  }

  /// 🔹 Get call details by ID
  Future<Map<String, dynamic>?> getCallById(String callId) async {
    try {
      debugPrint('ℹ️ [getCallById] Fetching call: $callId');

      final response = await _network.get("/calls/$callId");

      if (response['success'] == true && response['call'] != null) {
        debugPrint('✅ [getCallById] Retrieved call details');
        return response['call'];
      }

      debugPrint('⚠️ [getCallById] Call not found');
      return null;
    } catch (e) {
      debugPrint('❌ [getCallById] Error: $e');
      return null;
    }
  }

  /// 🔹 Get call details by Room ID
  Future<Map<String, dynamic>?> getCallByRoomId(String roomId) async {
    try {
      debugPrint('ℹ️ [getCallByRoomId] Fetching call for room: $roomId');

      final response = await _network.get("/calls/room/$roomId");

      if (response['success'] == true && response['call'] != null) {
        debugPrint('✅ [getCallByRoomId] Retrieved call by room');
        return response['call'];
      }

      debugPrint('⚠️ [getCallByRoomId] Call not found for room');
      return null;
    } catch (e) {
      debugPrint('❌ [getCallByRoomId] Error: $e');
      return null;
    }
  }

  /// 🔹 Get ongoing calls for a user
  Future<List<Map<String, dynamic>>> getOngoingCalls(String userId) async {
    try {
      debugPrint('📋 [getOngoingCalls] Fetching ongoing calls for: $userId');

      final response = await _network.get("/calls/ongoing/$userId");

      if (response['success'] == true && response['calls'] != null) {
        final List<dynamic> list = response['calls'];
        debugPrint('✅ [getOngoingCalls] Retrieved ${list.length} calls');

        return list.map<Map<String, dynamic>>((call) {
          return {
            'id': call['_id'] ?? call['id'],
            'callId': call['callId'],
            'roomId': call['roomId'],
            'callerId': call['callerId'],
            'callerName': call['callerName'] ?? 'Unknown',
            'callerImage': call['callerImage'],
            'receiverId': call['receiverId'],
            'receiverName': call['receiverName'] ?? 'Unknown',
            'status': call['status'] ?? 'unknown',
            'startedAt': call['startedAt'],
            'endedAt': call['endedAt'],
            'type': call['type'] ?? 'video',
            'duration': call['duration'] ?? 0,
          };
        }).toList();
      }

      debugPrint('📋 [getOngoingCalls] No ongoing calls found');
      return [];
    } catch (e) {
      debugPrint('❌ [getOngoingCalls] Error: $e');
      return [];
    }
  }

  /// 🔹 Get call history for a user
  Future<List<Map<String, dynamic>>> getCallHistory(String userId) async {
    try {
      debugPrint('📜 [getCallHistory] Fetching history for: $userId');

      final response = await _network.get("/calls/history/$userId");

      if (response['success'] == true && response['calls'] != null) {
        final List<dynamic> list = response['calls'];
        debugPrint('✅ [getCallHistory] Retrieved ${list.length} historical calls');

        return list.map<Map<String, dynamic>>((call) {
          return {
            'id': call['_id'] ?? call['id'],
            'callId': call['callId'],
            'roomId': call['roomId'],
            'callerId': call['callerId'],
            'callerName': call['callerName'] ?? 'Unknown',
            'receiverId': call['receiverId'],
            'receiverName': call['receiverName'] ?? 'Unknown',
            'status': call['status'] ?? 'ended',
            'startedAt': call['startedAt'],
            'endedAt': call['endedAt'],
            'type': call['type'] ?? 'video',
            'duration': call['duration'] ?? 0,
          };
        }).toList();
      }

      debugPrint('📜 [getCallHistory] No call history found');
      return [];
    } catch (e) {
      debugPrint('❌ [getCallHistory] Error: $e');
      return [];
    }
  }

  /// 🔹 Get missed calls for a user
  Future<List<Map<String, dynamic>>> getMissedCalls(String userId) async {
    try {
      debugPrint('📱 [getMissedCalls] Fetching missed calls for: $userId');

      final response = await _network.get("/calls/missed/$userId");

      if (response['success'] == true && response['calls'] != null) {
        final List<dynamic> list = response['calls'];
        debugPrint('✅ [getMissedCalls] Retrieved ${list.length} missed calls');

        return list.map<Map<String, dynamic>>((call) {
          return {
            'id': call['_id'] ?? call['id'],
            'callId': call['callId'],
            'roomId': call['roomId'],
            'callerId': call['callerId'],
            'callerName': call['callerName'] ?? 'Unknown',
            'callerImage': call['callerImage'],
            'timestamp': call['timestamp'] ?? call['startedAt'],
            'type': call['type'] ?? 'audio',
          };
        }).toList();
      }

      debugPrint('📱 [getMissedCalls] No missed calls found');
      return [];
    } catch (e) {
      debugPrint('❌ [getMissedCalls] Error: $e');
      return [];
    }
  }

  /// 🔹 Update call status
  Future<bool> updateCallStatus(String callId, String status) async {
    try {
      debugPrint('🔄 [updateCallStatus] Updating call $callId to $status');

      final response = await _network.put("/calls/$callId/status", {
        'status': status,
        'updatedAt': DateTime.now().toIso8601String(),
      });

      if (response['success'] == true) {
        debugPrint('✅ [updateCallStatus] Successfully updated status');
        return true;
      }

      debugPrint('⚠️ [updateCallStatus] Failed: ${response['error']}');
      return false;
    } catch (e) {
      debugPrint('❌ [updateCallStatus] Error: $e');
      return false;
    }
  }

  /// 🔹 Send call notification (for missed calls)
  Future<bool> sendCallNotification(String callId, String userId) async {
    try {
      debugPrint('📨 [sendCallNotification] Sending notification for call: $callId');

      final response = await _network.post("/calls/$callId/notify", {
        'userId': userId,
        'type': 'missed_call',
        'timestamp': DateTime.now().toIso8601String(),
      });

      if (response['success'] == true) {
        debugPrint('✅ [sendCallNotification] Notification sent');
        return true;
      }

      debugPrint('⚠️ [sendCallNotification] Failed: ${response['error']}');
      return false;
    } catch (e) {
      debugPrint('❌ [sendCallNotification] Error: $e');
      return false;
    }
  }


  /// 🔹 Track call start
  Future<Map<String, dynamic>> trackCallStart(
      String receiverId, {
        String callType = 'audio',
      }) async {
    return await _callTracking.trackCallInteraction(
      receiverId: receiverId,
      callStatus: 'started',
      callType: callType,
      duration: 0,
    );
  }

  /// 🔹 Track call acceptance
  Future<Map<String, dynamic>> trackCallAccepted(
      String receiverId, {
        String callType = 'audio',
      }) async {
    return await _callTracking.trackCallInteraction(
      receiverId: receiverId,
      callStatus: 'accepted',
      callType: callType,
      duration: 0,
    );
  }

  /// 🔹 Track call decline
  Future<Map<String, dynamic>> trackCallDeclined(
      String receiverId, {
        String callType = 'audio',
      }) async {
    return await _callTracking.trackCallInteraction(
      receiverId: receiverId,
      callStatus: 'declined',
      callType: callType,
      duration: 0,
    );
  }

  /// 🔹 Track call end
  Future<Map<String, dynamic>> trackCallEnd(
      String receiverId, {
        Duration? callDuration,
      }) async {
    return await _callTracking.trackCallEnd(
      receiverId: receiverId,
      callDuration: callDuration?.inSeconds ?? 0,
    );
  }
}