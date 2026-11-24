import 'package:latlong2/latlong.dart';
import 'package:permission_handler/permission_handler.dart';
import '../core/location_service.dart';
import '../core/geocoding_service.dart';

class LocationHelper {
  // ❌ Remove these two lines:
  // static final LocationService _locationService = LocationService();
  // The GeocodingService field can stay if that class has a real constructor.

  static final GeocodingService _geocodingService = GeocodingService();

  static Future<bool> hasLocationPermission() async {
    final status = await Permission.location.status;
    return status.isGranted;
  }

  static Future<PermissionStatus> requestLocationPermission() async {
    return await Permission.location.request();
  }

  static Future<bool> isLocationPermanentlyDenied() async {
    final status = await Permission.location.status;
    return status.isPermanentlyDenied;
  }

  static Future<bool> openSettings() async {
    return await openAppSettings();
  }

  static Future<LatLng?> getCurrentLocation() async {
    try {
      final hasPermission = await Permission.location.isGranted;
      if (!hasPermission) return null;

      // ✅ Call the static method directly
      return await LocationService.getCurrentLocation();
    } catch (e) {
      print('Error getting current location: $e');
      return null;
    }
  }

  static Future<LocationData?> getCurrentLocationWithAddress() async {
    try {
      final hasPermission = await Permission.location.isGranted;
      if (!hasPermission) return null;

      final location = await LocationService.getCurrentLocation(); // ✅ static
      if (location == null) return null;

      final geocodedLocation = await _geocodingService.reverseGeocode(
        location.latitude,
        location.longitude,
      );

      return LocationData(
        latitude: location.latitude,
        longitude: location.longitude,
        address: geocodedLocation.address ?? "Unknown location",
        latLng: location,
      );
    } catch (e) {
      print('Error getting location with address: $e');
      return null;
    }
  }

  /// Get address from coordinates
  static Future<String?> getAddressFromCoordinates(
      double latitude, double longitude) async {
    try {
      final location = await _geocodingService.reverseGeocode(
        latitude,
        longitude,
      );
      return location.address;
    } catch (e) {
      print('Error getting address from coordinates: $e');
      return null;
    }
  }

  /// Format coordinates as string
  static String formatCoordinates(double latitude, double longitude) {
    return "${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}";
  }

  /// Format coordinates as detailed string
  static String formatCoordinatesDetailed(double latitude, double longitude) {
    return "Lat: ${latitude.toStringAsFixed(6)}, Lng: ${longitude.toStringAsFixed(6)}";
  }
}

/// Location data model
class LocationData {
  final double latitude;
  final double longitude;
  final String address;
  final LatLng latLng;

  LocationData({
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.latLng,
  });

  /// Get formatted coordinates
  String get formattedCoordinates =>
      LocationHelper.formatCoordinates(latitude, longitude);

  /// Get detailed formatted coordinates
  String get formattedCoordinatesDetailed =>
      LocationHelper.formatCoordinatesDetailed(latitude, longitude);

  /// Convert to map for API calls
  Map<String, dynamic> toMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
    };
  }

  @override
  String toString() {
    return 'LocationData(lat: $latitude, lng: $longitude, address: $address)';
  }
}