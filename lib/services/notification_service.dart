// services/notification_service.dart
import 'dart:async';
import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:staffsync/models/user.dart';
import '../core/navigation.dart';
import '../screens/call/incoming_call_screen.dart';
import '../screens/ticket/ticket_detail_screen.dart';
import '../screens/ticket/my_tickets_screen.dart';
import '../screens/leave_screen.dart';
import '../screens/announcement_screen.dart';
import '../screens/payroll_screen.dart';
import '../screens/daily_task_screen.dart';
import '../screens/chat_home_screen.dart';
import '../screens/expense_list_screen.dart';
import '../screens/assets_screen.dart';
import '../screens/holiday_screen.dart';
import '../screens/celebration_screen.dart';
import '../screens/onboarding_screen.dart';
import '../screens/policy_screen.dart';
import '../screens/home_screen.dart';
import '../services/auth_service.dart';

// ------------------------------------------------------------------
// CONSTANTS & ENUMS
// ------------------------------------------------------------------

class NotificationConstants {
  static const String appName = 'StaffSync';
  static const String incomingCallChannelId = 'staffsync_calls';
  static const String callStatusChannelId = 'staffsync_call_status';
  static const String generalChannelId = 'staffsync_general';
  static const String defaultCallerName = 'Unknown';
  static const String defaultCallType = 'audio';
  static const Color primaryColor = Color(0xFF2196F3);

  static const String ringtoneSound = 'notification'; // was 'ringtone'
  static const String ringtoneIos = 'notification.aiff'; // update if iOS file
}

enum NotificationType {
  incomingCall('incoming_call'),
  callDeclined('call_declined'),
  callMissed('call_missed'),
  callEnded('call_ended'),
  callAccepted('call_accepted'),
  employeeInteraction('employee_interaction'),
  ticket('ticket'),
  attendance('attendance'),
  leave('leave'),
  leaveUpdate('leave_update'),
  payroll('payroll'),
  announcement('announcement'),
  task('task'),
  expense('expense'),
  message('message'),
  asset('asset'),
  celebration('celebration'),
  holiday('holiday'),
  security('security'),
  onboarding('onboarding'),
  policy('policy'),
  general('general');

  final String value;
  const NotificationType(this.value);

  static NotificationType fromString(String? value) {
    return values.firstWhere(
          (type) => type.value == value,
      orElse: () => NotificationType.general,
    );
  }
}

enum InteractionType {
  startedCall('started_call'),
  unknown('unknown');

  final String value;
  const InteractionType(this.value);

  static InteractionType fromString(String? value) {
    return values.firstWhere(
          (type) => type.value == value,
      orElse: () => InteractionType.unknown,
    );
  }
}

// ------------------------------------------------------------------
// SHARED PLUGIN INSTANCE
// ------------------------------------------------------------------

final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
FlutterLocalNotificationsPlugin();

// ------------------------------------------------------------------
// NOTIFICATION CHANNEL MANAGER
// ------------------------------------------------------------------

class NotificationChannelManager {
  static Future<void> createChannels() async {
    final androidPlugin = _localNotificationsPlugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin == null) return;

    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        NotificationConstants.incomingCallChannelId,
        'StaffSync Calls',
        description: 'Incoming & ongoing call notifications',
        importance: Importance.max,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('notification'),
        enableVibration: true,
        enableLights: true,
        ledColor: NotificationConstants.primaryColor,
        showBadge: false,
      ),
    );

    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        NotificationConstants.callStatusChannelId,
        'Call Status',
        description: 'Call ended/declined notifications',
        importance: Importance.high,
        playSound: false,
        enableVibration: false,
      ),
    );

    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        NotificationConstants.generalChannelId,
        'StaffSync Notifications',
        description: 'General app notifications',
        importance: Importance.high,
      ),
    );
  }

  /// ✅ Check and request full-screen intent permission (Android 14+).
  /// Without this, incoming call notifications won't wake/light up the screen.
  static Future<bool> checkFullScreenIntentPermission() async {
    try {
      final androidPlugin = _localNotificationsPlugin
          .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin == null) return true; // Not Android

      // Check if we can use full screen intents
      final canUse = await androidPlugin.areNotificationsEnabled() ?? true;
      debugPrint('📱 Full-screen intent / notification enabled: $canUse');

      if (!canUse) {
        debugPrint('⚠️ Notifications disabled — requesting permission');
        final granted = await androidPlugin.requestNotificationsPermission();
        debugPrint('📱 Notification permission result: $granted');
        return granted ?? false;
      }

      return canUse;
    } catch (e) {
      debugPrint('⚠️ Full-screen intent check error: $e');
      return true; // Assume allowed on error
    }
  }
}

