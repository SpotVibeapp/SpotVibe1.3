import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
      final coords = (lat: position.latitude, lng: position.longitude);
      await saveLastLocation(coords.lat, coords.lng);
      return coords;
    } catch (_) {
      if (lastKnownPosition == null) return null;
      final coords = (
        lat: lastKnownPosition.latitude,
        lng: lastKnownPosition.longitude,
      );
      await saveLastLocation(coords.lat, coords.lng);
      return coords;
    }
  }

  // ── Last-known-location persistence ───────────────────────────────────────
  // The feed auto-locates on open (see EventsScreen initState), but until a
  // fresh fix arrives the app would briefly show the default market. These
  // helpers let EventProvider restore the previous session's location
  // instantly, and keep it when GPS is temporarily unavailable.

  static const _kLastLatKey = 'spotvibe_last_lat';
  static const _kLastLngKey = 'spotvibe_last_lng';
  static const _kLastAtKey = 'spotvibe_last_location_at';

  /// Saved locations older than this are ignored (the user may have
  /// travelled; a fresh GPS fix overwrites them whenever available).
  static const _kLastLocationMaxAge = Duration(days: 7);

  static Future<void> saveLastLocation(double lat, double lng) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_kLastLatKey, lat);
    await prefs.setDouble(_kLastLngKey, lng);
    await prefs.setInt(
        _kLastAtKey, DateTime.now().millisecondsSinceEpoch);
  }

  /// Returns the saved last-known location, or `null` when none exists or it
  /// is older than [_kLastLocationMaxAge].
  static Future<({double lat, double lng})?> loadLastLocation() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey(_kLastLatKey) || !prefs.containsKey(_kLastLngKey)) {
      return null;
    }
    final savedAt = prefs.getInt(_kLastAtKey) ?? 0;
    final age = DateTime.now().millisecondsSinceEpoch - savedAt;
    if (age > _kLastLocationMaxAge.inMilliseconds) return null;
    return (
      lat: prefs.getDouble(_kLastLatKey)!,
      lng: prefs.getDouble(_kLastLngKey)!,
    );
  }

  static Future<void> clearLastLocation() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kLastLatKey);
    await prefs.remove(_kLastLngKey);
    await prefs.remove(_kLastAtKey);
  }
}
