import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kPermissionsAskedKey = 'spotvibe_permissions_asked';
const _kPermissionsAskedKeyLegacy = 'vibely_permissions_asked';

/// Thin service that manages location and notification permission requests.
/// All methods are no-ops on web.
class PermissionService {
  /// Returns true if the permission prompt has already been shown to the user.
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

  /// Requests location (when in use) permission.
  /// Returns true if granted.
  Future<bool> requestLocation() async {
    if (kIsWeb) return false;
    final status = await Permission.locationWhenInUse.request();
    return status.isGranted;
  }

  /// Requests notification permission via awesome_notifications.
  /// Returns true if granted.
  Future<bool> requestNotifications() async {
    if (kIsWeb) return false;
    return await AwesomeNotifications()
        .requestPermissionToSendNotifications();
  }

  /// Checks whether location permission is currently granted.
  Future<bool> isLocationGranted() async {
    if (kIsWeb) return false;
    return await Permission.locationWhenInUse.isGranted;
  }

  /// Checks whether notification permission is currently granted.
  Future<bool> isNotificationGranted() async {
    if (kIsWeb) return false;
    return await AwesomeNotifications().isNotificationAllowed();
  }
}
