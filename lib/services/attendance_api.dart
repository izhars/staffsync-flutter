import '../services/network_service.dart';
import 'api_exception.dart';

class AttendanceService {
  final NetworkService _network = NetworkService();

  // ---------------------------------------------------------
  // 🔥 Check-In
  // ---------------------------------------------------------
  Future<Map<String, dynamic>> checkIn({
    double? latitude,
    double? longitude,
    required String address,
    required String deviceInfo,
    List<double>? faceEmbedding,
  }) async {
    try {
      return await _network.post(
        "/attendance/check-in",
        {
          "latitude": latitude,
          "longitude": longitude,
          "address": address,
          "deviceInfo": deviceInfo,
          if (faceEmbedding != null) "faceEmbedding": faceEmbedding,
        },
      );
    } catch (e) {
      if (e is ApiException) throw e;
      rethrow;
    }
  }

  Future<Map<String, dynamic>> checkOut({
    required double latitude,
    required double longitude,
    required String address,
    required String deviceInfo,
    List<double>? faceEmbedding,
  }) async {
    try {
      return await _network.post(
        "/attendance/check-out",
        {
          "latitude": latitude,
          "longitude": longitude,
          "address": address,
          "deviceInfo": deviceInfo,
          if (faceEmbedding != null) "faceEmbedding": faceEmbedding,
        },
      );
    } catch (e) {
      if (e is ApiException) throw e;
      rethrow;
    }
  }

  // ---------------------------------------------------------
  // 🔥 Fetch Today's Attendance
  // ---------------------------------------------------------
  Future<Map<String, dynamic>> fetchTodayAttendance() async {
    try {
      return await _network.get("/attendance/today");
    } catch (e) {
      if (e is ApiException) throw e;
      rethrow;
    }
  }

  // ---------------------------------------------------------
  // 🔥 Fetch My Attendance (month/year filter)
  // ---------------------------------------------------------
  Future<Map<String, dynamic>> fetchMyAttendance({
    int? month,
    int? year,
  }) async {
    try {
      String url = "/attendance/my-attendance";

      if (month != null && year != null) {
        url += "?month=$month&year=$year";
      }

      return await _network.get(url);
    } catch (e) {
      if (e is ApiException) throw e;
      rethrow;
    }
  }

  // ---------------------------------------------------------
  // 🔥 Monthly Work Hours Chart
  // ---------------------------------------------------------
  Future<Map<String, dynamic>> getMonthlyWorkHours({
    required int month,
    required int year,
  }) async {
    try {
      return await _network.get(
        "/attendance/work-hours-chart-monthly?month=$month&year=$year",
      );
    } catch (e) {
      if (e is ApiException) throw e;
      rethrow;
    }
  }

  // ---------------------------------------------------------
  // 🔥 Work Hours Calculation Helper
  // ---------------------------------------------------------
  double? getWorkHours(Map<String, dynamic> attendance) {
    if (attendance['workHours'] != null) {
      return attendance['workHours'].toDouble();
    }

    final checkInTime = attendance['checkIn']?['time'];
    final checkOutTime = attendance['checkOut']?['time'];

    if (checkInTime != null && checkOutTime != null) {
      try {
        final checkIn = DateTime.parse(checkInTime);
        final checkOut = DateTime.parse(checkOutTime);
        return checkOut.difference(checkIn).inMinutes / 60.0;
      } catch (_) {
        return null;
      }
    }

    return null;
  }

  // ---------------------------------------------------------
  // 🔥 Attendance Regularization
  // ---------------------------------------------------------
  Future<Map<String, dynamic>> requestRegularization({
    required String date,
    required String checkInTime,
    String? checkOutTime,
    required String reason,
  }) async {
    try {
      return await _network.post(
        "/attendance/regularization",
        {
          "date": date,
          "requestedCheckIn": checkInTime,
          if (checkOutTime != null && checkOutTime.isNotEmpty)
            "requestedCheckOut": checkOutTime,
          "reason": reason,
        },
      );
    } catch (e) {
      if (e is ApiException) throw e;
      rethrow;
    }
  }

  Future<Map<String, dynamic>> fetchMyRegularizations({
    String? status,
    int? month,
    int? year,
  }) async {
    try {
      String url = "/attendance/regularization/my";
      final params = <String>[];
      if (status != null) params.add("status=$status");
      if (month != null) params.add("month=$month");
      if (year != null) params.add("year=$year");
      if (params.isNotEmpty) url += "?${params.join('&')}";

      return await _network.get(url);
    } catch (e) {
      if (e is ApiException) throw e;
      rethrow;
    }
  }

  // ---------------------------------------------------------
  // 🔥 Format Work Hours
  // ---------------------------------------------------------
  String formatWorkHours(double? hours) {
    if (hours == null) return "N/A";

    final intHours = hours.floor();
    final minutes = ((hours - intHours) * 60).round();

    if (minutes == 0) return "${intHours}h";
    return "${intHours}h ${minutes}m";
  }
}
