// models/activity.dart
class Activity {
  final int activityId;
  final String ownerType;
  final String ownerId;
  final String ownerValue;
  final String action;
  final int trackableId;
  final String trackableType;
  final String trackableValue;
  final String message;

  Activity({
    required this.activityId,
    required this.ownerType,
    required this.ownerId,
    required this.ownerValue,
    required this.action,
    required this.trackableId,
    required this.trackableType,
    required this.trackableValue,
    required this.message,
  });

  factory Activity.fromJson(Map<String, dynamic> json) {
    return Activity(
      activityId: json['activity_id'] as int,
      ownerType: json['owner_type'] as String,
      ownerId: json['owner_id'] as String,
      ownerValue: json['owner_value'] as String,
      action: json['action'] as String,
      trackableId: json['trackable_id'] as int,
      trackableType: json['trackable_type'] as String,
      trackableValue: json['trackable_value'] as String,
      message: json['message'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'activity_id': activityId,
      'owner_type': ownerType,
      'owner_id': ownerId,
      'owner_value': ownerValue,
      'action': action,
      'trackable_id': trackableId,
      'trackable_type': trackableType,
      'trackable_value': trackableValue,
      'message': message,
    };
  }
}