import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:staffsync/app/constants.dart';

class CallSocketService {
  static final CallSocketService _instance = CallSocketService._internal();
  factory CallSocketService() => _instance;
  CallSocketService._internal();

  late io.Socket _callSocket;
  bool _isConnected = false;
  String? _currentRoomId;
  String? _currentCallId;
  final Map<String, List<dynamic>> _rawEventBuffer = {};
  // Callbacks
  Function(Map<String, dynamic>)? onCallSocketConnected;
  Function(Map<String, dynamic>)? onCallIncoming;
  Function(Map<String, dynamic>)? onCallAccepted;
  Function(Map<String, dynamic>)? onCallRejected;
  Function(Map<String, dynamic>)? onCallEnded;
  Function(Map<String, dynamic>)? onCallMissed;
  Function(Map<String, dynamic>)? onCallCreated;
  Function(Map<String, dynamic>)? onCallStarted;
  Function(Map<String, dynamic>)? onWebRTCOffer;
  Function(Map<String, dynamic>)? onWebRTCAnswer;
  Function(Map<String, dynamic>)? onIceCandidate;
  Function(Map<String, dynamic>)? onUserAudioChanged;
  Function(Map<String, dynamic>)? onUserVideoChanged;
  Function(String)? onError;

  // Room callbacks
  Function(Map<String, dynamic>)? onRoomCreated;
  Function(Map<String, dynamic>)? onJoinedRoom;
  Function(Map<String, dynamic>)? onUserJoined;
  Function(Map<String, dynamic>)? onUserLeft;
  Function(Map<String, dynamic>)? onRoomLockChanged;
  Function(Map<String, dynamic>)? onRoomInfo;
  Function(Map<String, dynamic>)? onRoomParticipants;
  Function(Map<String, dynamic>)? onActiveRoomsList;
  Function(Map<String, dynamic>)? onRoomError;
  Function(Map<String, dynamic>)? onLeftRoom;

  // WebRTC signaling callbacks
  Function(Map<String, dynamic>)? _onRoomOffer;
  Function(Map<String, dynamic>)? _onRoomAnswer;
  Function(Map<String, dynamic>)? _onRoomIceCandidate;

  // Public setters with buffered event flushing
  set onRoomOffer(Function(Map<String, dynamic>)? handler) {
    _onRoomOffer = handler;
    if (handler != null) {
      _flushBufferedEvents('offer', handler);
    }
  }

  set onRoomAnswer(Function(Map<String, dynamic>)? handler) {
    _onRoomAnswer = handler;
    if (handler != null) {
      _flushBufferedEvents('answer', handler);
    }
  }

  set onRoomIceCandidate(Function(Map<String, dynamic>)? handler) {
    _onRoomIceCandidate = handler;
    if (handler != null) {
      _flushBufferedEvents('ice-candidate', handler);
    }
  }

  // Additional callbacks
  Function(Map<String, dynamic>)? onParticipantLeft;
  Function(Map<String, dynamic>)? onCallMessage;
  Function(Map<String, dynamic>)? onUserAvailability;
  Function(Map<String, dynamic>)? onActiveCallsList;
  Function(Map<String, dynamic>)? onCallStats;

  // Connection callbacks
  Function()? onConnected;
  Function()? onDisconnected;

  // Flush buffered events when handler is set
  void _flushBufferedEvents(String eventName, Function(Map<String, dynamic>) handler) {
    if (_rawEventBuffer.containsKey(eventName)) {
      final events = _rawEventBuffer[eventName]!;
      print('🔄 [CallSocketService] Flushing ${events.length} buffered $eventName events');

      for (var event in events) {
        try {
          final data = Map<String, dynamic>.from(event);
          handler(data);
        } catch (e) {
          print('❌ Error flushing buffered event: $e');
        }
      }

      _rawEventBuffer.remove(eventName);
    }
  }

