import 'ads_mobile.dart';
import 'ads_service.dart';

/// Handles the Google User Messaging Platform (UMP) consent flow required for
/// serving ads in a privacy-compliant way (EU GDPR + US state privacy laws).
///
/// Call [ensureConsent] once at startup, before the first ad is requested.
/// It requests the latest consent info, shows the consent form if one is
/// required and available, and quietly proceeds otherwise. Failures never
/// block the app — worst case, non-personalized ads are served. The web build
/// does not load the Mobile Ads SDK.
class AdConsentService {
  AdConsentService._();

  static bool _done = false;

  static Future<void> ensureConsent() async {
    if (_done || !AdsService.isSupported) return;
    _done = true;
    await runMobileAdConsent();
  }
}
