// services/face_service.dart
import '../../services/network_service.dart';

class FaceVerifyResult {
  final bool success;
  final String message;
  final double? similarity;

  const FaceVerifyResult({
    required this.success,
    required this.message,
    this.similarity,
  });

  factory FaceVerifyResult.fromJson(Map<String, dynamic> json) {
    return FaceVerifyResult(
      success: json['success'] == true,
      message: (json['message'] ?? '').toString(),
      similarity: (json['similarity'] as num?)?.toDouble(),
    );
  }
}

class FaceStatusResult {
  final bool success;
  final bool registered;
  final bool hasRecord;
  final bool isActive;
  final String status; // 'active', 'inactive', 'not_enrolled'
  final bool canEnroll;
  final String? model;
  final DateTime? enrolledAt;
  final String? enrolledFrom;
  final bool livenessPassed;

  const FaceStatusResult({
    required this.success,
    required this.registered,
    required this.hasRecord,
    required this.isActive,
    required this.status,
    required this.canEnroll,
    this.model,
    this.enrolledAt,
    this.enrolledFrom,
    this.livenessPassed = false,
  });

  factory FaceStatusResult.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map ? Map<String, dynamic>.from(json['data'] as Map) : null;
    DateTime? parsedDate;
    if (data?['enrolledAt'] != null) {
      parsedDate = DateTime.tryParse(data!['enrolledAt'].toString());
    }

    final isReg = json['registered'] == true;
    final isAct = json['isActive'] == true || isReg;
    final hasRec = json['hasRecord'] == true || isReg;
    final stat = json['status']?.toString() ?? (isReg ? 'active' : 'not_enrolled');
    final canEnr = json['canEnroll'] == true || !isAct;

    return FaceStatusResult(
      success: json['success'] == true,
      registered: isReg,
      hasRecord: hasRec,
      isActive: isAct,
      status: stat,
      canEnroll: canEnr,
      model: data?['model']?.toString(),
      enrolledAt: parsedDate,
      enrolledFrom: data?['enrolledFrom']?.toString(),
      livenessPassed: data?['livenessPassed'] == true,
    );
  }
}

class FaceService {
  final NetworkService _network;

  FaceService({NetworkService? network})
      : _network = network ?? NetworkService();

  Future<Map<String, dynamic>> registerFace({
    required List<double> embedding,
    required bool livenessPassed,
    String model = 'mobilefacenet',
  }) async {
    return await _network.post('/face/register', {
      'embedding': embedding,
      'livenessPassed': livenessPassed,
      'model': model,
    });
  }

  Future<Map<String, dynamic>> getFaceStatus() async {
    return await _network.get('/face/status');
  }

  Future<FaceStatusResult> getStatusDetailed() async {
    final res = await _network.get('/face/status');
    return FaceStatusResult.fromJson(Map<String, dynamic>.from(res));
  }

  Future<FaceVerifyResult> verifyFace({
    required List<double> embedding,
    required String action,
  }) async {
    final res = await _network.post('/face/verify', {
      'embedding': embedding,
      'action': action,
    });
    return FaceVerifyResult.fromJson(Map<String, dynamic>.from(res));
  }

  Future<Map<String, dynamic>> deleteOwnFace() async {
    return await _network.delete('/face/enrollments');
  }
}
