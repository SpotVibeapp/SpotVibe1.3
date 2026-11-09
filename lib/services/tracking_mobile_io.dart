import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:flutter/foundation.dart';

/// Shows the iOS App Tracking Transparency prompt. Returns whether the user
/// allowed tracking. Never throws.
Future<bool> requestIosTrackingAuthorization() async {
  try {
    var status = await AppTrackingTransparency.trackingAuthorizationStatus;
    if (status == TrackingStatus.notDetermined) {
      await Future<void>.delayed(const Duration(milliseconds: 500));
      status = await AppTrackingTransparency.requestTrackingAuthorization();
    }
    if (kDebugMode) debugPrint('[ads] ATT status: $status');
    return status == TrackingStatus.authorized;
  } catch (e) {
    if (kDebugMode) debugPrint('[ads] ATT request failed: $e');
    return false;
  }
}
