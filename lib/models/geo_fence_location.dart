import 'dart:math' as math;

class GeoFenceLocation {
  final String id;
  final String name;
  final String type;          // "office" | "highway" | ...
  final String shape;         // "circle" | "polyline"
  final String address;
  final double? latitude;
  final double? longitude;
  final double radiusMeters;
  final double corridorWidthMeters;
  final List<GeoPoint> polylinePoints;

  const GeoFenceLocation({
    required this.id,
    required this.name,
    required this.type,
    required this.shape,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.radiusMeters,
    required this.corridorWidthMeters,
    required this.polylinePoints,
  });

  bool get isCircle => shape == 'circle';
  bool get isPolyline => shape == 'polyline';

  factory GeoFenceLocation.fromJson(Map<String, dynamic> json) {
    return GeoFenceLocation(
      id: (json['_id'] ?? json['id'] ?? '') as String,
      name: (json['name'] as String?) ?? '',
      type: (json['type'] as String?) ?? 'office',
      shape: (json['shape'] as String?) ?? 'circle',
      address: (json['address'] as String?) ?? '',
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      radiusMeters: (json['radiusMeters'] as num?)?.toDouble() ?? 0,
      corridorWidthMeters:
      (json['corridorWidthMeters'] as num?)?.toDouble() ?? 0,
      polylinePoints: (json['polylinePoints'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(GeoPoint.fromJson)
          .toList(growable: false),
    );
  }

  /// Distance in meters from a point to the nearest part of this fence.
  double distanceTo(double lat, double lng) {
    if (isCircle && latitude != null && longitude != null) {
      final d = _haversineMeters(lat, lng, latitude!, longitude!);
      return math.max(0, d - radiusMeters);
    }
    if (isPolyline && polylinePoints.isNotEmpty) {
      double min = double.infinity;
      for (var i = 0; i < polylinePoints.length - 1; i++) {
        final p1 = polylinePoints[i];
        final p2 = polylinePoints[i + 1];
        final d = _distToSegmentMeters(
          lat, lng, p1.latitude, p1.longitude, p2.latitude, p2.longitude,
        );
        if (d < min) min = d;
      }
      return math.max(0, min - corridorWidthMeters / 2);
    }
    return double.infinity;
  }

  /// Whether a point falls inside this geofence.
  bool containsPoint(double lat, double lng) {
    if (isCircle && latitude != null && longitude != null) {
      final d = _haversineMeters(lat, lng, latitude!, longitude!);
      return d <= radiusMeters;
    }
    if (isPolyline && polylinePoints.length >= 2) {
      for (var i = 0; i < polylinePoints.length - 1; i++) {
        final p1 = polylinePoints[i];
        final p2 = polylinePoints[i + 1];
        final d = _distToSegmentMeters(
          lat, lng, p1.latitude, p1.longitude, p2.latitude, p2.longitude,
        );
        if (d <= corridorWidthMeters / 2) return true;
      }
    }
    return false;
  }
  /// Allowed radius for display purposes
  double get allowedRadius =>
      shape == 'circle'
          ? (radiusMeters ?? 0)
          : (corridorWidthMeters ?? 0) / 2;

  // ── geo helpers ──
  static double _haversineMeters(
      double lat1, double lon1, double lat2, double lon2,
      ) {
    const r = 6371000.0;
    final dLat = _rad(lat2 - lat1);
    final dLon = _rad(lon2 - lon1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_rad(lat1)) *
            math.cos(_rad(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return r * c;
  }

  static double _distToSegmentMeters(
      double px, double py, double ax, double ay, double bx, double by,
      ) {
    // Project on local equirectangular approximation (fine at small scales)
    final latRef = _rad((ay + by) / 2);
    const r = 6371000.0;
    final axM = _rad(bx - ax) * r * math.cos(latRef);
    // (unused in vector form below — keep for clarity)
    // ignore: unused_local_variable
    final _ = axM;
    final pX = _rad(py) * r * math.cos(latRef);
    final pY = _rad(px) * r;
    final aX = _rad(ay) * r * math.cos(latRef);
    final aY = _rad(ax) * r;
    final bX = _rad(by) * r * math.cos(latRef);
    final bY = _rad(bx) * r;

    final dx = bX - aX;
    final dy = bY - aY;
    final len2 = dx * dx + dy * dy;
    if (len2 == 0) {
      return math.sqrt(
        math.pow(pX - aX, 2).toDouble() + math.pow(pY - aY, 2).toDouble(),
      );
    }
    var t = ((pX - aX) * dx + (pY - aY) * dy) / len2;
    t = t.clamp(0.0, 1.0);
    final projX = aX + t * dx;
    final projY = aY + t * dy;
    return math.sqrt(
      math.pow(pX - projX, 2).toDouble() +
          math.pow(pY - projY, 2).toDouble(),
    );
  }

  static double _rad(double deg) => deg * math.pi / 180.0;
}

class GeoPoint {
  final double latitude;
  final double longitude;

  const GeoPoint({required this.latitude, required this.longitude});

  factory GeoPoint.fromJson(Map<String, dynamic> json) => GeoPoint(
    latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
    longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
  );
}