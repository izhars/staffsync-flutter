// models/device_session.dart
class DeviceSession {
  final String sessionId;
  final String deviceId;
  final String? deviceLabel;
  final String platform;
  final String? userAgent;
  final String? ip;
  final DateTime createdAt;
  final DateTime lastActiveAt;
  final DateTime expiresAt;
  final bool isCurrent;

  DeviceSession({
    required this.sessionId,
    required this.deviceId,
    this.deviceLabel,
    required this.platform,
    this.userAgent,
    this.ip,
    required this.createdAt,
    required this.lastActiveAt,
    required this.expiresAt,
    required this.isCurrent,
  });


  factory DeviceSession.fromJson(Map<String, dynamic> json, String? currentSessionId) {
    return DeviceSession(
      sessionId: json['sessionId']?.toString() ?? '',
      deviceId: json['deviceId']?.toString() ?? '',
      deviceLabel: json['deviceLabel']?.toString(),
      platform: json['platform']?.toString() ?? 'unknown',
      userAgent: json['userAgent']?.toString(),
      ip: json['ip']?.toString(),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
      lastActiveAt: DateTime.tryParse(json['lastActiveAt']?.toString() ?? '') ?? DateTime.now(),
      expiresAt: DateTime.tryParse(json['expiresAt']?.toString() ?? '') ?? DateTime.now(),
      isCurrent: currentSessionId != null && json['sessionId'] == currentSessionId,
    );
  }

  /// Never empty — falls back to deviceId, then platform.
  String get displayName {
    final label = deviceLabel?.trim();
    if (label != null && label.isNotEmpty) return label;
    return deviceId.isNotEmpty ? deviceId : _platformTitle;
  }

  String get _platformTitle {
    switch (platform) {
      case 'android': return 'Android device';
      case 'ios': return 'iPhone';
      case 'web': return 'Web browser';
      default: return 'Unknown device';
    }
  }

  String get platformLabel => _platformTitle;

  /// Short IP for display (e.g. "192.168.1.210").
  String? get shortIp {
    if (ip == null || ip!.isEmpty) return null;
    // Strip ::ffff: prefix and anything after the port.
    var cleaned = ip!.replaceFirst('::ffff:', '');
    final colon = cleaned.lastIndexOf(':');
    if (colon > 0 && !cleaned.contains('.')) {
      cleaned = cleaned.substring(0, colon);
    }
    return cleaned;
  }
}