// ------------------------------------------------------------------
// NOTIFICATION DATA MODEL
// ------------------------------------------------------------------

class NotificationData {
  final String? id;
  final String title;
  final String body;
  final Map<String, dynamic> payload;
  final NotificationType type;
  final DateTime timestamp;

  NotificationData({
    this.id,
    required this.title,
    required this.body,
    required this.payload,
    required this.type,
  }) : timestamp = DateTime.now();

  factory NotificationData.fromRemoteMessage(RemoteMessage message) {
    final data = message.data;

    final rawType = data['type'];
    final interactionType = data['interactionType'];
    final isStartedCall = rawType == NotificationType.employeeInteraction.value &&
        interactionType == InteractionType.startedCall.value;

    final normalizedPayload = isStartedCall
        ? NotificationPayloadProcessor.convertToCallData(data)
        : Map<String, dynamic>.from(data);

    final type = isStartedCall
        ? NotificationType.incomingCall
        : NotificationType.fromString(rawType);

    return NotificationData(
      id: normalizedPayload['notificationId']?.toString() ??
          normalizedPayload['callId'] ??
          message.messageId,
      title: message.notification?.title ??
          normalizedPayload['title'] ??
          NotificationConstants.appName,
      body: message.notification?.body ??
          normalizedPayload['body'] ??
          'New notification',
      payload: normalizedPayload,
      type: type,
    );
  }

  String get callerName =>
      payload['callerName'] ??
          payload['senderName'] ??
          NotificationConstants.defaultCallerName;

  String? get callId => payload['callId'];
  String? get roomId => payload['roomId'];
  String? get interactionType => payload['interactionType'];
}

// ------------------------------------------------------------------
// NOTIFICATION DISPLAYER
// ------------------------------------------------------------------

class NotificationDisplayer {
  static int _notificationIdFor(NotificationData n) {
    final key = n.id ?? n.callId ?? n.payload['id']?.toString() ?? n.title;
    return key.hashCode & 0x7fffffff;
  }

  static void openIncomingCallScreen(NotificationData notification) {
    _navigateToIncomingCallScreen(notification);
  }

  /// Returns `true` if the current user is the one who triggered the
  /// action described by this notification (e.g. they hung up / declined).
  /// Used to suppress "call ended" notifications the user caused themselves.
  static Future<bool> isFromSelf(NotificationData n) async {
    final actionBy = n.payload['actionBy']?.toString();
    if (actionBy == null || actionBy.isEmpty) return false;
    final me = await CallStateManager.getCurrentUserId();
    return me?.id == actionBy; // adjust field name to your User model
  }

  static Future<void> show(NotificationData notification) async {
    if (CallStateManager.currentCallId != null &&
        notification.type == NotificationType.incomingCall) {
      debugPrint('📞 Already in a call — suppressing incoming call notification');
      return;
    }

    switch (notification.type) {
      case NotificationType.incomingCall:
        await _showIncomingCallNotification(notification);
        break;

      case NotificationType.callEnded:
      case NotificationType.callDeclined:
        debugPrint('📞 Call ended/declined — notification suppressed');
        if (notification.callId != null) {
          await cancelByCallId(notification.callId!);
        }
        break;

      case NotificationType.callMissed:
        await _showCallStatusNotification(notification);
        if (notification.callId != null) {
          await cancelByCallId(notification.callId!);
        }
        break;

      case NotificationType.callAccepted:
        debugPrint('📞 Call accepted, no notification shown');
        if (notification.callId != null) {
          await cancelByCallId(notification.callId!);
        }
        break;

      default:
        await _showGeneralNotification(notification);
    }
  }

