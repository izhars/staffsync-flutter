import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import '../../services/call_service.dart';
import '../../services/auth_service.dart';
import '../../utils/notification_handler.dart';
import '../../services/notification_service.dart';
import 'call_screen.dart';

// ===================== DESIGN TOKENS (mirrors report style) =====================
class IncomingCallDesign {
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

class IncomingCallScreen extends StatefulWidget {
  final Map<String, dynamic>? callData;
  final String? userToken;
  final String? currentUserId;

  const IncomingCallScreen({
    Key? key,
    this.callData,
    this.userToken,
    this.currentUserId,
  }) : super(key: key);

  static Route route(Map<String, dynamic> arguments) {
    return MaterialPageRoute(
      builder: (_) => IncomingCallScreen(
        callData: arguments['callData'],
        userToken: arguments['userToken'],
        currentUserId: arguments['currentUserId'],
      ),
    );
  }

  @override
  _IncomingCallScreenState createState() => _IncomingCallScreenState();
}

class _IncomingCallScreenState extends State<IncomingCallScreen> {
  final CallService _callService = CallService();
  final NotificationManager _notificationManager = NotificationManager();
  final NotificationService _notificationService = NotificationService();

  Timer? _timeoutTimer;
  Timer? _ringTimer;
  int _ringDuration = 0;
  bool _isAccepting = false;
  bool _isDeclining = false;
  bool _isDisposed = false;
  StreamSubscription? _notificationSubscription;
  StreamSubscription<Map<String, dynamic>>? _callTerminationSubscription;

  bool _callEndedByOther = false;
  bool _hasTrackedMissedCall = false;
  String? _actualCurrentUserId;
  bool _showCallEndedOverlay = false;
  String _callEndedMessage = 'Call ended';
  String? _cancelledByUserId;

  String get _callType {
    final type = widget.callData?['callType'] ?? widget.callData?['type'];
    if (type == 'video' || type == 'audio') return type!;
    return 'video';
  }

  @override
  void initState() {
    super.initState();

    debugPrint('📱 IncomingCallScreen initialized');
    debugPrint('📝 Call Data: ${widget.callData}');
    debugPrint('📝 Caller ID: ${widget.callData?['callerId']}');
    debugPrint('📝 Call ID: ${widget.callData?['callId']}');

    _getCurrentUserId();
    _startRinging();
    _startTimeout();
    _setupCallTerminationListener();
    _trackMissedCallStart();
  }

  Future<void> _getCurrentUserId() async {
    try {
      final authService = AuthService();
      _actualCurrentUserId =
          await authService.getUserId() ?? widget.currentUserId;
      debugPrint('👤 Current User ID: $_actualCurrentUserId');
    } catch (e) {
      debugPrint('❌ Error getting current user ID: $e');
      _actualCurrentUserId = widget.currentUserId;
    }
  }

  void _setupCallTerminationListener() {
    _callTerminationSubscription =
        _notificationService.notificationStream.listen((data) {
          _handleCallTerminationNotification(data);
        });

    _notificationSubscription =
        FirebaseMessaging.onMessage.listen((message) {
          if (_isDisposed) return;
          _handleCallTerminationNotification(message.data);
        });

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      if (_isDisposed) return;
      _handleCallTerminationNotification(message.data);
    });

