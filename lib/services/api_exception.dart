class ApiException implements Exception {
  final int statusCode;
  final String message;
  final dynamic data; // 🔥 NEW: full response body for detailed errors

  ApiException({
    required this.statusCode,
    required this.message,
    this.data,
  });

  @override
  String toString() => message;

  bool get isUnauthorized => statusCode == 401;
  bool get isForbidden => statusCode == 403;
  bool get isNotFound => statusCode == 404;
  bool get isServerError => statusCode >= 500;
  bool get isNetworkError => statusCode == 0;

  // 🔥 NEW: Geo-fence helpers
  bool get isGeoFenceError =>
      statusCode == 403 && data != null && data['nearestLocation'] != null;

  Map<String, dynamic>? get nearestLocation =>
      isGeoFenceError ? data['nearestLocation'] as Map<String, dynamic>? : null;

  List<dynamic>? get allLocations =>
      isGeoFenceError ? data['allLocations'] as List<dynamic>? : null;

  Map<String, dynamic>? get yourLocation =>
      isGeoFenceError ? data['yourLocation'] as Map<String, dynamic>? : null;
}