  static Future<void> _showGeneralNotification(
      NotificationData notification) async {
    final androidDetails = AndroidNotificationDetails(
      NotificationConstants.generalChannelId,
      'StaffSync Notifications',
      channelDescription: 'General app notifications',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
      color: NotificationConstants.primaryColor,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    await _localNotificationsPlugin.show(
      _notificationIdFor(notification),
      notification.title,
      notification.body,
      NotificationDetails(android: androidDetails, iOS: iosDetails),
      payload: jsonEncode(notification.payload),
    );

    debugPrint('📱 General notification shown: ${notification.title}');
  }

  static Future<void> _showIncomingCallNotification(
      NotificationData notification) async {
    if (CallStateManager.currentCallId != null) {
      debugPrint(
          '📞 Already in call ${CallStateManager.currentCallId}, skipping incoming');
      return;
    }

    final actions = _createCallActions(notification.callId);

    final androidDetails = AndroidNotificationDetails(
      NotificationConstants.incomingCallChannelId,
      'StaffSync Calls',
      channelDescription: 'Incoming & ongoing call notifications',
      importance: Importance.max,
      priority: Priority.max,
      category: AndroidNotificationCategory.call,
      fullScreenIntent: true,
      visibility: NotificationVisibility.public,
      ongoing: true,
      autoCancel: false,
      playSound: true,
      sound: const RawResourceAndroidNotificationSound(
          NotificationConstants.ringtoneSound),
      enableVibration: true,
      enableLights: true,
      ledColor: NotificationConstants.primaryColor,
      ledOnMs: 1000,
      ledOffMs: 500,
      icon: '@mipmap/ic_launcher',
      actions: actions,
    );

    final iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: NotificationConstants.ringtoneIos,
      categoryIdentifier: 'INCOMING_CALL',
      interruptionLevel: InterruptionLevel.timeSensitive,
      threadIdentifier: 'call-${notification.callId}',
    );

    await _localNotificationsPlugin.show(
      _notificationIdFor(notification),
      notification.title,
      notification.body,
      NotificationDetails(android: androidDetails, iOS: iosDetails),
      payload: jsonEncode({
        ...notification.payload,
        'type': NotificationType.incomingCall.value,
        'fullScreen': true,
      }),
    );

    debugPrint(
        '📞 Incoming call notification shown for ${notification.callerName}');

    // ✅ Also navigate to IncomingCallScreen directly when app is in foreground
    _navigateToIncomingCallScreen(notification);
  }

  /// ✅ Navigate to IncomingCallScreen when a foreground notification arrives.
  /// This ensures the call UI shows even if the notification doesn't wake the
  /// screen (e.g. Android 14+ full-screen intent denied).
  static void _navigateToIncomingCallScreen(NotificationData notification) {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final token = await AuthService().getToken();
        if (token == null) {
          debugPrint('❌ No auth token — cannot open IncomingCallScreen');
          return;
        }

        final nav = navigatorKey.currentState;
        if (nav == null) {
          debugPrint('❌ Navigator not ready — cannot open IncomingCallScreen');
          return;
        }

        debugPrint('📞 Opening IncomingCallScreen from notification');
        nav.push(
          MaterialPageRoute(
            builder: (_) => IncomingCallScreen(
              callData: notification.payload,
              userToken: token,
            ),
          ),
        );
      } catch (e) {
        debugPrint('❌ Error navigating to IncomingCallScreen: $e');
      }
    });
  }

  static Future<void> _showCallStatusNotification(
      NotificationData notification) async {
    final androidDetails = AndroidNotificationDetails(
      NotificationConstants.callStatusChannelId,
      'Call Status',
      channelDescription: 'Call ended/declined notifications',
      importance: Importance.high,
      priority: Priority.high,
      autoCancel: true,
      playSound: false,
      enableVibration: false,
      icon: '@mipmap/ic_launcher',
      color: Colors.grey,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: false,
      presentSound: false,
    );

    await _localNotificationsPlugin.show(
      _notificationIdFor(notification),
      notification.title,
      notification.body,
      NotificationDetails(android: androidDetails, iOS: iosDetails),
      payload: jsonEncode(notification.payload),
    );

    debugPrint(
        '📞 Call status notification shown for call: ${notification.callId}');
  }

  static List<AndroidNotificationAction> _createCallActions(String? callId) {
    final suffix = callId ?? 'unknown';
    return [
      AndroidNotificationAction(
        'accept_$suffix',
        'Accept',
        titleColor: Colors.green,
        showsUserInterface: true,
        cancelNotification: true,
      ),
      AndroidNotificationAction(
        'decline_$suffix',
        'Decline',
        titleColor: Colors.red,
        showsUserInterface: true,
        cancelNotification: true,
      ),
    ];
  }

  static Future<void> cancelAll() async {
    await _localNotificationsPlugin.cancelAll();
    debugPrint('🗑️ All notifications cancelled');
  }

  /// Cancels the incoming-call ringing notification(s) for [callId],
  /// covering both **pending** (not-yet-delivered) and **active**
  /// (currently-displayed) notifications.
  static Future<void> cancelByCallId(String callId) async {
    var cancelled = 0;

    // 1. Pending (not yet delivered) notifications.
    final pending =
    await _localNotificationsPlugin.pendingNotificationRequests();
    for (final n in pending) {
      final payload = _tryDecodePayload(n.payload);
      if (payload != null &&
          payload['callId'] == callId &&
          payload['type'] == NotificationType.incomingCall.value) {
        await _localNotificationsPlugin.cancel(n.id);
        cancelled++;
        debugPrint('🗑️ Cancelled pending notification ${n.id} for call $callId');
      }
    }

    // 2. Already-displayed (active) notifications.
    final active = await _localNotificationsPlugin.getActiveNotifications();
    for (final n in active) {
      final payload = _tryDecodePayload(n.payload);
      if (payload != null &&
          payload['callId'] == callId &&
          payload['type'] == NotificationType.incomingCall.value) {
        if (n.id != null) {
          await _localNotificationsPlugin.cancel(n.id!);
          cancelled++;
          debugPrint(
              '🗑️ Cancelled active notification ${n.id} for call $callId');
        }
      }
    }

    if (cancelled > 0) {
      debugPrint('🗑️ Cancelled $cancelled notification(s) for call $callId');
    }
  }

  static Future<void> cancelIncomingCallNotification(String callId) async {
    final pending =
    await _localNotificationsPlugin.pendingNotificationRequests();

    for (final n in pending) {
      final payload = _tryDecodePayload(n.payload);
      if (payload != null &&
          payload['callId'] == callId &&
          payload['type'] == NotificationType.incomingCall.value) {
        await _localNotificationsPlugin.cancel(n.id);
        debugPrint('📞 Cancelled incoming call notification for: $callId');
      }
    }
  }

  static Map<String, dynamic>? _tryDecodePayload(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }
}

