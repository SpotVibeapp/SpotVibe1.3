import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ads_service.dart';

/// Handles the Google User Messaging Platform (UMP) consent flow required for
/// serving ads in a privacy-compliant way (EU GDPR + US state privacy laws).
///
/// Call [ensureConsent] once at startup, before the first ad is requested.
/// It requests the latest consent info, shows the consent form if one is
/// required and available, and quietly proceeds otherwise. Failures never
/// block the app — worst case, non-personalized ads are served.
class AdConsentService {
  AdConsentService._();

  static bool _done = false;

  static Future<void> ensureConsent() async {
    if (_done || !AdsService.isSupported) return;
    _done = true;

    try {
      final params = ConsentRequestParameters();
      final completer = Completer<void>();

      ConsentInformation.instance.requestConsentInfoUpdate(
        params,
        () async {
          // Info updated — load & show a form if the user needs to act.
          try {
            final available =
                await ConsentInformation.instance.isConsentFormAvailable();
            if (available) {
              await _loadAndShowFormIfRequired();
            }
          } catch (e) {
            if (kDebugMode) debugPrint('[ads] consent form error: $e');
          }
          if (!completer.isCompleted) completer.complete();
        },
        (FormError error) {
          // Update failed — proceed; the SDK will serve non-personalized ads.
          if (kDebugMode) {
            debugPrint('[ads] consent update failed: ${error.message}');
          }
          if (!completer.isCompleted) completer.complete();
        },
      );

      await completer.future;
    } catch (e) {
      if (kDebugMode) debugPrint('[ads] ensureConsent failed: $e');
    }
  }

  static Future<void> _loadAndShowFormIfRequired() async {
    final completer = Completer<void>();
    ConsentForm.loadAndShowConsentFormIfRequired((FormError? error) {
      if (error != null && kDebugMode) {
        debugPrint('[ads] consent form show failed: ${error.message}');
      }
      if (!completer.isCompleted) completer.complete();
    });
    await completer.future;
  }
}
