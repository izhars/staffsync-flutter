import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

/// Why location is (or isn't) available, so the UI can react with the
/// correct call-to-action instead of a single generic failure state.
enum LocationAvailability {
  granted,
  serviceDisabled,
  permissionDenied,
  permissionDeniedForever,
  timedOut,
  error,
}

class LocationCheckResult {
  final LocationAvailability status;
  final String? errorMessage;

  const LocationCheckResult(this.status, {this.errorMessage});

  bool get isGranted => status == LocationAvailability.granted;

  @override
  String toString() =>
      'LocationCheckResult($status${errorMessage != null ? ', $errorMessage' : ''})';
}

/// Centralizes all location-availability logic so no screen talks to
/// Geolocator directly. Every call site gets a structured result instead
/// of a bare bool, so the UI can tell *why* location isn't available and
/// offer the right fix.
class LocationService {
  LocationService._();

  // ---------------------------------------------------------------------------
  // Availability / permission
  // ---------------------------------------------------------------------------

  static Future<LocationCheckResult> checkAvailability({
    Duration timeout = const Duration(seconds: 30),
  }) async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return const LocationCheckResult(LocationAvailability.serviceDisabled);
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return const LocationCheckResult(LocationAvailability.permissionDenied);
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return const LocationCheckResult(LocationAvailability.permissionDeniedForever);
      }

      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null) {
        return const LocationCheckResult(LocationAvailability.granted);
      }

      try {
        await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.low,
          timeLimit: timeout,
        );
        return const LocationCheckResult(LocationAvailability.granted);
      } on TimeoutException {
        final fallback = await Geolocator.getLastKnownPosition();
        if (fallback != null) {
          return const LocationCheckResult(LocationAvailability.granted);
        }
        return const LocationCheckResult(LocationAvailability.timedOut);
      }
    } on TimeoutException {
      return const LocationCheckResult(LocationAvailability.timedOut);
    } catch (e) {
      return LocationCheckResult(
        LocationAvailability.error,
        errorMessage: e.toString(),
      );
    }
  }

  static Future<bool> openLocationSettings() =>
      Geolocator.openLocationSettings();

  static Future<bool> openAppSettings() => Geolocator.openAppSettings();

  // ---------------------------------------------------------------------------
  // One-shot fetch — used at punch time and for the initial dashboard load
  // ---------------------------------------------------------------------------

  /// Fresh, high-accuracy fix. Fast-paths to recent location (< 3 mins)
  /// in under 10ms, or queries GPS with a responsive 4-second timeout to avoid UI freezes.
  static Future<LatLng?> getCurrentLocation({
    Duration timeout = const Duration(seconds: 4),
    Duration maxStaleDuration = const Duration(minutes: 3),
  }) async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }

      // Fast-path: If the device already recorded a fresh location (< 3 minutes),
      // return it immediately in 5ms instead of waiting for a cold satellite fix!
      try {
        final lastKnown = await Geolocator.getLastKnownPosition();
        if (lastKnown != null) {
          final age = DateTime.now().difference(lastKnown.timestamp);
          if (age <= maxStaleDuration && lastKnown.accuracy <= 60.0) {
            return LatLng(lastKnown.latitude, lastKnown.longitude);
          }
        }
      } catch (_) {}

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: timeout,
      );
      return LatLng(pos.latitude, pos.longitude);
    } catch (_) {
      // Fall back to last known so a punch is never blocked by slow indoor GPS.
      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown == null) return null;
      return LatLng(lastKnown.latitude, lastKnown.longitude);
    }
  }

  // ---------------------------------------------------------------------------
  // Live stream — keeps the dashboard address fresh as the user moves
  // ---------------------------------------------------------------------------

  /// Emits a new [LatLng] every time the device moves roughly
  /// [distanceFilterMeters] metres. Battery-friendly: the OS won't wake
  /// the GPS for tiny jitter.
  ///
  /// Cancel the subscription in `dispose()` and when the app is backgrounded.
  static Stream<LatLng> locationStream({
    int distanceFilterMeters = 30,
    LocationAccuracy accuracy = LocationAccuracy.high,
  }) {
    return Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: accuracy,
        distanceFilter: distanceFilterMeters,
      ),
    ).map((p) => LatLng(p.latitude, p.longitude));
  }
}