  Future<void> connect(String token) async {
    try {
      print('🔌 [CallSocketService] Connecting to socket...');

      _callSocket = io.io(
        '${AppConstants.socketBaseUrl}/call',
        io.OptionBuilder()
            .setTransports(['websocket', 'polling'])
            .enableForceNew()
            .setAuth({'token': token})
            .setQuery({'token': token})
            .enableAutoConnect()
            .setExtraHeaders({
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        })
            .setReconnectionDelay(1000)
            .setReconnectionDelayMax(5000)
            .setReconnectionAttempts(5)
            .setTimeout(30000)
            .build(),
      );

      // ==================== CONNECTION EVENTS ====================
      _callSocket.onConnect((_) {
        print('✅ [CallSocketService] Connected to socket');
        _isConnected = true;
        onConnected?.call();
      });

      _callSocket.onDisconnect((_) {
        print('❌ [CallSocketService] Disconnected');
        _isConnected = false;
        _currentRoomId = null;
        _currentCallId = null;
        _rawEventBuffer.clear();
        onDisconnected?.call();
      });

      _callSocket.onConnectError((data) {
        print('💥 [CallSocketService] Connection error: $data');
        onError?.call('Connection failed: $data');
      });

      _callSocket.onError((data) {
        print('💥 [CallSocketService] Socket error: $data');
        onError?.call('Socket error: $data');
      });

      // ==================== ROOM EVENTS ====================
      _callSocket.on('room-created', (data) {
        print('🏠 [CallSocketService] Room created: $data');
        onRoomCreated?.call(Map<String, dynamic>.from(data));
      });

      _callSocket.on('joined-room', (data) {
        print('🚪 [CallSocketService] Joined room: $data');
        onJoinedRoom?.call(Map<String, dynamic>.from(data));
      });

      _callSocket.on('user-joined', (data) {
        print('👤 [CallSocketService] User joined: $data');
        onUserJoined?.call(Map<String, dynamic>.from(data));
      });

      _callSocket.on('user-left', (data) {
        print('👤 [CallSocketService] User left: $data');
        onUserLeft?.call(Map<String, dynamic>.from(data));
      });

      // ✅ CRITICAL FIX: Buffer events if handler not set, or call handler if set
      _callSocket.on('offer', (data) {
        print('📡 [CallSocketService] Received offer event');

        if (_onRoomOffer != null) {
          print('📡 Calling offer handler immediately');
          _onRoomOffer!(Map<String, dynamic>.from(data));
        } else {
          print('📡 Buffering offer (handler not set yet)');
          if (!_rawEventBuffer.containsKey('offer')) {
            _rawEventBuffer['offer'] = [];
          }
          _rawEventBuffer['offer']!.add(data);
        }
      });

      _callSocket.on('answer', (data) {
        print('📡 [CallSocketService] Received answer event');

        if (_onRoomAnswer != null) {
          print('📡 Calling answer handler immediately');
          _onRoomAnswer!(Map<String, dynamic>.from(data));
        } else {
          print('📡 Buffering answer (handler not set yet)');
          if (!_rawEventBuffer.containsKey('answer')) {
            _rawEventBuffer['answer'] = [];
          }
          _rawEventBuffer['answer']!.add(data);
        }
      });

      _callSocket.on('ice-candidate', (data) {
        print('🧊 [CallSocketService] Received ice-candidate event');

        if (_onRoomIceCandidate != null) {
          _onRoomIceCandidate!(Map<String, dynamic>.from(data));
        } else {
          if (!_rawEventBuffer.containsKey('ice-candidate')) {
            _rawEventBuffer['ice-candidate'] = [];
          }
          _rawEventBuffer['ice-candidate']!.add(data);
        }
      });

      _callSocket.on('room-error', (data) {
        final errorData = Map<String, dynamic>.from(data);
        print('💥 [CallSocketService] Room error: ${errorData['message']}');
        onError?.call(errorData['message'] ?? 'Room error');
      });

      // ==================== CALL EVENTS ====================
      _callSocket.on('call-socket-connected', (data) {
        print('✅ [CallSocketService] Socket fully connected: $data');
        onCallSocketConnected?.call(Map<String, dynamic>.from(data));
      });

      _callSocket.on('call-incoming', (data) {
        print('📞 [CallSocketService] Incoming call: $data');
        onCallIncoming?.call(Map<String, dynamic>.from(data));
      });

      _callSocket.on('call-accepted', (data) {
        print('✅ [CallSocketService] Call accepted: $data');
        onCallAccepted?.call(Map<String, dynamic>.from(data));
      });

      _callSocket.on('call-rejected', (data) {
        print('❌ [CallSocketService] Call rejected: $data');
        onCallRejected?.call(Map<String, dynamic>.from(data));
      });

      _callSocket.on('call-ended', (data) {
        print('📞 [CallSocketService] Call ended: $data');
        onCallEnded?.call(Map<String, dynamic>.from(data));
      });

      _callSocket.on('call-missed', (data) {
        print('📞 [CallSocketService] Call missed: $data');
        onCallMissed?.call(Map<String, dynamic>.from(data));
      });

      _callSocket.on('call-created', (data) {
        print('📞 [CallSocketService] Call created: $data');
        onCallCreated?.call(Map<String, dynamic>.from(data));
      });

      _callSocket.on('call-started', (data) {
        print('📞 [CallSocketService] Call started: $data');
        onCallStarted?.call(Map<String, dynamic>.from(data));
      });

      _callSocket.on('call-error', (data) {
        final errorData = Map<String, dynamic>.from(data);
        print('💥 [CallSocketService] Call error: ${errorData['message']}');
        onError?.call(errorData['message'] ?? 'Call error');
      });

      // Direct WebRTC signaling
      _callSocket.on('webrtc-offer', (data) {
        print('📡 [CallSocketService] Received direct WebRTC offer');
        onWebRTCOffer?.call(Map<String, dynamic>.from(data));
      });

      _callSocket.on('webrtc-answer', (data) {
        print('📡 [CallSocketService] Received direct WebRTC answer');
        onWebRTCAnswer?.call(Map<String, dynamic>.from(data));
      });

      _callSocket.on('webrtc-ice-candidate', (data) {
        print('🧊 [CallSocketService] Received direct ICE candidate');
        onIceCandidate?.call(Map<String, dynamic>.from(data));
      });

      // Additional events
      _callSocket.on('user-audio-changed', (data) {
        onUserAudioChanged?.call(Map<String, dynamic>.from(data));
      });

      _callSocket.on('user-video-changed', (data) {
        onUserVideoChanged?.call(Map<String, dynamic>.from(data));
      });

      _callSocket.on('participant-left', (data) {
        onParticipantLeft?.call(Map<String, dynamic>.from(data));
      });

      _callSocket.on('call-message', (data) {
        onCallMessage?.call(Map<String, dynamic>.from(data));
      });

      _callSocket.on('user-availability', (data) {
        onUserAvailability?.call(Map<String, dynamic>.from(data));
      });

      _callSocket.on('active-calls-list', (data) {
        onActiveCallsList?.call(Map<String, dynamic>.from(data));
      });

      _callSocket.on('call-stats', (data) {
        onCallStats?.call(Map<String, dynamic>.from(data));
      });

      // Connect
      _callSocket.connect();

    } catch (e) {
      print('💥 [CallSocketService] Failed to connect: $e');
      rethrow;
    }
  }