    _checkInitialNotification();
  }

  Future<void> _checkInitialNotification() async {
    try {
      final initialData =
      await _notificationService.getInitialNotificationData();
      if (initialData != null) {
        _handleCallTerminationNotification(initialData);
      }
    } catch (e) {
      debugPrint('❌ Error checking initial notification: $e');
    }
  }

  void _handleCallTerminationNotification(Map<String, dynamic> data) {
    try {
      final type = data['type'];
      final callId = data['callId'];
      final currentCallId = widget.callData?['callId'];

      if (callId != currentCallId) return;

      final notificationType = NotificationType.fromString(type);

      if (notificationType == NotificationType.callDeclined ||
          notificationType == NotificationType.callMissed ||
          notificationType == NotificationType.callEnded ||
          type == 'call_cancelled') {
        final terminatedBy =
            data['terminatedBy'] ?? data['cancelledBy'] ?? data['endedBy'];
        final currentUserId = _actualCurrentUserId;
        final reason = data['reason'] ?? 'call ended';

        if (terminatedBy != currentUserId) {
          _handleCallTerminationByOther(data, notificationType, reason);
        }
      }
    } catch (e) {
      debugPrint('❌ Error handling termination notification: $e');
    }
  }

  void _handleCallTerminationByOther(
      Map<String, dynamic> data,
      NotificationType? type,
      String reason,
      ) {
    if (_isDisposed || _callEndedByOther) return;

    debugPrint('📞 Call was cancelled by other person');

    _callEndedByOther = true;
    _cancelledByUserId = data['cancelledBy'] ?? data['terminatedBy'];

    if (type == NotificationType.callDeclined) {
      _callEndedMessage = 'Call declined';
    } else if (type == NotificationType.callMissed) {
      _callEndedMessage = 'Missed call';
    } else if (reason == 'timeout') {
      _callEndedMessage = 'Call timed out';
    } else {
      _callEndedMessage = 'Call cancelled';
    }

    _timeoutTimer?.cancel();
    _ringTimer?.cancel();

    final callId = widget.callData?['callId'];
    if (callId != null) {
      _notificationManager.cancelCallNotification(callId);
    }

    if (!_hasTrackedMissedCall) {
      _trackCallDeclined(isAutoTimeout: reason == 'timeout');
    }

    _cleanupAndExit('call_terminated_by_other');
  }

  Future<void> _showIncomingCallNotification() async {
    try {
      await _notificationManager.showIncomingCallNotification(
        callId: widget.callData?['callId'] ?? '',
        callerName: widget.callData?['callerName'] ?? 'Unknown',
        roomId: widget.callData?['roomId'] ?? '',
        callerId: widget.callData?['callerId'] ?? '',
        callType: _callType,
      );
    } catch (e) {
      debugPrint('❌ Error showing incoming call notification: $e');
    }
  }

  void _startRinging() {
    _ringTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isDisposed && mounted) {
        setState(() {
          _ringDuration++;
        });
        if (_ringDuration >= 15) {
          timer.cancel();
          setState(() {});
        }
      }
    });
  }

  void _startTimeout() {
    _timeoutTimer = Timer(const Duration(seconds: 45), () {
      if (!_isDisposed && mounted) {
        debugPrint('⏰ Call timeout - auto declining as missed call');
        _declineCall(isAutoTimeout: true);
      }
    });
  }

  Future<void> _showCallStatusNotification({
    required String title,
    required String body,
    required String statusType,
    String? reason,
  }) async {
    try {
      await _notificationManager.showCallStatusNotification(
        callId: widget.callData?['callId'] ?? '',
        title: title,
        body: body,
        statusType: statusType,
        extraData: {
          'reason': reason,
          'terminatedBy': _actualCurrentUserId,
          'callerId': widget.callData?['callerId'],
          'callType': _callType,
        },
      );
    } catch (e) {
      debugPrint('❌ Error showing call status notification: $e');
    }
  }

  void _closeAfterDelay(String message) {
    if (_isDisposed || _callEndedByOther) return;

    _callEndedByOther = true;

    if (mounted && !_isDisposed) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: IncomingCallDesign.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(IncomingCallDesign.radiusMd),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }

    Future.delayed(const Duration(seconds: 2), () {
      _cleanupAndExit(message);
    });
  }

  // ==================== CALL TRACKING METHODS ====================

  Future<void> _trackMissedCallStart() async {
    try {
      final callerId = widget.callData?['callerId'];
      final callType = _callType;

      if (callerId != null && _actualCurrentUserId != null) {
        debugPrint('📞 Tracking missed call start from $callerId');
        await _callService.trackCallStart(callerId, callType: callType);
      }
    } catch (e) {
      debugPrint('❌ Error tracking missed call start: $e');
    }
  }

  Future<void> _trackCallAccepted() async {
    try {
      final callerId = widget.callData?['callerId'];
      final callType = _callType;

      if (callerId != null && _actualCurrentUserId != null) {
        debugPrint('✅ Tracking call acceptance for $callerId');
        await _callService.trackCallAccepted(callerId, callType: callType);
      }
    } catch (e) {
      debugPrint('❌ Error tracking call acceptance: $e');
    }
  }

  Future<void> _trackCallDeclined({bool isAutoTimeout = false}) async {
    if (_hasTrackedMissedCall) return;

    try {
      final callerId = widget.callData?['callerId'];
      final callType = _callType;

      if (callerId != null && widget.currentUserId != null) {
        debugPrint(
            '❌ Tracking call decline for $callerId (timeout: $isAutoTimeout)');
        await _callService.trackCallDeclined(callerId, callType: callType);
        _hasTrackedMissedCall = true;
      }
    } catch (e) {
      debugPrint('❌ Error tracking call decline: $e');
    }
  }

  // ==================== CALL ACTION METHODS ====================

  Future<void> _answerCall() async {
    if (_isAccepting || _isDisposed || _callEndedByOther) return;

    debugPrint('✅ [_answerCall] Answering call...');
    setState(() {
      _isAccepting = true;
      _isDeclining = false;
    });

    _timeoutTimer?.cancel();
    _ringTimer?.cancel();

    try {
      final callId = widget.callData?['callId'];
      final roomId = widget.callData?['roomId'];
      final callerName = widget.callData?['callerName'] ?? 'Caller';
      final callerId = widget.callData?['callerId'] ?? '';
      final callType = _callType;

      debugPrint('📌 [_answerCall] Call ID: $callId');
      debugPrint('📌 [_answerCall] Room ID: $roomId');
      debugPrint('📌 [_answerCall] Caller ID: $callerId');

      if (callId == null || roomId == null) {
        _showError('Invalid call data');
        if (mounted && !_isDisposed) Navigator.pop(context);
        return;
      }

      await _notificationManager.cancelCallNotification(callId);
      await _trackCallAccepted();

      debugPrint('📞 Accepting call via API...');
      bool accepted = await _callService.acceptCall(callId);
      debugPrint('📞 Accept API returned: $accepted');

      if (!accepted) {
        _showError('Failed to accept call on server');
        return;
      }

      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted && !_isDisposed) {
        debugPrint('🚀 Navigating to call screen...');

        await Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => SimpleCallScreen(
              token: widget.userToken ?? '',
              roomId: roomId,
              callId: callId,
              callType: callType,
              isCaller: false,
              targetUserName: callerName,
              targetUserId: callerId,
              onCallEnd: (duration) async {
                debugPrint('Call ended. Duration: $duration');
                await _callService.trackCallEnd(callerId,
                    callDuration: duration);
              },
            ),
          ),
        );

        debugPrint('✅ Successfully navigated to call screen');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ [_answerCall] Error: $e');
      debugPrint('❌ Stack trace: $stackTrace');
      _showError('Failed to answer call');

      if (mounted && !_isDisposed) {
        setState(() => _isAccepting = false);
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted && !_isDisposed) Navigator.pop(context);
        });
      }
    }
  }

  Future<void> _declineCall({bool isAutoTimeout = false}) async {
    if (_isDisposed || _isDeclining || _callEndedByOther) return;

    final reason = isAutoTimeout ? 'timeout' : 'user_declined';
    debugPrint('❌ Declining call (reason: $reason)...');

    setState(() => _isDeclining = true);

    _timeoutTimer?.cancel();
    _ringTimer?.cancel();

    try {
      final callId = widget.callData?['callId'];
      final callerId = widget.callData?['callerId'];

      await _notificationManager.cancelCallNotification(callId ?? '');
      await _trackCallDeclined(isAutoTimeout: isAutoTimeout);

      if (isAutoTimeout) {
        await _showCallStatusNotification(
          title: 'Missed Call',
          body: 'Call timed out',
          statusType: 'missed',
          reason: reason,
        );
      }

      if (callId != null) {
        debugPrint('📞 Sending decline to server for call: $callId');
        bool declined = await _callService.declineCall(callId, reason: reason);
        debugPrint('📞 Decline API returned: $declined');
      }

      if (mounted && !_isDisposed) Navigator.pop(context);
    } catch (e) {
      debugPrint('❌ Decline call error: $e');
      if (mounted && !_isDisposed) Navigator.pop(context);
    }
  }

  void _cleanupAndExit(String message) {
    if (_isDisposed) return;

    debugPrint('🧹 Cleaning up and exiting: $message');

    _timeoutTimer?.cancel();
    _ringTimer?.cancel();
    _notificationSubscription?.cancel();
    _callTerminationSubscription?.cancel();

    _notificationManager
        .cancelCallNotification(widget.callData?['callId'] ?? '');

    if (mounted) Navigator.pop(context);
  }

  void _showError(String message) {
    if (mounted && !_isDisposed) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: IncomingCallDesign.danger,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(IncomingCallDesign.radiusMd),
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  // ==================== UI ====================

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: IncomingCallDesign.md,
        vertical: IncomingCallDesign.sm,
      ),
      child: Row(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _declineCall(isAutoTimeout: false),
              borderRadius:
              BorderRadius.circular(IncomingCallDesign.radiusSm),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                  borderRadius:
                  BorderRadius.circular(IncomingCallDesign.radiusSm),
                  border: Border.all(
                      color: Colors.white.withOpacity(0.1), width: 1),
                ),
                child: const Icon(Icons.arrow_back_rounded,
                    color: Colors.white, size: 20),
              ),
            ),
          ),
          const Spacer(),
          Text(
            _callEndedByOther ? 'Call Ended' : 'Incoming Call',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
            ),
          ),
          const Spacer(),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildCallerInfo() {
    final callerName = widget.callData?['callerName'] ?? 'Unknown Caller';
    final callType = _callType;
    final imageUrl = widget.callData?['imageUrl'];

    // Status colors derived from state
    final Color statusColor = _callEndedByOther
        ? IncomingCallDesign.warning
        : _isAccepting
        ? IncomingCallDesign.success
        : _isDeclining
        ? IncomingCallDesign.danger
        : _ringDuration < 15
        ? IncomingCallDesign.success
        : IncomingCallDesign.warning;

    final Color statusSoft = _callEndedByOther
        ? IncomingCallDesign.warningSoft
        : _isAccepting
        ? IncomingCallDesign.successSoft
        : _isDeclining
        ? IncomingCallDesign.dangerSoft
        : _ringDuration < 15
        ? IncomingCallDesign.successSoft
        : IncomingCallDesign.warningSoft;

    final Color statusBorder = _callEndedByOther
        ? IncomingCallDesign.warningBorder
        : _isAccepting
        ? IncomingCallDesign.successBorder
        : _isDeclining
        ? IncomingCallDesign.dangerBorder
        : _ringDuration < 15
        ? IncomingCallDesign.successBorder
        : IncomingCallDesign.warningBorder;

    final IconData statusIcon = _callEndedByOther
        ? Icons.call_end_rounded
        : _isAccepting
        ? Icons.check_circle_rounded
        : _isDeclining
        ? Icons.call_end_rounded
        : _ringDuration < 15
        ? Icons.ring_volume_rounded
        : Icons.alarm_rounded;

    final String statusText = _callEndedByOther
        ? _callEndedMessage
        : _isAccepting
        ? 'Accepting...'
        : _isDeclining
        ? 'Declining...'
        : _ringDuration < 15
        ? 'Ringing...'
        : 'Waiting...';

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Avatar
        Container(
          width: 132,
          height: 132,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: IncomingCallDesign.primarySoft,
            border: Border.all(
                color: IncomingCallDesign.primaryLight, width: 2),
            boxShadow: [
              BoxShadow(
                color: IncomingCallDesign.primary.withOpacity(0.25),
                blurRadius: 40,
                spreadRadius: 8,
              ),
            ],
          ),
          child: ClipOval(
            child: imageUrl != null && imageUrl.isNotEmpty
                ? Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.person_rounded,
                size: 60,
                color: IncomingCallDesign.primary,
              ),
            )
                : const Icon(
              Icons.person_rounded,
              size: 60,
              color: IncomingCallDesign.primary,
            ),
          ),
        ),
        const SizedBox(height: IncomingCallDesign.xl),

        // Caller name
        Text(
          callerName,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: IncomingCallDesign.sm),

        // Call type tag
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: IncomingCallDesign.md, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(IncomingCallDesign.radiusSm),
            border: Border.all(
                color: Colors.white.withOpacity(0.1), width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                callType == 'video'
                    ? Icons.videocam_rounded
                    : Icons.call_rounded,
                size: 14,
                color: Colors.white70,
              ),
              const SizedBox(width: 6),
              Text(
                callType == 'video' ? 'Video Call' : 'Audio Call',
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
        const SizedBox(height: IncomingCallDesign.md),

        // Status pill (tinted tag)
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: IncomingCallDesign.md, vertical: 8),
          decoration: BoxDecoration(
            color: statusSoft,
            borderRadius: BorderRadius.circular(IncomingCallDesign.radiusSm),
            border: Border.all(color: statusBorder, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(statusIcon, color: statusColor, size: 16),
              const SizedBox(width: 8),
              Text(
                statusText,
                style: TextStyle(
                  color: statusColor,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.2,
                ),
              ),
              if (!_callEndedByOther) ...[
                const SizedBox(width: 6),
                Text(
                  '($_ringDuration s)',
                  style: TextStyle(
                    color: statusColor.withOpacity(0.7),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    final callType = _callType;
    final isVideoCall = callType == 'video';
    final buttonsEnabled = !_isAccepting && !_isDeclining && !_callEndedByOther;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        IncomingCallDesign.lg,
        IncomingCallDesign.md,
        IncomingCallDesign.lg,
        IncomingCallDesign.xl,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: IncomingCallDesign.lg, vertical: IncomingCallDesign.md + 2),
        decoration: BoxDecoration(
          color: IncomingCallDesign.darkSurface.withOpacity(0.9),
          borderRadius: BorderRadius.circular(IncomingCallDesign.radiusLg + 4),
          border:
          Border.all(color: Colors.white.withOpacity(0.08), width: 1),
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
            _buildActionCircleButton(
              icon: Icons.call_end_rounded,
              label: !buttonsEnabled
                  ? (_callEndedByOther ? 'Call Ended' : 'Declining...')
                  : 'Decline',
              enabled: buttonsEnabled,
              isPrimary: false,
              onTap: () => _declineCall(isAutoTimeout: false),
            ),
            _buildActionCircleButton(
              icon: isVideoCall
                  ? Icons.videocam_rounded
                  : Icons.call_rounded,
              label: !buttonsEnabled
                  ? (_callEndedByOther ? 'Unavailable' : 'Accepting...')
                  : (isVideoCall ? 'Video' : 'Audio'),
              enabled: buttonsEnabled,
              isPrimary: true,
              onTap: _answerCall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCircleButton({
    required IconData icon,
    required String label,
    required bool enabled,
    required bool isPrimary,
    required VoidCallback onTap,
  }) {
    final Color base = isPrimary
        ? IncomingCallDesign.success
        : IncomingCallDesign.danger;
    final Color soft = isPrimary
        ? IncomingCallDesign.successSoft
        : IncomingCallDesign.dangerSoft;
    final Color border = isPrimary
        ? IncomingCallDesign.successBorder
        : IncomingCallDesign.dangerBorder;

    final Color bg = enabled ? soft : IncomingCallDesign.neutralSoft;
    final Color ic = enabled ? base : IncomingCallDesign.neutral;
    final Color bd = enabled ? border : IncomingCallDesign.neutralBorder;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: enabled ? onTap : null,
            borderRadius: BorderRadius.circular(34),
            child: Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: bg,
                shape: BoxShape.circle,
                border: Border.all(color: bd, width: 1.5),
                boxShadow: [
                  if (enabled)
                    BoxShadow(
                      color: base.withOpacity(0.25),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                      spreadRadius: -2,
                    ),
                ],
              ),
              child: Icon(icon, color: ic, size: 30),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: enabled ? Colors.white70 : Colors.white38,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }

  Widget _buildCallEndedOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.85),
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(
                horizontal: IncomingCallDesign.lg),
            padding: const EdgeInsets.all(IncomingCallDesign.xl),
            decoration: BoxDecoration(
              color: IncomingCallDesign.darkSurface,
              borderRadius: BorderRadius.circular(IncomingCallDesign.radiusLg),
              border:
              Border.all(color: Colors.white.withOpacity(0.08), width: 1),
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
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: IncomingCallDesign.warningSoft,
                    shape: BoxShape.circle,
                    border:
                    Border.all(color: IncomingCallDesign.warningBorder),
                  ),
                  child: const Icon(
                    Icons.call_end_rounded,
                    size: 38,
                    color: IncomingCallDesign.warning,
                  ),
                ),
                const SizedBox(height: IncomingCallDesign.lg),
                Text(
                  _callEndedMessage,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: IncomingCallDesign.sm),
                const Text(
                  'Closing in 3 seconds...',
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (!_callEndedByOther) {
          _declineCall(isAutoTimeout: false);
        }
        return false;
      },
      child: Scaffold(
        backgroundColor: IncomingCallDesign.darkBg,
        body: Container(
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
          child: SafeArea(
            child: Stack(
              children: [
                Column(
                  children: [
                    _buildHeader(),
                    Expanded(
                      child: Center(child: _buildCallerInfo()),
                    ),
                    if (!_callEndedByOther) _buildActionButtons(),
                  ],
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
    debugPrint('🧹 IncomingCallScreen disposing...');
    _isDisposed = true;

    _timeoutTimer?.cancel();
    _ringTimer?.cancel();
    _notificationSubscription?.cancel();
    _callTerminationSubscription?.cancel();

    if (!_hasTrackedMissedCall &&
        !_isAccepting &&
        !_isDeclining &&
        !_callEndedByOther) {
      debugPrint('📞 Screen disposed without action, tracking as missed call');
      _trackCallDeclined(isAutoTimeout: false);
    }

    super.dispose();
    debugPrint('🧹 Dispose completed');
  }
}