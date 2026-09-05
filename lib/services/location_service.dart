import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

/// Thin wrapper around [Geolocator] that handles permission requests and
/// returns a nullable (lat, lng) record. All calls are no-ops on web.
class LocationService {
  /// Returns the device's current coordinates when possible.
  ///
  /// When [requestPermission] is false, this never presents an Android prompt.
  /// That makes it safe to refresh the nearby feed after a user has already
  /// granted location access during onboarding. When a fresh GPS fix takes too
  /// long, a previously known device location is used as a fallback so a
  /// temporary indoor/GPS delay does not look like a permission failure.
  Future<({double lat, double lng})?> getCurrentLocation({
    bool requestPermission = true,
  }) async {
    if (kIsWeb) return null;

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied && requestPermission) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return null;
    }

    Position? lastKnownPosition;
    try {
      lastKnownPosition = await Geolocator.getLastKnownPosition();
    } catch (_) {
      // A current GPS fix can still succeed when Android has no cached value.
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 20),
        ),
      );
      return (lat: position.latitude, lng: position.longitude);
    } catch (_) {
      if (lastKnownPosition == null) return null;
      return (
        lat: lastKnownPosition.latitude,
        lng: lastKnownPosition.longitude,
      );
    }
  }
}
