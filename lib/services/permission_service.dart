import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'notification_backend.dart';

const _kPermissionsAskedKey = 'spotvibe_permissions_asked';
const _kPermissionsAskedKeyLegacy = 'vibely_permissions_asked';

/// Location and notification permission requests.
///
/// Phones use permission_handler and awesome_notifications. The browser uses
/// the Geolocation API (via geolocator) and the Notifications API. The
/// first-run onboarding prompt is skipped on the web so the feed can open
/// immediately; the browser asks only when the visitor turns location or
/// alerts on.
class PermissionService {
  PermissionService({NotificationBackend? notifications})
      : _notifications = notifications ?? createNotificationBackend();

  final NotificationBackend _notifications;

  /// Returns true if the permission prompt has already been shown to the user.
  /// The web app does not block the first screen on a native-style prompt.
  Future<bool> hasAskedBefore() async {
    if (kIsWeb) return true;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kPermissionsAskedKey) ??
        prefs.getBool(_kPermissionsAskedKeyLegacy) ??
        false;
  }

  /// Marks the permission prompt as having been shown so it is not shown again.
  Future<void> markAsked() async {
    if (kIsWeb) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kPermissionsAskedKey, true);
  }

  /// Requests location permission. Returns true if granted.
  Future<bool> requestLocation() async {
    if (kIsWeb) return _requestBrowserLocation();
    try {
      final status = await Permission.locationWhenInUse.request();
      return status.isGranted;
    } catch (_) {
      return false;
    }
  }

  /// Requests notification permission. Returns true if granted.
  Future<bool> requestNotifications() async {
    try {
      return await _notifications.requestPermission();
    } catch (_) {
      return false;
    }
  }

  /// Checks whether location permission is currently granted.
  Future<bool> isLocationGranted() async {
    if (kIsWeb) {
      try {
        final permission = await Geolocator.checkPermission();
        return permission == LocationPermission.whileInUse ||
            permission == LocationPermission.always;
      } catch (_) {
        return false;
      }
    }
    try {
      return await Permission.locationWhenInUse.isGranted;
    } catch (_) {
      return false;
    }
  }

  /// Checks whether notification permission is currently granted.
  Future<bool> isNotificationGranted() async {
    try {
      return await _notifications.isAllowed();
    } catch (_) {
      return false;
    }
  }

  /// Opens the operating system's page for this app when a permission was
  /// previously denied and Android no longer shows the native prompt.
  /// Browsers have no equivalent app-settings screen.
  Future<bool> openDeviceSettings() async {
    if (kIsWeb) return false;
    try {
      return await openAppSettings();
    } catch (_) {
      return false;
    }
  }

  Future<bool> _requestBrowserLocation() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      return permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always;
    } catch (_) {
      return false;
    }
  }
}