  // No longer needed - handled automatically
  void flushBufferedEvents(String eventName) {
    print('⚠️ flushBufferedEvents() is deprecated - events flush automatically when handler is set');
  }

  // ==================== ROOM MANAGEMENT ====================

  void createRoom(String roomId, {Map<String, dynamic>? metadata}) {
    if (!_isConnected) {
      onError?.call('Not connected to call server');
      return;
    }

    print('🏠 [CallSocketService] Creating room: $roomId');
    _callSocket.emit('create-room', {
      'roomId': roomId,
      'metadata': metadata ?? {
        'platform': 'flutter',
        'timestamp': DateTime.now().toIso8601String(),
        'isCaller': true,
      }
    });
  }

  void joinRoom(String roomId) {
    if (!_isConnected) {
      onError?.call('Not connected to call server');
      return;
    }

    print('🚪 [CallSocketService] Joining room: $roomId');
    _callSocket.emit('join-room', {
      'roomId': roomId,
      'metadata': {
        'platform': 'flutter',
        'timestamp': DateTime.now().toIso8601String(),
        'isCaller': false,
      }
    });
  }

  void leaveRoom({String? roomId, String reason = 'User left'}) {
    if (!_isConnected) {
      onError?.call('Not connected to call server');
      return;
    }

    final targetRoomId = roomId ?? _currentRoomId;
    if (targetRoomId == null) {
      onError?.call('Not currently in any room');
      return;
    }

    print('🚶 [CallSocketService] Leaving room: $targetRoomId');
    _callSocket.emit('leave-room', {
      'roomId': targetRoomId,
      'reason': reason,
    });
  }

  void onEvent(String eventName, Function(dynamic) handler) {
    _callSocket.on(eventName, handler);
  }

