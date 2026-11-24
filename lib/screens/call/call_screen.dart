import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:staffsync/services/auth_service.dart';
import '../../services/call_service.dart';
import '../../utils/notification_handler.dart';
import 'call_socket_service.dart';

// ===================== DESIGN TOKENS (mirrors report style) =====================
class CallDesign {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;

  static const double radiusSm = 10;
  static const double radiusMd = 14;
  static const double radiusLg = 20;

  static const Color primary = Color(0xFF4F46E5);
  static const Color primaryDark = Color(0xFF4338CA);
  static const Color primarySoft = Color(0xFFEEF2FF);
  static const Color primaryLight = Color(0xFFC7D2FE);

  static const Color surface = Colors.white;
  static const Color surfaceMuted = Color(0xFFF8FAFC);
  static const Color bg = Color(0xFFF6F7FB);
  static const Color border = Color(0xFFEAECEF);

  static const Color textPrimary = Color(0xFF1A1D26);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textMuted = Color(0xFF9CA3AF);

  static const Color success = Color(0xFF059669);
  static const Color successSoft = Color(0xFFECFDF5);
  static const Color successBorder = Color(0xFFA7F3D0);

  static const Color danger = Color(0xFFDC2626);
  static const Color dangerSoft = Color(0xFFFEF2F2);
  static const Color dangerBorder = Color(0xFFFECACA);

  static const Color warning = Color(0xFFD97706);
  static const Color warningSoft = Color(0xFFFFFBEB);
  static const Color warningBorder = Color(0xFFFDE68A);

  static const Color neutral = Color(0xFF6B7280);
  static const Color neutralSoft = Color(0xFFF3F4F6);
  static const Color neutralBorder = Color(0xFFE5E7EB);

  static const Color darkSurface = Color(0xFF1E2130);
  static const Color darkBg = Color(0xFF12141C);

  static List<BoxShadow> get softShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.04),
      blurRadius: 14,
      offset: const Offset(0, 4),
      spreadRadius: -2,
    ),
  ];

  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.06),
      blurRadius: 22,
      offset: const Offset(0, 8),
      spreadRadius: -6,
    ),
  ];
}

class SimpleCallScreen extends StatefulWidget {
  final String token;
  final String roomId;
  final String callId;
  final bool isCaller;
  final String callType;
  final String targetUserName;
  final String targetUserId;
  final Function(Duration)? onCallEnd;

  const SimpleCallScreen({
    Key? key,
    required this.token,
    required this.roomId,
    required this.callId,
    required this.isCaller,
    required this.callType,
    required this.targetUserName,
    required this.targetUserId,
    this.onCallEnd,
  }) : super(key: key);

  @override
  _SimpleCallScreenState createState() => _SimpleCallScreenState();
}