// ------------------------------------------------------------------
// NOTIFICATION PAYLOAD PROCESSOR
// ------------------------------------------------------------------

class NotificationPayloadProcessor {
  static Map<String, dynamic> convertToCallData(Map<String, dynamic> data) {
    try {
      final metadataStr = data['metadata'];
      Map<String, dynamic> metadata = {};

      if (metadataStr is String && metadataStr.isNotEmpty) {
        metadata = jsonDecode(metadataStr) as Map<String, dynamic>;
      } else if (metadataStr is Map) {
        metadata = Map<String, dynamic>.from(metadataStr);
      }

      return {
        'type': NotificationType.incomingCall.value,
        'callId':
        data['callId'] ?? 'call_${DateTime.now().millisecondsSinceEpoch}',
        'roomId': data['roomId'] ??
            'room_${data['senderId']}_${data['receiverId']}',
        'callerId': data['senderId'],
        'callerName':
        data['senderName'] ?? NotificationConstants.defaultCallerName,
        'callType': metadata['callType'] ??
            metadata['type'] ??
            data['callType'] ??
            (data['type'] != null && data['type'] != NotificationType.incomingCall.value ? data['type'] : null) ??
            NotificationConstants.defaultCallType,
        'timestamp':
        metadata['timestamp'] ?? DateTime.now().toIso8601String(),
        'imageUrl': data['imageUrl'],
      };
    } catch (e) {
      debugPrint('❌ convertToCallData error: $e');
      return {
        'type': NotificationType.incomingCall.value,
        'callId': 'call_temp_${DateTime.now().millisecondsSinceEpoch}',
        'callerName':
        data['senderName'] ?? NotificationConstants.defaultCallerName,
        'callType': NotificationConstants.defaultCallType,
      };
    }
  }

  static void handleEarlyClickPayload(String payload) {
    try {
      final data = jsonDecode(payload) as Map<String, dynamic>;
      handleEarlyNotificationClick(data);
    } catch (e) {
      debugPrint('❌ Early payload parse error: $e');
    }
  }

  static void handleEarlyNotificationClick(Map<String, dynamic> data) {
    final type = NotificationType.fromString(data['type']);
    final interactionType = InteractionType.fromString(data['interactionType']);

    debugPrint('🔔 Early click handler → type: ${type.value}');

    if (type == NotificationType.incomingCall ||
        (type == NotificationType.employeeInteraction &&
            interactionType == InteractionType.startedCall)) {
      _openIncomingCallScreenFromEarly(data, type);
    } else {
      NotificationNavigator.navigateFromNotification(data);
    }
  }

  static void _openIncomingCallScreenFromEarly(
      Map<String, dynamic> data,
      NotificationType type,
      ) {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final callData = type == NotificationType.employeeInteraction
          ? convertToCallData(data)
          : data;

      final token = await AuthService().getToken();
      if (token == null) {
        debugPrint('❌ [EarlyClick] No auth token — cannot open call screen');
        return;
      }

      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (_) => IncomingCallScreen(
            callData: callData,
            userToken: token,
          ),
        ),
      );
    });
  }
}

// ------------------------------------------------------------------
// CALL STATE MANAGER
// ------------------------------------------------------------------

class CallStateManager {
  static String? _currentCallId;
  static Completer<void>? _callEndCompleter;

  static String? get currentCallId => _currentCallId;

  static void setCurrentCall(String callId) {
    _currentCallId = callId;
    _callEndCompleter = Completer<void>();
    debugPrint('📞 Tracking call: $callId');
  }

