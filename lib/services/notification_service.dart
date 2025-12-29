import 'dart:convert';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../main.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
  FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    const iosSettings = DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (response.payload != null) {
          final data = jsonDecode(response.payload!);
          _handleNotificationTap(data);
        }
      },
    );

    await _createNotificationChannel();
  }

  /// ANDROID CHANNEL (no UI stuff here)
  static Future<void> _createNotificationChannel() async {
    const androidChannel = AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      description: 'Important app notifications like leave approvals',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);
  }

  /// SHOW LOCAL NOTIFICATION
  static Future<void> show({
    required String title,
    required String body,
    String? imageUrl,
    Map<String, dynamic>? data,
  }) async {
    // ---------------- ANDROID IMAGE ----------------
    BigPictureStyleInformation? bigPictureStyle;

    if (imageUrl != null && imageUrl.isNotEmpty) {
      final base64Image = await _downloadAndConvertImage(imageUrl);

      if (base64Image.isNotEmpty) {
        bigPictureStyle = BigPictureStyleInformation(
          ByteArrayAndroidBitmap.fromBase64String(base64Image),
          largeIcon:
          ByteArrayAndroidBitmap.fromBase64String(base64Image),
        );
      }
    }

    final androidDetails = AndroidNotificationDetails(
      'high_importance_channel',
      'High Importance Notifications',
      channelDescription: 'Important notifications',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      showWhen: true,
      styleInformation: bigPictureStyle,
    );

    // ---------------- iOS IMAGE ----------------
    String? iosImagePath;
    if (imageUrl != null && imageUrl.isNotEmpty) {
      iosImagePath = await _downloadAndSaveImage(imageUrl);
    }

    final iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      attachments: iosImagePath != null
          ? [DarwinNotificationAttachment(iosImagePath)]
          : null,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      notificationDetails,
      payload: data != null ? jsonEncode(data) : null,
    );
  }

  /// ANDROID helper: download image → base64
  static Future<String> _downloadAndConvertImage(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        return base64Encode(response.bodyBytes);
      }
    } catch (e) {
      debugPrint('❌ Android image download failed: $e');
    }
    return '';
  }

  /// iOS helper: download image → local file path
  static Future<String?> _downloadAndSaveImage(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final dir = await getTemporaryDirectory();
        final filePath =
            '${dir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';

        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);
        return filePath;
      }
    } catch (e) {
      debugPrint('❌ iOS image download failed: $e');
    }
    return null;
  }

  /// NOTIFICATION TAP HANDLER
  static void _handleNotificationTap(Map<String, dynamic> data) {
    debugPrint('🔔 Notification tapped: $data');
    _handleNotificationNavigation(data);
  }
}

/// GLOBAL NAVIGATION HANDLER
void _handleNotificationNavigation(Map<String, dynamic> data) {
  switch (data['type']) {
    case 'leave':
      if (data['action'] == 'approved' || data['action'] == 'rejected') {
        navigatorKey.currentState?.pushNamed(
          '/leave-detail',
          arguments: data['leaveId'],
        );
      } else if (data['action'] == 'requested') {
        navigatorKey.currentState?.pushNamed('/leave-requests');
      }
      break;

    case 'attendance':
      navigatorKey.currentState?.pushNamed('/attendance');
      break;

    case 'test_notification':
      final firedAt = data['firedAt'] ?? '';
      debugPrint('📌 Test notification tapped! firedAt NS: $firedAt'); // 🔹 log
      navigatorKey.currentState?.pushNamed(
        '/test',
        arguments: firedAt, // pass timestamp to TestScreen
      );
      break;
  }
}

