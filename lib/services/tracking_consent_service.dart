import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:flutter/foundation.dart';

/// App Tracking Transparency (ATT) for iOS 14.5+.
///
/// Apple requires the system ATT prompt before the app (or the AdMob SDK)
/// accesses the IDFA. We request it explicitly after the UMP consent flow
/// and before the Mobile Ads SDK is initialized, then report whether ads may
/// be personalized. On Android/web this is a no-op and personalization is
/// left to UMP, so Android behavior is unchanged.
class TrackingConsentService {
  TrackingConsentService._();

  static bool _trackingAuthorized = false;

  /// Whether the user allowed tracking (always true off iOS, where UMP alone
  /// governs personalization).
  static bool get trackingAuthorized => !_isIOS || _trackingAuthorized;

  static bool get _isIOS =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  /// Shows the ATT prompt if the status is still undetermined. Never throws.
  static Future<void> requestIfNeeded() async {
    if (!_isIOS) return;
    try {
      var status = await AppTrackingTransparency.trackingAuthorizationStatus;
      if (status == TrackingStatus.notDetermined) {
        // The prompt is ignored by iOS unless the app is active; give the
        // first frame / UMP form dismissal a moment to settle.
        await Future<void>.delayed(const Duration(milliseconds: 500));
        status = await AppTrackingTransparency.requestTrackingAuthorization();
      }
      _trackingAuthorized = status == TrackingStatus.authorized;
      if (kDebugMode) debugPrint('[ads] ATT status: $status');
    } catch (e) {
      _trackingAuthorized = false;
      if (kDebugMode) debugPrint('[ads] ATT request failed: $e');
    }
  }
}