class _SimpleCallScreenState extends State<SimpleCallScreen>
    with SingleTickerProviderStateMixin {
  // WebRTC
  final CallService _callService = CallService();
  final NotificationManager _notificationManager = NotificationManager();
  RTCPeerConnection? _peerConnection;
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  final AuthService _authService = AuthService();
  MediaStream? _localStream;
  late CallSocketService _socket;
  MediaStream? _remoteStream;
  final List<RTCIceCandidate> _pendingCandidates = [];
  bool _remoteDescSet = false;
  // State
  bool _isAudioMuted = false;
  bool _isVideoMuted = false;
  bool _isConnected = false;
  bool _isConnecting = true;
  bool _isSocketConnected = false;
  bool _isRoomJoined = false;
  Duration _callDuration = Duration.zero;
  Timer? _timer;
  Timer? _reconnectTimer;
  Timer? _offerResendTimer;
  bool _hasRemoteStream = false;
  String _connectionStatus = 'Initializing...';
  int _reconnectAttempts = 0;
  bool _isDisposed = false;
  bool _hasReceivedOffer = false;
  bool _hasSentOffer = false;
  bool _isWebRTCReady = false;
  RTCSessionDescription? _lastOffer;
  RTCSessionDescription? _lastAnswer;
  bool _showManualRetry = false;
  bool _hasInitialized = false;
  bool _isLocalStreamReady = false;

  // Notification & Call State
  StreamSubscription? _notificationSubscription;
  bool _callEndedByOther = false;
  bool _isEndingCall = false;
  String? _currentUserId;
  bool _showCallEndedScreen = false;
  String _callEndedMessage = 'Call ended';

  // Animation
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    debugPrint(
        '🎬 SimpleCallScreen init: isCaller=${widget.isCaller}, room=${widget.roomId}, callId=${widget.callId}');

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _initializeRenderers();
    _notificationManager.cancelAllNotifications();
    _getCurrentUserId();
    _setupCallCancellationListener();
  }

  Future<void> _getCurrentUserId() async {
    try {
      final user = await _authService.getCurrentUser();
      if (user != null) {
        _currentUserId = user.id.toString();
        debugPrint('👤 Current User ID: $_currentUserId');
      } else {
        _currentUserId = '';
        debugPrint('⚠️ Current user not found');
      }
    } catch (e) {
      debugPrint('❌ Error getting current user ID: $e');
      _currentUserId = '';
    }
  }

  void _setupCallCancellationListener() {
    _notificationSubscription =
        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          _handleCallCancellation(message.data);
        });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleCallCancellation(message.data);
    });
  }

  void _handleCallCancellation(Map<String, dynamic> data) {
    try {
      final type = data['type'];
      final notificationCallId = data['callId'];
      final currentCallId = widget.callId;

      if (notificationCallId != currentCallId) return;

      debugPrint(
          '📢 Received call notification: $type for call: $notificationCallId');

      if (type == 'call_cancelled' ||
          type == 'call_declined' ||
          type == 'call_ended' ||
          type == 'call_missed') {
        if (_isDisposed || _callEndedByOther || _isEndingCall) return;

        _callEndedByOther = true;
        final terminatedBy = data['terminatedBy'] ??
            data['cancelledBy'] ??
            data['endedBy'];
        final currentUserId = _currentUserId;

        if (terminatedBy != currentUserId) {
          debugPrint('📞 Call was terminated by other person: $terminatedBy');
          _cleanupAndExit(false);
        }
      }
    } catch (e) {
      debugPrint('❌ Error handling call cancellation: $e');
    }
  }

  void _cleanupTimers() {
    _timer?.cancel();
    _reconnectTimer?.cancel();
    _offerResendTimer?.cancel();
  }

  Future<void> _initializeRenderers() async {
    try {
      await _localRenderer.initialize();
      await _remoteRenderer.initialize();
      debugPrint('✅ Renderers initialized successfully');
      _initializeCall();
    } catch (e) {
      debugPrint('❌ Renderer initialization error: $e');
      _showErrorAndExit('Failed to initialize video renderers');
    }
  }

  Future<void> _initializeCall() async {
    try {
      if (_hasInitialized) return;
      _hasInitialized = true;

      setState(() => _connectionStatus = 'Requesting permissions...');
      await _requestPermissions();

      setState(() => _connectionStatus = 'Setting up camera and microphone...');
      await _setupWebRTC();

      _isWebRTCReady = true;
      setState(() => _connectionStatus = 'Connecting to server...');
      await _connectToSocketWithRetry();
    } catch (e) {
      debugPrint('❌ Initialize call error: $e');
      _showErrorAndExit('Failed to initialize call: ${e.toString()}');
    }
  }

  Future<void> _connectToSocketWithRetry() async {
    try {
      _socket = CallSocketService();
      _setupSocketListeners();
      await _socket.connect(widget.token);
      await _waitForSocketConnection();
    } catch (e) {
      debugPrint('Socket connection error: $e');
      _reconnectAttempts++;
      if (_reconnectAttempts <= 3 && !_isDisposed) {
        setState(() => _connectionStatus =
        'Reconnecting... (Attempt $_reconnectAttempts/3)');
        await Future.delayed(const Duration(seconds: 2));
        await _connectToSocketWithRetry();
      } else {
        _showErrorAndExit('Failed to connect after $_reconnectAttempts attempts');
      }
    }
  }

  Future<void> _waitForSocketConnection() async {
    Completer<void> completer = Completer();
    int attempts = 0;
    Timer.periodic(const Duration(milliseconds: 100), (timer) {
      attempts++;
      if (_socket.isConnected) {
        timer.cancel();
        completer.complete();
      } else if (attempts >= 50) {
        timer.cancel();
        completer.completeError('Socket connection timeout');
      }
    });
    return completer.future;
  }

  void _setupSocketListeners() {
    bool hasJoinedRoom = false;

    _socket.onConnected = () {
      debugPrint('✅ Socket connected, joining room...');
      _isSocketConnected = true;
      _reconnectAttempts = 0;
      _reconnectTimer?.cancel();
      if (!_isDisposed) {
        setState(() => _connectionStatus = 'Joining room...');
      }
      if (!hasJoinedRoom && !_isDisposed) {
        hasJoinedRoom = true;
        debugPrint(
            '🏠 ${widget.isCaller ? 'Creating' : 'Joining'} room: ${widget.roomId}');
        if (widget.isCaller) {
          _socket.createRoom(widget.roomId, metadata: {
            'callType': widget.callType,
            'callerId': widget.targetUserId,
            'callerName': widget.targetUserName,
            'timestamp': DateTime.now().toIso8601String(),
          });
        } else {
          _socket.joinRoom(widget.roomId);
          _setupOfferListener();
          _setupOfferResendTimer();
        }
      }
    };

    _socket.onDisconnected = () {
      debugPrint('❌ Socket disconnected');
      _isSocketConnected = false;
      if (!_isDisposed && mounted) {
        setState(() => _connectionStatus = 'Reconnecting...');
        _reconnectTimer = Timer(const Duration(seconds: 2), () {
          if (!_isDisposed && mounted && !_isSocketConnected) {
            _socket.connect(widget.token);
          }
        });
      }
    };

    _socket.onRoomCreated = (data) {
      debugPrint('🏠 Room created: $data');
      if (!_isDisposed && mounted) {
        setState(() {
          _isConnecting = false;
          _isRoomJoined = true;
          _connectionStatus = 'Calling ${widget.targetUserName}...';
        });
      }
      if (widget.isCaller && !_hasSentOffer) {
        Future.delayed(const Duration(seconds: 1), () {
          if (!_isDisposed && _isSocketConnected && _isWebRTCReady) {
            _createOffer();
          }
        });
      }
    };

    _socket.onJoinedRoom = (data) {
      debugPrint('🚪 Joined room: $data');
      if (!_isDisposed && mounted) {
        setState(() {
          _isConnecting = false;
          _isRoomJoined = true;
          _connectionStatus =
          widget.isCaller ? 'Waiting for user...' : 'Waiting for call...';
        });
      }
      if (!widget.isCaller) _setupOfferListener();
    };

    _socket.onUserJoined = (data) {
      debugPrint('👤 User joined: $data');
      if (widget.isCaller && !_hasSentOffer && !_isDisposed && _isWebRTCReady) {
        if (mounted) {
          setState(() => _connectionStatus = 'User joined, connecting...');
        }
        Future.delayed(const Duration(milliseconds: 500), _createOffer);
      } else if (widget.isCaller &&
          _hasSentOffer &&
          !_isConnected &&
          !_isDisposed) {
        debugPrint('🔄 User joined but no connection, resending offer...');
        _resendLastOffer();
      }
    };

    _socket.onRoomAnswer = (data) async {
      debugPrint('📡 Received room answer: ${data['roomId']}');
      if (data['roomId'] == widget.roomId && !_isDisposed) {
        if (mounted) {
          setState(() => _connectionStatus = 'Finalizing connection...');
        }
        await _handleAnswer(data);
      }
    };

    _socket.onRoomIceCandidate = (data) async {
      debugPrint('🧊 Received room ICE candidate: ${data['roomId']}');
      if (data['roomId'] == widget.roomId && !_isDisposed) {
        await _handleIceCandidate(data);
      }
    };

    _socket.onUserLeft = (data) {
      debugPrint('User left: $data');
      if (data['roomId'] == widget.roomId && !_isDisposed) {
        _handleOtherUserLeft();
      }
    };

    _socket.onCallEnded = (data) {
      debugPrint('Call ended event: $data');
      if (!_isDisposed) _handleRemoteCallEnd(data);
    };

    _socket.onCallRejected = (data) {
      debugPrint('Call cancelled socket event: $data');
      if (!_isDisposed) {
        _handleCallCancellation({...data, 'type': 'call_cancelled'});
      }
    };

    _socket.onError = (error) {
      debugPrint('Socket error: $error');
      if (!_isDisposed && mounted && _connectionStatus != 'Connected') {
        _showError('Connection error: $error');
      }
    };

    if (widget.isCaller) {
      _socket.onEvent('request-offer', (data) {
        final dataMap = Map<String, dynamic>.from(data);
        if (dataMap['roomId'] == widget.roomId && !_isDisposed) {
          debugPrint('🔔 Callee requested offer resend');
          if (!_hasSentOffer) {
            _createOffer();
          } else {
            debugPrint('🔄 Resending last offer...');
            _resendLastOffer();
          }
        }
      });
    }
  }

  void _handleOtherUserLeft() {
    if (_isDisposed || _callEndedByOther || _isEndingCall) return;
    _callEndedByOther = true;
    debugPrint('📞 Other user left the call, closing immediately');
    _cleanupAndExit(false);
  }

  void _handleRemoteCallEnd(Map<String, dynamic> data) {
    if (_isDisposed || _callEndedByOther || _isEndingCall) return;
    _callEndedByOther = true;
    debugPrint('📞 Call ended by other user, closing immediately');
    _cleanupAndExit(false);
  }

  void _showCallTerminatedFeedback(String message) {
    if (!mounted || _isDisposed) return;
    Navigator.pop(context);
  }

  void _setupOfferListener() {
    debugPrint('🎯 Setting up offer listener for room: ${widget.roomId}');
    _socket.onRoomOffer = (data) async {
      debugPrint('📡 Received room offer: ${data['roomId']}');
      if (data['roomId'] == widget.roomId &&
          !_hasReceivedOffer &&
          !_isDisposed) {
        _hasReceivedOffer = true;
        _offerResendTimer?.cancel();
        _showManualRetry = false;
        if (mounted) setState(() => _connectionStatus = 'Connecting...');
        await _handleOffer(data);
      }
    };
    _socket.flushBufferedEvents('offer');
  }

  void _setupOfferResendTimer() {
    if (widget.isCaller) return;
    _offerResendTimer = Timer(const Duration(seconds: 5), () {
      if (!_hasReceivedOffer &&
          !_isConnected &&
          !_isDisposed &&
          _isSocketConnected) {
        debugPrint('⏰ No offer received after 5 seconds, requesting resend...');
        if (mounted) {
          setState(() {
            _connectionStatus = 'Requesting call...';
            _showManualRetry = true;
          });
        }
        _socket.requestOfferResend(widget.roomId);
      }
    });
  }

  Future<void> _requestOfferResend() async {
    debugPrint('🔔 Manually requesting offer resend...');
    _socket.requestOfferResend(widget.roomId);
    if (mounted) setState(() => _connectionStatus = 'Requesting call...');
  }

  Future<void> _requestPermissions() async {
    try {
      if (widget.callType == 'video') {
        final statuses =
        await [Permission.camera, Permission.microphone].request();
        if (statuses[Permission.camera] != PermissionStatus.granted ||
            statuses[Permission.microphone] != PermissionStatus.granted) {
          throw Exception(
              'Camera and microphone permissions are required for video calls');
        }
        debugPrint('✅ Camera and microphone permissions granted');
      } else {
        final status = await Permission.microphone.request();
        if (status != PermissionStatus.granted) {
          throw Exception(
              'Microphone permission is required for audio calls');
        }
        debugPrint('✅ Microphone permission granted');
      }
    } catch (e) {
      debugPrint('❌ Permission error: $e');
      rethrow;
    }
  }

  Future<void> _setupWebRTC() async {
    try {
      debugPrint('🎥 Setting up WebRTC...');

      final config = {
        'iceServers': [
          {'urls': 'stun:stun.l.google.com:19302'},
          {'urls': 'stun:stun1.l.google.com:19302'},
          {'urls': 'stun:stun2.l.google.com:19302'},
        ],
        'iceTransportPolicy': 'all',
        'bundlePolicy': 'max-bundle',
        'rtcpMuxPolicy': 'require',
        'iceCandidatePoolSize': 10,
      };

      _peerConnection = await createPeerConnection(config);
      debugPrint('✅ Peer connection created');

      final mediaConstraints = {
        'audio': {
          'echoCancellation': true,
          'noiseSuppression': true,
          'autoGainControl': true,
        },
        'video': widget.callType == 'video'
            ? {
          'facingMode': 'user',
          'width': {'ideal': 640},
          'height': {'ideal': 480},
          'frameRate': {'ideal': 24},
        }
            : false,
      };

      debugPrint('🎤 Requesting user media with constraints: $mediaConstraints');
      _localStream = await navigator.mediaDevices.getUserMedia(mediaConstraints);

      if (_localStream == null) {
        throw Exception('Failed to get local media stream');
      }

      debugPrint(
          '✅ Local stream obtained with ${_localStream!.getTracks().length} tracks');

      _localStream!.getTracks().forEach((track) {
        debugPrint(
            '📹 Track: ${track.kind}, enabled: ${track.enabled}, id: ${track.id}');
      });

      _localRenderer.srcObject = _localStream;
      _isLocalStreamReady = true;
      debugPrint('✅ Local stream set to renderer');

      _localStream!.getTracks().forEach((track) {
        _peerConnection!.addTrack(track, _localStream!);
        debugPrint('➕ Added ${track.kind} track to peer connection');
      });

      _peerConnection!.onIceCandidate = (RTCIceCandidate? candidate) {
        if (candidate != null && _isSocketConnected && !_isDisposed) {
          debugPrint('🧊 Sending ICE candidate');
          _socket.sendRoomIceCandidate(widget.roomId, {
            'candidate': candidate.candidate,
            'sdpMid': candidate.sdpMid,
            'sdpMLineIndex': candidate.sdpMLineIndex,
          });
        }
      };

      _peerConnection!.onIceConnectionState =
          (RTCIceConnectionState? state) {
        debugPrint('🔌 ICE connection state: $state');
        if (state != null && !_isDisposed) _updateConnectionState(state);
      };

      _peerConnection!.onConnectionState =
          (RTCPeerConnectionState? state) {
        debugPrint('🔗 Peer connection state: $state');
      };

      _peerConnection!.onTrack = (RTCTrackEvent event) async {
        if (_isDisposed) return;
        debugPrint('📡 onTrack: kind=${event.track.kind}, id=${event.track.id}, streams=${event.streams.length}');

        if (event.streams.isNotEmpty) {
          _remoteStream = event.streams.first;
        } else {
          _remoteStream ??= await createLocalMediaStream('remote');
          _remoteStream!.addTrack(event.track);
        }

        if (widget.callType == 'video') {
          if (event.track.kind == 'video' ||
              (_remoteStream != null && _remoteStream!.getVideoTracks().isNotEmpty)) {
            _remoteRenderer.srcObject = _remoteStream;
          }
        }

        if (!mounted) return;
        setState(() {
          _hasRemoteStream = true;
          _isConnected = true;
          _connectionStatus = 'Connected';
          _showManualRetry = false;
        });
        _startTimer();
      };

      _peerConnection!.onAddStream = (MediaStream stream) {
        if (_isDisposed) return;
        debugPrint('📡 onAddStream: id=${stream.id}, tracks=${stream.getTracks().length}');
        _remoteStream = stream;
        if (widget.callType == 'video' && stream.getVideoTracks().isNotEmpty) {
          _remoteRenderer.srcObject = stream;
        }
        if (!mounted) return;
        setState(() {
          _hasRemoteStream = true;
          _isConnected = true;
          _connectionStatus = 'Connected';
          _showManualRetry = false;
        });
        _startTimer();
      };

      if (mounted) setState(() {});

      debugPrint('✅ WebRTC setup completed successfully');
    } catch (e, stackTrace) {
      debugPrint('❌ WebRTC setup error: $e');
      debugPrint('❌ Stack trace: $stackTrace');
      throw e;
    }
  }

  void _updateConnectionState(RTCIceConnectionState state) {
    if (_isDisposed || !mounted) return;
    switch (state) {
      case RTCIceConnectionState.RTCIceConnectionStateNew:
        setState(() => _connectionStatus = 'Starting connection...');
        break;
      case RTCIceConnectionState.RTCIceConnectionStateChecking:
        setState(() => _connectionStatus = 'Connecting...');
        break;
      case RTCIceConnectionState.RTCIceConnectionStateConnected:
      case RTCIceConnectionState.RTCIceConnectionStateCompleted:
        setState(() {
          _isConnected = true;
          _connectionStatus = 'Connected';
          _showManualRetry = false;
        });
        debugPrint('✅ WebRTC connected!');
        _startTimer();
        break;
      case RTCIceConnectionState.RTCIceConnectionStateFailed:
        setState(() => _connectionStatus = 'Connection failed');
        _showError('Connection failed. Retrying...');
        _retryWebRTCConnection();
        break;
      case RTCIceConnectionState.RTCIceConnectionStateDisconnected:
        setState(() => _connectionStatus = 'Disconnected');
        _showError('Connection lost. Reconnecting...');
        _retryWebRTCConnection();
        break;
      case RTCIceConnectionState.RTCIceConnectionStateClosed:
        setState(() => _connectionStatus = 'Connection closed');
        break;
      case RTCIceConnectionState.RTCIceConnectionStateCount:
        break;
    }
  }

  void _retryWebRTCConnection() {
    if (!_isDisposed && mounted && !_isConnected) {
      Future.delayed(const Duration(seconds: 2), () {
        if (!_isDisposed && mounted && !_isConnected) {
          debugPrint('🔄 Retrying WebRTC connection...');
          _createOfferIfCaller();
        }
      });
    }
  }

  void _createOfferIfCaller() {
    if (widget.isCaller &&
        _isSocketConnected &&
        _isRoomJoined &&
        !_hasSentOffer) {
      if (mounted) setState(() => _connectionStatus = 'Retrying call...');
      _createOffer();
    }
  }

  Future<void> _createOffer() async {
    if (_hasSentOffer || _isDisposed || _peerConnection == null) return;
    try {
      debugPrint('📞 Creating offer...');
      _hasSentOffer = true;
      if (mounted) setState(() => _connectionStatus = 'Creating offer...');

      final offer = await _peerConnection!.createOffer({
        'offerToReceiveAudio': true,
        'offerToReceiveVideo': widget.callType == 'video',
      });

      await _peerConnection!.setLocalDescription(offer);
      _lastOffer = offer;

      debugPrint('📤 Sending offer to room...');
      _socket.sendRoomOffer(widget.roomId, {
        'type': offer.type,
        'sdp': offer.sdp,
      });

      if (mounted && !_isDisposed) {
        setState(() => _connectionStatus = 'Waiting for answer...');
      }
    } catch (e) {
      debugPrint('❌ Create offer error: $e');
      _hasSentOffer = false;
      if (!_isDisposed) _showError('Failed to create offer');
    }
  }

  void _resendLastOffer() {
    if (_lastOffer == null || _isDisposed) return;
    debugPrint('🔄 Resending last offer...');
    _socket.sendRoomOffer(widget.roomId, {
      'type': _lastOffer!.type,
      'sdp': _lastOffer!.sdp,
    });
    if (mounted) setState(() => _connectionStatus = 'Resending call...');
  }

  Future<void> _handleOffer(Map<String, dynamic> data) async {
    if (_peerConnection == null) return;
    try {
      debugPrint('📥 Handling offer...');
      Map<String, dynamic> offerData;
      if (data.containsKey('offer')) {
        offerData = data['offer'];
      } else {
        offerData = data;
      }

      final offer = RTCSessionDescription(offerData['sdp'], offerData['type']);
      await _peerConnection!.setRemoteDescription(offer);
      _remoteDescSet = true;
      for (final c in _pendingCandidates) { await _peerConnection!.addCandidate(c); }
      _pendingCandidates.clear();

      final answer = await _peerConnection!.createAnswer({
        'offerToReceiveAudio': true,
        'offerToReceiveVideo': widget.callType == 'video',
      });
      await _peerConnection!.setLocalDescription(answer);
      _lastAnswer = answer;

      debugPrint('📤 Sending answer...');
      _socket.sendRoomAnswer(widget.roomId, {
        'type': answer.type,
        'sdp': answer.sdp,
      });

      if (mounted && !_isDisposed) {
        setState(() => _connectionStatus = 'Connecting...');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Handle offer error: $e');
      debugPrint('❌ Stack trace: $stackTrace');
      if (!_isDisposed) _showError('Failed to handle offer');
    }
  }

  Future<void> _handleAnswer(Map<String, dynamic> data) async {
    if (_peerConnection == null) return;
    try {
      debugPrint('📥 Handling answer...');
      Map<String, dynamic> answerData;
      if (data.containsKey('answer')) {
        answerData = data['answer'];
      } else {
        answerData = data;
      }

      final answer =
      RTCSessionDescription(answerData['sdp'], answerData['type']);
      await _peerConnection!.setRemoteDescription(answer);
      _remoteDescSet = true;
      for (final c in _pendingCandidates) {
        await _peerConnection!.addCandidate(c);
      }
      _pendingCandidates.clear();

      if (mounted && !_isDisposed) {
        setState(() => _connectionStatus = 'Finalizing...');
      }
    } catch (e) {
      debugPrint('❌ Handle answer error: $e');
      if (!_isDisposed) _showError('Failed to handle answer');
    }
  }

  Future<void> _handleIceCandidate(Map<String, dynamic> data) async {
    if (_peerConnection == null) return;
    try {
      Map<String, dynamic> candidateData;
      if (data.containsKey('candidate')) {
        candidateData = data['candidate'];
      } else {
        candidateData = data;
      }

      final candidate = RTCIceCandidate(
        candidateData['candidate'],
        candidateData['sdpMid'] ?? '',
        candidateData['sdpMLineIndex'] ?? 0,
      );

      if (_remoteDescSet) {
        await _peerConnection!.addCandidate(candidate);
      } else {
        _pendingCandidates.add(candidate);
      }
      debugPrint('✅ Added ICE candidate');
    } catch (e) {
      debugPrint('❌ ICE candidate error: $e');
    }
  }

  void _startTimer() {
    if (_timer?.isActive == true) return;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_isDisposed && mounted) {
        setState(() {
          _callDuration += const Duration(seconds: 1);
        });
      }
    });
  }

  String _formatDuration() {
    final minutes = _callDuration.inMinutes.toString().padLeft(2, '0');
    final seconds = (_callDuration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void _toggleAudio() {
    if (_localStream != null && !_isDisposed && !_callEndedByOther) {
      final tracks = _localStream!.getAudioTracks();
      if (tracks.isNotEmpty) {
        setState(() {
          _isAudioMuted = !_isAudioMuted;
          tracks.first.enabled = !_isAudioMuted;
        });
        _socket.toggleAudio(widget.roomId, _isAudioMuted);
        debugPrint('🎤 Audio ${_isAudioMuted ? 'muted' : 'unmuted'}');
      }
    }
  }

  void _toggleVideo() {
    if (_localStream != null &&
        widget.callType == 'video' &&
        !_isDisposed &&
        !_callEndedByOther) {
      final tracks = _localStream!.getVideoTracks();
      if (tracks.isNotEmpty) {
        setState(() {
          _isVideoMuted = !_isVideoMuted;
          tracks.first.enabled = !_isVideoMuted;
        });
        _socket.toggleVideo(widget.roomId, !_isVideoMuted);
        debugPrint('📹 Video ${_isVideoMuted ? 'disabled' : 'enabled'}');
      }
    }
  }

  Future<void> _endCall({bool byUser = true}) async {
    if (_isDisposed || _isEndingCall) return;
    debugPrint('☎️ Ending call... byUser: $byUser');

    _isEndingCall = true;
    _cleanupTimers();

    try {
      if (widget.callId.isNotEmpty) {
        await _callService.endCall(
          widget.callId,
          reason: byUser ? 'user_ended' : 'remote_ended',
        );
        debugPrint('✅ Server notified about call end');
      }
    } catch (e) {
      debugPrint('⚠️ Error notifying server: $e');
    }

    _cleanupAndExit(byUser);
  }

  void _cleanupAndExit(bool byUser) {
    try {
      _peerConnection?.close();
      if (_localStream != null) {
        _localStream!.getTracks().forEach((track) => track.stop());
        _localStream!.dispose();
      }
    } catch (e) {
      debugPrint('Error during WebRTC cleanup: $e');
    }

    try {
      _socket.leaveRoom(roomId: widget.roomId);
      _socket.disconnect();
    } catch (e) {
      debugPrint('Error during socket cleanup: $e');
    }

    try {
      _localRenderer.dispose();
      _remoteRenderer.dispose();
    } catch (e) {
      debugPrint('Error during renderer disposal: $e');
    }

    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (widget.onCallEnd != null) widget.onCallEnd!(_callDuration);
        if (mounted) Navigator.pop(context);
      });
    }
  }

  void _showError(String message) {
    if (!_isDisposed && mounted && !_callEndedByOther) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: CallDesign.danger,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(CallDesign.radiusMd),
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _showErrorAndExit(String message) {
    if (!_isDisposed) {
      _showError(message);
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted && !_isDisposed) Navigator.pop(context);
      });
    }
  }

  // ===================== BUILD =====================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CallDesign.darkBg,
      body: Stack(
        children: [
          // Remote video / waiting view
          if (widget.callType == 'video' &&
              _hasRemoteStream &&
              _remoteRenderer.srcObject != null &&
              _remoteStream != null &&
              _remoteStream!.getVideoTracks().isNotEmpty &&
              _isConnected)
            Positioned.fill(
              child: Container(
                color: Colors.black,
                child: RTCVideoView(
                  _remoteRenderer,
                  key: ValueKey('${_remoteStream?.id}-${_remoteStream?.getVideoTracks().length}'),
                  objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                ),
              ),
            )
          else
            _buildModernWaitingView(),

          // Local PiP
          if (widget.callType == 'video' &&
              _isLocalStreamReady &&
              _localRenderer.srcObject != null)
            Positioned(
              top: MediaQuery.of(context).padding.top + 100,
              right: 16,
              child: _buildLocalVideoPreview(),
            ),

          _buildTopBar(),

          if (!_callEndedByOther)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildModernControls(),
            ),

          if (!_isSocketConnected && _connectionStatus.contains('Reconnecting'))
            _buildReconnectingOverlay(),
        ],
      ),
    );
  }

  // ===================== CALL ENDED SCREEN =====================
  Widget _buildCallEndedScreen() {
    return Scaffold(
      backgroundColor: CallDesign.bg,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(CallDesign.lg),
            child: Container(
              padding: const EdgeInsets.all(CallDesign.xl),
              decoration: BoxDecoration(
                color: CallDesign.surface,
                borderRadius: BorderRadius.circular(CallDesign.radiusLg),
                border: Border.all(color: CallDesign.border, width: 1),
                boxShadow: CallDesign.cardShadow,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      color: CallDesign.neutralSoft,
                      shape: BoxShape.circle,
                      border: Border.all(color: CallDesign.border, width: 1),
                    ),
                    child: const Icon(
                      Icons.call_end_rounded,
                      size: 38,
                      color: CallDesign.textMuted,
                    ),
                  ),
                  const SizedBox(height: CallDesign.lg),
                  Text(
                    _callEndedMessage,
                    style: const TextStyle(
                      color: CallDesign.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: CallDesign.sm),
                  Text(
                    'with ${widget.targetUserName}',
                    style: const TextStyle(
                      color: CallDesign.textMuted,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (_callDuration.inSeconds > 0) ...[
                    const SizedBox(height: CallDesign.md),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: CallDesign.md,
                        vertical: CallDesign.sm,
                      ),
                      decoration: BoxDecoration(
                        color: CallDesign.primarySoft,
                        borderRadius:
                        BorderRadius.circular(CallDesign.radiusSm),
                        border: Border.all(color: CallDesign.primaryLight),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.timer_outlined,
                            size: 14,
                            color: CallDesign.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Duration ${_formatDuration()}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: CallDesign.primary,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: CallDesign.xl),
                  SizedBox(
                    width: double.infinity,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          if (mounted) Navigator.pop(context);
                        },
                        borderRadius:
                        BorderRadius.circular(CallDesign.radiusMd),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: CallDesign.primary,
                            borderRadius:
                            BorderRadius.circular(CallDesign.radiusMd),
                            boxShadow: [
                              BoxShadow(
                                color:
                                CallDesign.primary.withOpacity(0.25),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: const Text(
                            'Close',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ===================== TOP BAR =====================
  Widget _buildTopBar() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 16,
          left: 16,
          right: 16,
          bottom: 16,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withOpacity(0.65),
              Colors.black.withOpacity(0.0),
            ],
          ),
        ),
        child: Container(
          padding: const EdgeInsets.all(CallDesign.md),
          decoration: BoxDecoration(
            color: CallDesign.darkSurface.withOpacity(0.85),
            borderRadius: BorderRadius.circular(CallDesign.radiusLg),
            border: Border.all(color: Colors.white.withOpacity(0.08), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: CallDesign.primarySoft,
                  borderRadius: BorderRadius.circular(CallDesign.radiusSm),
                  border: Border.all(color: CallDesign.primaryLight, width: 1),
                ),
                child: const Icon(Icons.person_rounded,
                    color: CallDesign.primary, size: 20),
              ),
              const SizedBox(width: CallDesign.sm + 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.targetUserName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (_isConnected) ...[
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: CallDesign.success,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: CallDesign.success.withOpacity(0.6),
                                  blurRadius: 6,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                        Text(
                          _isConnected
                              ? (_callDuration.inSeconds > 0
                              ? _formatDuration()
                              : 'Connected')
                              : _connectionStatus,
                          style: TextStyle(
                            color: _isConnected
                                ? Colors.white
                                : Colors.white.withOpacity(0.7),
                            fontSize: 12,
                            fontWeight: _isConnected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: CallDesign.sm, vertical: 4),
                decoration: BoxDecoration(
                  color: (_isConnected ? CallDesign.success : CallDesign.warning)
                      .withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: (_isConnected
                        ? CallDesign.successBorder
                        : CallDesign.warningBorder)
                        .withOpacity(0.6),
                    width: 1,
                  ),
                ),
                child: Text(
                  _isConnected ? 'LIVE' : 'WAIT',
                  style: TextStyle(
                    color:
                    _isConnected ? CallDesign.success : CallDesign.warning,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _switchCamera() async {
    if (_localStream != null && widget.callType == 'video' && !_isDisposed) {
      final videoTracks = _localStream!.getVideoTracks();
      if (videoTracks.isNotEmpty) {
        try {
          await Helper.switchCamera(videoTracks.first);
          if (mounted) setState(() {});
        } catch (e) {
          debugPrint('Error switching camera: $e');
        }
      }
    }
  }

  // ===================== LOCAL VIDEO PREVIEW =====================
  Widget _buildLocalVideoPreview() {
    return GestureDetector(
      onTap: _switchCamera,
      child: Container(
        width: 110,
        height: 150,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(CallDesign.radiusLg),
          border: Border.all(color: Colors.white.withOpacity(0.15), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 22,
              offset: const Offset(0, 8),
              spreadRadius: -4,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(CallDesign.radiusLg - 1),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Container(
                color: Colors.black,
                child: RTCVideoView(
                  _localRenderer,
                  mirror: true,
                  objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                ),
              ),
              if (_isVideoMuted)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.75),
                    borderRadius: BorderRadius.circular(CallDesign.radiusLg - 1),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.videocam_off_rounded,
                            color: Colors.white70, size: 30),
                        const SizedBox(height: 6),
                        const Text(
                          'Camera Off',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.cameraswitch_rounded,
                    color: Colors.white,
                    size: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===================== WAITING VIEW =====================
  Widget _buildModernWaitingView() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1A1D26),
            Color(0xFF12141C),
            Color(0xFF0E1015),
          ],
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: CallDesign.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ScaleTransition(
                scale: _pulseAnimation,
                child: Container(
                  width: 132,
                  height: 132,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: CallDesign.primarySoft,
                    border: Border.all(color: CallDesign.primaryLight, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: CallDesign.primary.withOpacity(0.25),
                        blurRadius: 40,
                        spreadRadius: 8,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.person_rounded,
                      size: 64, color: CallDesign.primary),
                ),
              ),
              const SizedBox(height: CallDesign.xl),
              Text(
                widget.targetUserName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: CallDesign.sm),
              // Status pill
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: CallDesign.md, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(CallDesign.radiusSm),
                  border: Border.all(
                      color: Colors.white.withOpacity(0.1), width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: CallDesign.warning,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: CallDesign.warning.withOpacity(0.5),
                            blurRadius: 6,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _connectionStatus,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
              if (_showManualRetry && !_isConnected && !widget.isCaller) ...[
                const SizedBox(height: CallDesign.lg),
                _buildRetryButton(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRetryButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _requestOfferResend,
        borderRadius: BorderRadius.circular(CallDesign.radiusMd),
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: CallDesign.lg, vertical: 14),
          decoration: BoxDecoration(
            color: CallDesign.primary,
            borderRadius: BorderRadius.circular(CallDesign.radiusMd),
            boxShadow: [
              BoxShadow(
                color: CallDesign.primary.withOpacity(0.3),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.refresh_rounded, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text(
                'Retry Connection',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===================== BOTTOM CONTROLS =====================
  Widget _buildModernControls() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Colors.black.withOpacity(0.9),
            Colors.black.withOpacity(0.6),
            Colors.transparent,
          ],
        ),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).padding.bottom + 24,
        top: 40,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: CallDesign.lg, vertical: CallDesign.md + 2),
        decoration: BoxDecoration(
          color: CallDesign.darkSurface.withOpacity(0.9),
          borderRadius: BorderRadius.circular(CallDesign.radiusLg + 4),
          border: Border.all(color: Colors.white.withOpacity(0.08), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.35),
              blurRadius: 24,
              offset: const Offset(0, 10),
              spreadRadius: -6,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildControlButton(
              icon: _isAudioMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
              label: _isAudioMuted ? 'Unmute' : 'Mute',
              isActive: !_isAudioMuted,
              onTap: _toggleAudio,
            ),
            _buildEndCallButton(),
            if (widget.callType == 'video')
              _buildControlButton(
                icon: _isVideoMuted
                    ? Icons.videocam_off_rounded
                    : Icons.videocam_rounded,
                label: _isVideoMuted ? 'Turn On' : 'Turn Off',
                isActive: !_isVideoMuted,
                onTap: _toggleVideo,
              )
            else
              _buildControlButton(
                icon: Icons.volume_up_rounded,
                label: 'Speaker',
                isActive: true,
                onTap: () {},
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(30),
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: isActive
                    ? CallDesign.primarySoft
                    : CallDesign.dangerSoft,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isActive
                      ? CallDesign.primaryLight
                      : CallDesign.dangerBorder,
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (isActive ? CallDesign.primary : CallDesign.danger)
                        .withOpacity(0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                    spreadRadius: -2,
                  ),
                ],
              ),
              child: Icon(
                icon,
                color: isActive ? CallDesign.primary : CallDesign.danger,
                size: 24,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }

  Widget _buildEndCallButton() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _endCall(byUser: true),
            borderRadius: BorderRadius.circular(34),
            child: Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [CallDesign.danger, Color(0xFFB91C1C)],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: CallDesign.danger.withOpacity(0.45),
                    blurRadius: 22,
                    offset: const Offset(0, 8),
                    spreadRadius: -2,
                  ),
                ],
              ),
              child: const Icon(Icons.call_end_rounded,
                  color: Colors.white, size: 30),
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'End Call',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }

  // ===================== RECONNECTING OVERLAY =====================
  Widget _buildReconnectingOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.85),
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(CallDesign.xl),
            margin: const EdgeInsets.symmetric(horizontal: CallDesign.lg),
            decoration: BoxDecoration(
              color: CallDesign.darkSurface,
              borderRadius: BorderRadius.circular(CallDesign.radiusLg),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 30,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: CallDesign.warningSoft,
                    shape: BoxShape.circle,
                    border: Border.all(color: CallDesign.warningBorder),
                  ),
                  child: const Icon(
                    Icons.wifi_off_rounded,
                    size: 32,
                    color: CallDesign.warning,
                  ),
                ),
                const SizedBox(height: CallDesign.lg),
                const Text(
                  'Reconnecting...',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: CallDesign.sm),
                const Text(
                  'Please wait while we restore your connection',
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 12.5,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    debugPrint('🧹 SimpleCallScreen disposing...');
    _isDisposed = true;

    _cleanupTimers();
    _notificationSubscription?.cancel();
    _pulseController.dispose();

    if (!_callEndedByOther && !_isEndingCall) {
      _endCall(byUser: false);
    }

    super.dispose();
  }
}