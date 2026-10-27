import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'admob_ids.dart';
import 'tracking_consent_service.dart';

/// Central place for AdMob configuration and one-time SDK initialization.
///
/// Ad unit ids come from `--dart-define` so the real ids are supplied at build
/// time and never committed. When no id is provided the code falls back to
/// Google's OFFICIAL TEST ids, which always fill with a test ad and can never
/// cause a policy strike — so debug/dev builds are safe.
class AdsService {
  AdsService._();

  /// Google's official test banner unit (Android). Safe to ship in dev builds.
  static const String _testBannerAndroid =
      'ca-app-pub-3940256099942544/6300978111';

  /// Google's official test banner unit (iOS).
  static const String _testBanneriOS =
      'ca-app-pub-3940256099942544/2934735716';

  /// Real Android banner unit id, injected at build time:
  ///   --dart-define=ADMOB_BANNER_ANDROID=ca-app-pub-XXXXXXXX/ZZZZZZZZ
  static const String _bannerAndroid = String.fromEnvironment(
    'ADMOB_BANNER_ANDROID',
    defaultValue: _testBannerAndroid,
  );

  /// Real iOS banner unit id, injected at build time:
  ///   --dart-define=ADMOB_BANNER_IOS=ca-app-pub-XXXXXXXX/ZZZZZZZZ
  static const String _banneriOS = String.fromEnvironment(
    'ADMOB_BANNER_IOS',
    defaultValue: _testBanneriOS,
  );

  /// True when no real ad unit id was supplied and we are using test ads.
  static bool get usingTestAds =>
      _bannerAndroid == _testBannerAndroid && _banneriOS == _testBanneriOS;

  /// The banner ad unit id for the current platform.
  static String get bannerUnitId {
    if (defaultTargetPlatform == TargetPlatform.iOS) return _banneriOS;
    return _bannerAndroid;
  }

  /// Whether a banner may be requested with [bannerUnitId].
  ///
  /// Debug/profile builds always may (they use Google's test ids). A release
  /// build never requests an ad with a test or placeholder id. This is only a
  /// last line of defence: the Android release build already fails in Gradle
  /// (`verifyReleaseAdMobIds`) and the iOS one in Xcode when such ids remain.
  static bool get bannerAllowed =>
      bannerAllowedFor(bannerUnitId, releaseMode: kReleaseMode);

  @visibleForTesting
  static bool bannerAllowedFor(String unitId, {required bool releaseMode}) =>
      !releaseMode ||
      admobReleaseIdProblem(unitId, AdMobIdKind.adUnit) == null;

  /// The ad request to use for every ad. On iOS, when the user has not
  /// authorized tracking (ATT), ads are requested as non-personalized (npa=1).
  /// On Android this is identical to the previous `const AdRequest()`.
  static AdRequest get adRequest => TrackingConsentService.trackingAuthorized
      ? const AdRequest()
      : const AdRequest(nonPersonalizedAds: true);

  static bool _initialized = false;

  /// Ads are only supported on Android/iOS. Web and desktop skip entirely.
  static bool get isSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  /// Initialize the Mobile Ads SDK once. Safe to call unconditionally; it
  /// no-ops on unsupported platforms and after the first successful call.
  static Future<void> initialize() async {
    if (_initialized || !isSupported) return;
    _initialized = true;
    try {
      await MobileAds.instance.initialize();
    } catch (e) {
      // Never let ad init crash startup.
      if (kDebugMode) debugPrint('[ads] initialize failed: $e');
    }
  }
}
