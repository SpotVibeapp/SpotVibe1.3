import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

/// Thin wrapper around [Geolocator] that handles permission requests and
/// returns a nullable (lat, lng) record.  All calls are no-ops on web.
class LocationService {
  /// Requests permission if needed, then returns the device's current
  /// coordinates.  Returns `null` on web, when permission is denied, or when
  /// location services are disabled.
  Future<({double lat, double lng})?> getCurrentLocation() async {
    if (kIsWeb) return null;

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }
    if (permission == LocationPermission.deniedForever) return null;

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 10),
        ),
      );
      return (lat: position.latitude, lng: position.longitude);
    } catch (_) {
      return null;
    }
  }
}
