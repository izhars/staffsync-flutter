import '../models/geo_fence_location.dart';
import 'network_service.dart';
import 'api_exception.dart';

class GeoFenceService {
  final NetworkService _network = NetworkService();

  // In-memory cache
  List<GeoFenceLocation> _cachedLocations = [];
  DateTime? _lastFetch;

  static const Duration _cacheTtl = Duration(minutes: 5);

  // ---------------------------------------------------------
  // 🔥 Fetch raw response
  // ---------------------------------------------------------
  Future<Map<String, dynamic>> fetchMyLocations() async {
    try {
      return await _network.get("/geo-fence/my-locations");
    } catch (e) {
      if (e is ApiException) throw e;
      rethrow;
    }
  }

  // ---------------------------------------------------------
  // 🔥 Fetch + parse to typed list (with cache)
  // ---------------------------------------------------------
  Future<List<GeoFenceLocation>> fetchLocations({bool forceRefresh = false}) async {
    if (!forceRefresh &&
        _cachedLocations.isNotEmpty &&
        _lastFetch != null &&
        DateTime.now().difference(_lastFetch!) < _cacheTtl) {
      return _cachedLocations;
    }

    final response = await fetchMyLocations();

    if (response['success'] == true && response['locations'] is List) {
      _cachedLocations = (response['locations'] as List)
          .map((j) => GeoFenceLocation.fromJson(j as Map<String, dynamic>))
          .toList();
      _lastFetch = DateTime.now();
      return _cachedLocations;
    }
    return _cachedLocations;
  }

  // ---------------------------------------------------------
  // 🔥 Check if point is inside ANY fence
  // ---------------------------------------------------------
  Future<GeoFenceValidationResult> validateLocation({
    required double latitude,
    required double longitude,
    bool forceRefresh = false,
  }) async {
    final locations = await fetchLocations(forceRefresh: forceRefresh);

    if (locations.isEmpty) {
      // No fence configured → allow (or block, depending on policy)
      return GeoFenceValidationResult(
        isInside: true,
        matchedLocation: null,
        nearestLocation: null,
        nearestDistance: null,
      );
    }

    for (final loc in locations) {
      if (loc.containsPoint(latitude, longitude)) {
        return GeoFenceValidationResult(
          isInside: true,
          matchedLocation: loc,
          nearestLocation: loc,
          nearestDistance: loc.distanceTo(latitude, longitude),
        );
      }
    }

    // Not inside any → find nearest for error dialog
    GeoFenceLocation? nearest;
    double minDist = double.infinity;
    for (final loc in locations) {
      final d = loc.distanceTo(latitude, longitude);
      if (d < minDist) {
        minDist = d;
        nearest = loc;
      }
    }

    return GeoFenceValidationResult(
      isInside: false,
      matchedLocation: null,
      nearestLocation: nearest,
      nearestDistance: minDist,
    );
  }

  void clearCache() {
    _cachedLocations = [];
    _lastFetch = null;
  }
}

// ---------------------------------------------------------
// 🔥 Validation Result Model
// ---------------------------------------------------------
class GeoFenceValidationResult {
  final bool isInside;
  final GeoFenceLocation? matchedLocation;
  final GeoFenceLocation? nearestLocation;
  final double? nearestDistance;

  GeoFenceValidationResult({
    required this.isInside,
    this.matchedLocation,
    this.nearestLocation,
    this.nearestDistance,
  });
}