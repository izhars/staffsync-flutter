import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationManager {
  static final NotificationManager _instance = NotificationManager._internal();
  factory NotificationManager() => _instance;
  NotificationManager._internal();
  static const String _callChannelId = 'staffsync_calls';
  static const String _callStatusChannelId = 'staffsync_call_status';

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  final Map<String, DateTime> _notificationTimestamps = {};

  Future<void> initialize() async {
    try {
      // Initialize Android channels
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

      // iOS settings
      final iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
        onDidReceiveLocalNotification: (id, title, body, payload) {
          // _handleNotificationTap(payload);
        },
      );

      final settings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _notifications.initialize(
        settings,
        onDidReceiveNotificationResponse: (response) {
          //_handleNotificationTap(response.payload);
        },
      );

      // Create notification channels
      await _createNotificationChannels();

      debugPrint('✅ NotificationManager initialized');
    } catch (e) {
      debugPrint('❌ NotificationManager initialization error: $e');
    }
  }

  Future<void> _createNotificationChannels() async {
    final android = AndroidFlutterLocalNotificationsPlugin();

    // Call channel (for incoming calls)
    await android?.createNotificationChannel(
      const AndroidNotificationChannel(
        _callChannelId,
        'StaffSync Calls',
        description: 'Incoming & ongoing call notifications',
        importance: Importance.max,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('ringtone'),
        enableVibration: true,
        enableLights: true,
        ledColor: Colors.blue,
      ),
    );

    // Call status channel (for ended/declined calls)
    await android?.createNotificationChannel(
      const AndroidNotificationChannel(
        _callStatusChannelId,
        'Call Status',
        description: 'Call ended/declined notifications',
        importance: Importance.high,
        playSound: false,
        enableVibration: true,
      ),
    );
  }

  // ==================== CALL NOTIFICATION METHODS ====================

  Future<void> showIncomingCallNotification({
    required String callId,
    required String callerName,
    required String roomId,
    required String callerId,
    required String callType,
  }) async {
    try {
      // Cancel any existing call notifications
      await cancelCallNotification(callId);

      // Create actions
      final List<AndroidNotificationAction> actions = [
        AndroidNotificationAction(
          'accept_$callId',
          'Accept',
          titleColor: Colors.green,
          showsUserInterface: true,
          cancelNotification: true,
        ),
        AndroidNotificationAction(
          'decline_$callId',
          'Decline',
          titleColor: Colors.red,
          showsUserInterface: true,
          cancelNotification: true,
        ),
      ];

      // Android details
      final androidDetails = AndroidNotificationDetails(
        _callChannelId,
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
        sound: const RawResourceAndroidNotificationSound('ringtone'),
        enableVibration: true,
        enableLights: true,
        ledColor: Colors.blue,
        ledOnMs: 1000,
        ledOffMs: 500,
        icon: '@mipmap/ic_launcher',
        actions: actions,
      );

      // iOS details
      final iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'ringtone.aiff',
        categoryIdentifier: 'INCOMING_CALL',
        interruptionLevel: InterruptionLevel.timeSensitive,
        threadIdentifier: 'call-$callId',
      );

      // Show notification
      await _notifications.show(
        _generateNotificationId(callId),
        '📞 Incoming ${callType == 'video' ? 'Video' : 'Audio'} Call',
        '$callerName is calling you',
        NotificationDetails(android: androidDetails, iOS: iosDetails),
        payload: jsonEncode({
          'type': 'incoming_call',
          'callId': callId,
          'roomId': roomId,
          'callerId': callerId,
          'callerName': callerName,
          'callType': callType,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );

      _notificationTimestamps[callId] = DateTime.now();
      debugPrint('📞 Incoming call notification shown: $callId');
    } catch (e) {
      debugPrint('❌ Error showing incoming call notification: $e');
    }
  }

  Future<void> showCallStatusNotification({
    required String callId,
    required String title,
    required String body,
    required String statusType, // 'ended', 'declined', 'missed'
    Map<String, dynamic>? extraData,
  }) async {
    try {
      // Cancel the incoming call notification first
      await cancelCallNotification(callId);

      // Do not show in-app / status notifications when call is ended or declined
      if (statusType == 'ended' || statusType == 'declined') {
        return;
      }

      // Android details for status notification
      final androidDetails = AndroidNotificationDetails(
        _callStatusChannelId,
        'Call Status',
        channelDescription: 'Call ended/declined notifications',
        importance: Importance.high,
        priority: Priority.high,
        autoCancel: true,
        playSound: false,
        enableVibration: true,
        vibrationPattern: Int64List.fromList(<int>[0, 200, 100, 200]),
        icon: '@mipmap/ic_launcher',
        color: _getStatusColor(statusType),
      );

      // iOS details
      final iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: false,
        presentSound: false,
        interruptionLevel: InterruptionLevel.active,
      );

      // Combine payload
      final payload = {
        'type': 'call_$statusType',
        'callId': callId,
        'timestamp': DateTime.now().toIso8601String(),
        ...?extraData,
      };

      // Show status notification
      await _notifications.show(
        _generateNotificationId('${callId}_$statusType'),
        title,
        body,
        NotificationDetails(android: androidDetails, iOS: iosDetails),
        payload: jsonEncode(payload),
      );

      debugPrint('📞 Call status notification shown: $statusType for $callId');
    } catch (e) {
      debugPrint('❌ Error showing call status notification: $e');
    }
  }

  Future<void> cancelCallNotification(String callId) async {
    try {
      // Cancel the main call notification
      await _notifications.cancel(_generateNotificationId(callId));

      // Cancel any status notifications for this call
      await _notifications.cancel(_generateNotificationId('${callId}_ended'));
      await _notifications.cancel(_generateNotificationId('${callId}_declined'));
      await _notifications.cancel(_generateNotificationId('${callId}_missed'));

      _notificationTimestamps.remove(callId);
      debugPrint('🗑️ Cancelled notifications for call: $callId');
    } catch (e) {
      debugPrint('❌ Error cancelling call notification: $e');
    }
  }

  Future<void> cancelAllNotifications() async {
    try {
      await _notifications.cancelAll();
      _notificationTimestamps.clear();
      debugPrint('🗑️ All notifications cancelled');
    } catch (e) {
      debugPrint('❌ Error cancelling all notifications: $e');
    }
  }

  // ==================== HELPER METHODS ====================

  int _generateNotificationId(String seed) {
    return seed.hashCode.abs() % 100000;
  }

  Color _getStatusColor(String statusType) {
    switch (statusType) {
      case 'ended':
        return Colors.blue;
      case 'declined':
        return Colors.orange;
      case 'missed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Future<void> clearOldNotifications() async {
    final cutoff = DateTime.now().subtract(Duration(hours: 24));
    final toRemove = <String>[];

    _notificationTimestamps.forEach((callId, timestamp) {
      if (timestamp.isBefore(cutoff)) {
        toRemove.add(callId);
      }
    });

    for (final callId in toRemove) {
      await cancelCallNotification(callId);
    }
  }
}