  static void clearCurrentCall() {
    final id = _currentCallId;
    _currentCallId = null;
    _callEndCompleter?.complete();
    _callEndCompleter = null;
    if (id != null) {
      NotificationDisplayer.cancelByCallId(id);
    }
    debugPrint('📞 Call tracking cleared');
  }

  static Future<void> waitForCallEnd() async {
    await _callEndCompleter?.future;
  }

  static bool isCurrentCall(String? callId) =>
      callId != null && callId == _currentCallId;

  static Future<User?> getCurrentUserId() {
    return AuthService().getCurrentUser();
  }
}

// ------------------------------------------------------------------
// NOTIFICATION NAVIGATOR
// ------------------------------------------------------------------

class NotificationNavigator {
  static Map<String, dynamic>? _pendingCallData;
  static bool _appReady = false;

  static void navigateFromNotification(Map<String, dynamic> data) {
    final rawType = data['type'];
    final interactionType = data['interactionType'];
    final isStartedCall =
        rawType == NotificationType.employeeInteraction.value &&
            interactionType == InteractionType.startedCall.value;

    final notification = NotificationData(
      title: data['title'] ?? NotificationConstants.appName,
      body: data['body'] ?? '',
      payload: isStartedCall
          ? NotificationPayloadProcessor.convertToCallData(data)
          : data,
      type: isStartedCall
          ? NotificationType.incomingCall
          : NotificationType.fromString(rawType),
    );

    // Gate incoming calls until the app has finished Splash/Auth navigation.
    if (notification.type == NotificationType.incomingCall) {
      _pendingCallData = Map<String, dynamic>.from(notification.payload);
      _openPendingCall();
      return;
    }

    _handleNotificationNavigation(notification);
  }

  /// Call this only after Splash/Auth navigation is complete.
  static void markAppReady() {
    _appReady = true;
    _openPendingCall();
  }