  void emitEvent(String eventName, Map<String, dynamic> data) {
    if (!_isConnected) {
      onError?.call('Not connected to call server');
      return;
    }

    print('📤 [CallSocketService] Emitting event: $eventName');
    _callSocket.emit(eventName, data);
  }

  // ==================== ROOM WEBRTC SIGNALING ====================

  void sendRoomOffer(String roomId, Map<String, dynamic> offer) {
    if (!_isConnected) {
      onError?.call('Not connected to call server');
      return;
    }

    print('📡 [CallSocketService] Sending room offer to: $roomId');
    _callSocket.emit('offer', {
      'roomId': roomId,
      'offer': offer,
    });
  }

  void sendRoomAnswer(String roomId, Map<String, dynamic> answer) {
    if (!_isConnected) {
      onError?.call('Not connected to call server');
      return;
    }

    print('📡 [CallSocketService] Sending room answer to: $roomId');
    _callSocket.emit('answer', {
      'roomId': roomId,
      'answer': answer,
    });
  }

  void sendRoomIceCandidate(String roomId, Map<String, dynamic> candidate) {
    if (!_isConnected) {
      onError?.call('Not connected to call server');
      return;
    }

    _callSocket.emit('ice-candidate', {
      'roomId': roomId,
      'candidate': candidate,
    });
  }

  // ==================== DIRECT CALL FUNCTIONS ====================

  void createCall(String targetUserId, {String callType = 'video', Map<String, dynamic>? metadata}) {
    if (!_isConnected) {
      onError?.call('Not connected to call server');
      return;
    }

    print('📞 [CallSocketService] Creating call to: $targetUserId');
    _callSocket.emit('create-call', {
      'targetUserId': targetUserId,
      'callType': callType,
      'metadata': metadata,
    });
  }

  void acceptCall(String callId) {
    if (!_isConnected) {
      onError?.call('Not connected to call server');
      return;
    }

    print('✅ [CallSocketService] Accepting call: $callId');
    _callSocket.emit('accept-call', {
      'callId': callId,
    });
    _currentCallId = callId;
  }

  void rejectCall(String callId, {String reason = 'Call rejected'}) {
    if (!_isConnected) {
      onError?.call('Not connected to call server');
      return;
    }

    print('❌ [CallSocketService] Rejecting call: $callId');
    _callSocket.emit('reject-call', {
      'callId': callId,
      'reason': reason,
    });
    _currentCallId = null;
  }

  void endCall(String callId, {String reason = 'Call ended'}) {
    if (!_isConnected) {
      onError?.call('Not connected to call server');
      return;
    }

    print('📞 [CallSocketService] Ending call: $callId');
    _callSocket.emit('end-call', {
      'callId': callId,
      'reason': reason,
    });
    _currentCallId = null;
  }

  void toggleAudio(String callId, bool isMuted) {
    if (!_isConnected) {
      onError?.call('Not connected to call server');
      return;
    }

    print('🎤 [CallSocketService] Toggling audio for call: $callId');
    _callSocket.emit('toggle-audio', {
      'callId': callId,
      'isMuted': isMuted,
    });
  }

  void toggleVideo(String callId, bool isVideoOn) {
    if (!_isConnected) {
      onError?.call('Not connected to call server');
      return;
    }

    print('📹 [CallSocketService] Toggling video for call: $callId');
    _callSocket.emit('toggle-video', {
      'callId': callId,
      'isVideoOn': isVideoOn,
    });
  }

  void requestOfferResend(String roomId) {
    if (!_isConnected) {
      onError?.call('Not connected to call server');
      return;
    }

    print('🔔 [CallSocketService] Requesting offer resend for room: $roomId');
    _callSocket.emit('request-offer', {
      'roomId': roomId,
    });
  }

  // ==================== UTILITY FUNCTIONS ====================

  void disconnect() {
    if (_isConnected) {
      print('🔌 [CallSocketService] Disconnecting...');

      if (_currentRoomId != null) {
        leaveRoom();
      }

      if (_currentCallId != null) {
        endCall(_currentCallId!);
      }

      _callSocket.disconnect();
      _isConnected = false;
      _currentRoomId = null;
      _currentCallId = null;
      _rawEventBuffer.clear();
    }
  }

  // ==================== GETTERS ====================

  bool get isConnected => _isConnected;
  String get socketId => _callSocket.id ?? 'not-connected';
  String? get currentRoomId => _currentRoomId;
  String? get currentCallId => _currentCallId;
  io.Socket get callSocket => _callSocket;
}