  static void _openPendingCall() {
    if (!_appReady) return;
    if (_pendingCallData == null) return;
    if (navigatorKey.currentState == null) return;

    final data = _pendingCallData!;
    _pendingCallData = null;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final token = await AuthService().getToken();
      if (token == null) {
        debugPrint('❌ [PendingCall] No auth token — cannot open call screen');
        return;
      }

      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (_) => IncomingCallScreen(
            callData: data,
            userToken: token,
          ),
        ),
      );
    });
  }

  static void _handleNotificationNavigation(NotificationData notification) {
    debugPrint(
        '🔗 Navigating from notification type: ${notification.type.value}');

    switch (notification.type) {
      case NotificationType.incomingCall:
        _navigateToIncomingCall(notification);
        break;
      case NotificationType.callAccepted:
        _navigateToCallScreen(notification);
        break;
      case NotificationType.callDeclined:
      case NotificationType.callMissed:
      case NotificationType.callEnded:
        _handleCallTermination(notification);
        break;
      case NotificationType.employeeInteraction:
        _handleEmployeeInteraction(notification);
        break;
      case NotificationType.ticket:
        _navigateToTicket(notification);
        break;
      case NotificationType.leave:
      case NotificationType.leaveUpdate:
        _navigateToLeave(notification);
        break;
      case NotificationType.attendance:
        _navigateToAttendance(notification);
        break;
      case NotificationType.payroll:
        _navigateToPayroll(notification);
        break;
      case NotificationType.announcement:
        _navigateToAnnouncement(notification);
        break;
      case NotificationType.task:
        _navigateToTask(notification);
        break;
      case NotificationType.message:
        _navigateToChat(notification);
        break;
      case NotificationType.expense:
        _navigateToExpense(notification);
        break;
      case NotificationType.asset:
        _navigateToAssets(notification);
        break;
      case NotificationType.holiday:
        _navigateToHoliday(notification);
        break;
      case NotificationType.celebration:
        _navigateToCelebration(notification);
        break;
      case NotificationType.onboarding:
        _navigateToOnboarding(notification);
        break;
      case NotificationType.policy:
        _navigateToPolicy(notification);
        break;
      default:
        debugPrint('📌 Unhandled notification type: ${notification.type.value}');
    }
  }

  static void _navigateToLeave(NotificationData notification) {
    navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (_) => const LeavesScreen(),
      ),
    );
  }

  static void _navigateToAttendance(NotificationData notification) {
    navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (_) => const HomeScreen(),
      ),
    );
  }

  static void _navigateToPayroll(NotificationData notification) {
    navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (_) => const PayrollListScreen(),
      ),
    );
  }

  static void _navigateToAnnouncement(NotificationData notification) {
    navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (_) => const AnnouncementsPage(),
      ),
    );
  }

  static void _navigateToTask(NotificationData notification) {
    navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (_) => const DailyTasksScreen(),
      ),
    );
  }

  static void _navigateToChat(NotificationData notification) {
    navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (_) => const ChatHomeScreen(),
      ),
    );
  }

  static void _navigateToExpense(NotificationData notification) {
    navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (_) => const ExpenseListScreen(),
      ),
    );
  }

  static void _navigateToAssets(NotificationData notification) {
    navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (_) => const AssetsScreen(),
      ),
    );
  }

  static void _navigateToHoliday(NotificationData notification) {
    navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (_) => const PremiumHolidayCalendar(),
      ),
    );
  }

  static void _navigateToCelebration(NotificationData notification) {
    navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (_) => const CelebrationScreen(),
      ),
    );
  }

  static void _navigateToOnboarding(NotificationData notification) {
    navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (_) => const OnboardingScreen(),
      ),
    );
  }

  static void _navigateToPolicy(NotificationData notification) {
    navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (_) => const PolicyScreen(),
      ),
    );
  }

  static void _navigateToTicket(NotificationData notification) {
    final ticketId = notification.payload['ticketId']?.toString();
    if (ticketId != null && ticketId.isNotEmpty) {
      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (_) => TicketDetailScreen(ticketId: ticketId),
        ),
      );
    } else {
      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (_) => const MyTicketsScreen(),
        ),
      );
    }
  }

  static void _navigateToIncomingCall(NotificationData notification) {
    final callData = Map<String, dynamic>.from(notification.payload);

    navigatorKey.currentState?.pushNamed(
      '/incoming-call',
      arguments: {'callData': callData},
    );
  }

  static void _navigateToCallScreen(NotificationData notification) {
    final roomId = notification.roomId;
    final callId = notification.callId;
    if (roomId == null || callId == null) return;

    final calleeName = notification.payload['calleeName'] ?? 'User';

    navigatorKey.currentState?.pushNamed(
      '/call',
      arguments: {
        'token': '',
        'roomId': roomId,
        'callId': callId,
        'callType': 'video',
        'isCaller': true,
        'targetUserName': calleeName,
        'targetUserId': '',
        'fromNotification': true,
      },
    );
  }

  static void _handleCallTermination(NotificationData notification) {
    final declinedBy = notification.payload['declinedBy'];

    debugPrint('📞 Call terminated — type: ${notification.type.value}');

    final shouldClose = notification.type == NotificationType.callEnded ||
        declinedBy == null; // can't identify self → safest to close

    if (shouldClose) {
      _closeCallScreens();
    }
    _showCallStatusMessage(notification);
  }

  static void _handleEmployeeInteraction(NotificationData notification) {
    debugPrint(
        '👥 Employee interaction: ${notification.payload['interactionType']}');
  }

  static void _closeCallScreens() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final nav = navigatorKey.currentState;
      if (nav == null) return;

      nav.popUntil((route) => !_isCallRoute(route.settings.name));
      CallStateManager.clearCurrentCall();
    });
  }

  static bool _isCallRoute(String? routeName) =>
      routeName == '/call' ||
          routeName == '/incoming-call' ||
          routeName == '/call-screen';

  static void _showCallStatusMessage(NotificationData notification) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = navigatorKey.currentContext;
      if (context == null) return;

      final (message, color) = _getCallStatusInfo(notification);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: color,
          duration: const Duration(seconds: 4),
        ),
      );
    });
  }

  static (String, Color) _getCallStatusInfo(NotificationData notification) {
    final reason = notification.payload['reason'];

    switch (notification.type) {
      case NotificationType.callDeclined:
        return (
        'Call was declined${reason != null ? ' ($reason)' : ''}',
        Colors.orange,
        );
      case NotificationType.callMissed:
        return ('Missed call', Colors.red.shade700);
      case NotificationType.callEnded:
        return (
        'Call ended${reason != null ? ' ($reason)' : ''}',
        Colors.blue,
        );
      default:
        return ('Call status updated', Colors.grey);
    }
  }
}

// ------------------------------------------------------------------
// FCM TOKEN MANAGER
// ------------------------------------------------------------------

class FCMTokenManager {
  static final FirebaseMessaging _firebaseMessaging =
      FirebaseMessaging.instance;

  static Future<String?> getToken() async {
    try {
      return await _firebaseMessaging.getToken();
    } catch (e) {
      debugPrint('❌ Error getting FCM token: $e');
      return null;
    }
  }

  static Future<void> saveToken() async {
    try {
      final token = await getToken();
      if (token == null) return;
      await _saveTokenToBackend(token);

      _firebaseMessaging.onTokenRefresh.listen(_saveTokenToBackend);
    } catch (e) {
      debugPrint('❌ Error saving FCM token: $e');
    }
  }

  static Future<void> _saveTokenToBackend(String token) async {
    try {
      final userToken = await AuthService().getToken();
      if (userToken == null) return;
      debugPrint('💾 FCM token ready for backend: $token');
    } catch (e) {
      debugPrint('❌ Error in _saveTokenToBackend: $e');
    }
  }

  static Future<void> deleteToken() => _firebaseMessaging.deleteToken();
}

// ------------------------------------------------------------------
// BACKGROUND MESSAGE HANDLER
// ------------------------------------------------------------------

@pragma('vm:entry-point')
Future<void> firebaseBackgroundMessageHandler(RemoteMessage message) async {
  await NotificationService.initialize();

  final notification = NotificationData.fromRemoteMessage(message);

  // 🙈 Suppress terminal call notifications caused by the current user.
  if (await NotificationDisplayer.isFromSelf(notification)) {
    debugPrint('🙈 [background] Suppressing self-triggered '
        '${notification.type.value} for call ${notification.callId}');
    return;
  }

  await NotificationDisplayer.show(notification);
}

// ------------------------------------------------------------------
// MAIN NOTIFICATION SERVICE
// ------------------------------------------------------------------

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  /// Terminal call states the acting user does not need to be notified
  /// about when they themselves caused them.
  static const Set<NotificationType> _terminalTypes = {
    NotificationType.callEnded,
    NotificationType.callDeclined,
    NotificationType.callMissed,
  };

  final StreamController<Map<String, dynamic>> _notificationStream =
  StreamController<Map<String, dynamic>>.broadcast();

  Map<String, dynamic>? _initialNotificationData;
  StreamSubscription<RemoteMessage>? _onMessageSub;
  StreamSubscription<RemoteMessage>? _onOpenedSub;

  // 🔒 Client-side dedupe: same notificationId within 2 minutes is dropped.
  final Set<String> _recentIds = <String>{};

  Function(Map<String, dynamic>)? onNotificationReceived;
  Function(Map<String, dynamic>)? onNotificationClicked;

  Stream<Map<String, dynamic>> get notificationStream =>
      _notificationStream.stream;

  // ─────────────────────────────────────────────────────────────
  // INITIALIZATION
  // ─────────────────────────────────────────────────────────────

  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;
    try {
      await NotificationChannelManager.createChannels();
      await _initializeLocalNotifications();
      _initialized = true;
      debugPrint('✅ Local notifications initialized');
    } catch (e) {
      debugPrint('❌ Failed to initialize local notifications: $e');
    }
  }

  static Future<void> _initializeLocalNotifications() async {
    const androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    final iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      onDidReceiveLocalNotification: (id, title, body, payload) {
        if (payload != null) {
          NotificationPayloadProcessor.handleEarlyClickPayload(payload);
        }
      },
    );

    await _localNotificationsPlugin.initialize(
      InitializationSettings(android: androidSettings, iOS: iosSettings),
      onDidReceiveNotificationResponse: (response) {
        if (response.payload == null) return;
        try {
          final data = jsonDecode(response.payload!) as Map<String, dynamic>;
          NotificationPayloadProcessor.handleEarlyNotificationClick(data);
        } catch (e) {
          debugPrint('❌ Error parsing notification payload: $e');
        }
      },
    );
  }

  // ─────────────────────────────────────────────────────────────
  // INSTANCE METHODS
  // ─────────────────────────────────────────────────────────────

  Future<void> init() async {
    try {
      await _requestPermissions();
      _setupFirebaseListeners();
      await FCMTokenManager.saveToken();
      await _storeInitialNotification();

      // ✅ Check full-screen intent permission for incoming calls (Android 14+)
      await NotificationChannelManager.checkFullScreenIntentPermission();

      debugPrint('✅ NotificationService fully initialized');
    } catch (e) {
      debugPrint('❌ NotificationService init failed: $e');
    }
  }

  Future<void> _requestPermissions() async {
    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint('📱 Notification permission: ${settings.authorizationStatus.name}');

    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
      alert: false, // ← let the local notification plugin own the UI
      badge: true,
      sound: false,
    );
  }

  void _setupFirebaseListeners() {
    _onMessageSub?.cancel();
    _onOpenedSub?.cancel();

    _onMessageSub = FirebaseMessaging.onMessage.listen((message) {
      _handleForegroundMessage(message);
    });

    _onOpenedSub = FirebaseMessaging.onMessageOpenedApp.listen(
      NotificationService.handleMessageOpenedApp,
    );
  }

  Future<void> _storeInitialNotification() async {
    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) {
      final notification = NotificationData.fromRemoteMessage(initial);
      _initialNotificationData = notification.payload;
      debugPrint('📱 Stored initial notification data');
    }
  }

  // ─────────────────────────────────────────────────────────────
  // HANDLERS
  // ─────────────────────────────────────────────────────────────

  /// Returns `true` if this notification should be processed (not a
  /// duplicate), `false` if it has already been seen recently.
  bool _dedupe(NotificationData notification) {
    final id = notification.id;
    if (id == null || id.isEmpty) return true;
    if (_recentIds.contains(id)) {
      debugPrint('🔁 [dedupe] Dropped duplicate notification: $id');
      return false;
    }
    _recentIds.add(id);
    Timer(const Duration(minutes: 2), () => _recentIds.remove(id));
    return true;
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final notification = NotificationData.fromRemoteMessage(message);

    if (!_dedupe(notification)) return;

    if (_terminalTypes.contains(notification.type) &&
        await NotificationDisplayer.isFromSelf(notification)) {
      debugPrint('🙈 Suppressing self-triggered notification');
      return;
    }

    _notificationStream.add(notification.payload);
    onNotificationReceived?.call(notification.payload);

    debugPrint('📱 Foreground message: ${notification.type.value}');

    if (CallStateManager.isCurrentCall(notification.callId)) {
      _handleCurrentCallNotification(notification);
      return;
    }

    if (notification.type == NotificationType.incomingCall) {
      // Route through the navigator so the pending/app-ready gate applies.
      NotificationNavigator.navigateFromNotification(notification.payload);
      return;
    }

    // Display foreground heads-up notification banner so user receives alert
    await NotificationDisplayer.show(notification);
    debugPrint('🔔 Foreground notification displayed: ${notification.title}');
  }

  void _handleCurrentCallNotification(NotificationData notification) {
    debugPrint('📞 Current call notification: ${notification.type.value}');

    switch (notification.type) {
      case NotificationType.callDeclined:
      case NotificationType.callEnded:
        if (notification.callId != null) {
          NotificationDisplayer.cancelByCallId(notification.callId!);
        }
        NotificationNavigator._closeCallScreens();
        break;
      case NotificationType.callMissed:
        _showCallTerminationNotification(notification);
        if (notification.callId != null) {
          NotificationDisplayer.cancelByCallId(notification.callId!);
        }
        break;
      case NotificationType.callAccepted:
        if (notification.callId != null) {
          NotificationDisplayer.cancelByCallId(notification.callId!);
        }
        break;
      default:
        break;
    }
  }

  void _showCallTerminationNotification(NotificationData notification) {
    NotificationDisplayer.show(notification);
    NotificationNavigator._closeCallScreens();
  }

  static void handleMessageOpenedApp(RemoteMessage message) {
    debugPrint('👆 App opened via notification (warm)');
    NotificationNavigator.navigateFromNotification(message.data);
  }
  // ─────────────────────────────────────────────────────────────
  // PUBLIC API
  // ─────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>?> getInitialNotificationData() async {
    final data = _initialNotificationData;
    _initialNotificationData = null;
    return data;
  }

  Future<void> cancelAllNotifications() => NotificationDisplayer.cancelAll();

  Future<void> cancelCallNotification(String callId) =>
      NotificationDisplayer.cancelByCallId(callId);

  void dispose() {
    _onMessageSub?.cancel();
    _onOpenedSub?.cancel();
    _notificationStream.close();
  }

  static Future<void> showNotification({
    required String title,
    required String body,
    required Map<String, dynamic> data,
  }) {
    final notification = NotificationData(
      title: title,
      body: body,
      payload: data,
      type: NotificationType.fromString(data['type']),
    );
    return NotificationDisplayer.show(notification);
  }

  static Future<void> handleCallTermination(Map<String, dynamic> data) async {
    final notificationType = NotificationType.fromString(data['type']);
    final callId = data['callId'];

    if (notificationType == NotificationType.callAccepted ||
        notificationType == NotificationType.callEnded ||
        notificationType == NotificationType.callDeclined) {
      debugPrint('📞 Call $notificationType — cancelling incoming-call notification and suppressing alert');
      if (callId != null) {
        await NotificationDisplayer.cancelByCallId(callId);
      }
      return;
    }

    final notification = NotificationData(
      title: data['title'] ?? 'Call Update',
      body: data['body'] ?? '',
      payload: data,
      type: notificationType,
    );

    // 🙈 Suppress terminal call notifications the user caused themselves.
    if (_terminalTypes.contains(notification.type) &&
        await NotificationDisplayer.isFromSelf(notification)) {
      debugPrint('🙈 Suppressing self-triggered socket termination '
          'for call $callId');
      return;
    }

    await NotificationDisplayer.show(notification);
  }
}