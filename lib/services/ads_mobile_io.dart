import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ads_service.dart';
import 'tracking_consent_service.dart';

/// Android/iOS Mobile Ads SDK init. Not referenced by the web build.
Future<void> initializeMobileAds() async {
  try {
    await MobileAds.instance.initialize();
  } catch (e) {
    if (kDebugMode) debugPrint('[ads] initialize failed: $e');
  }
}

/// UMP consent. Failures never block startup.
Future<void> runMobileAdConsent() async {
  try {
    final params = ConsentRequestParameters();
    final completer = Completer<void>();
    ConsentInformation.instance.requestConsentInfoUpdate(
      params,
      () async {
        try {
          final available =
              await ConsentInformation.instance.isConsentFormAvailable();
          if (available) {
            final formCompleter = Completer<void>();
            ConsentForm.loadAndShowConsentFormIfRequired((FormError? error) {
              if (error != null && kDebugMode) {
                debugPrint('[ads] consent form show failed: ${error.message}');
              }
              if (!formCompleter.isCompleted) formCompleter.complete();
            });
            await formCompleter.future;
          }
        } catch (e) {
          if (kDebugMode) debugPrint('[ads] consent form error: $e');
        }
        if (!completer.isCompleted) completer.complete();
      },
      (FormError error) {
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

AdRequest mobileAdRequest() => TrackingConsentService.trackingAuthorized
    ? const AdRequest()
    : const AdRequest(nonPersonalizedAds: true);

/// Anchored adaptive banner. Only compiled into Android/iOS builds.
class MobileBannerAd extends StatefulWidget {
  const MobileBannerAd({super.key});

  @override
  State<MobileBannerAd> createState() => _MobileBannerAdState();
}

class _MobileBannerAdState extends State<MobileBannerAd> {
  BannerAd? _ad;
  bool _loaded = false;
  bool _requested = false;
  static const double _placeholderHeight = 56;

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  Future<void> _loadAd() async {
    if (_requested || !AdsService.bannerAllowed) return;
    _requested = true;
    final width = MediaQuery.of(context).size.width.truncate();
    final size =
        await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(width);
    if (!mounted) return;
    final ad = BannerAd(
      size: size ?? AdSize.banner,
      adUnitId: AdsService.bannerUnitId,
      request: mobileAdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (!mounted) return;
          setState(() => _loaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          if (!mounted) return;
          setState(() {
            _ad = null;
            _loaded = false;
          });
        },
      ),
    );
    _ad = ad;
    await ad.load();
  }

  @override
  Widget build(BuildContext context) {
    if (!_requested) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadAd());
    }
    final colors = Theme.of(context).colorScheme;
    final ad = _ad;
    if (_loaded && ad != null) {
      return Container(
        color: colors.surface,
        alignment: Alignment.center,
        width: ad.size.width.toDouble(),
        height: ad.size.height.toDouble(),
        child: AdWidget(ad: ad),
      );
    }
    return SizedBox(
      height: _placeholderHeight,
      child: Center(
        child: Text(
          'Ad',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: colors.onSurfaceVariant.withValues(alpha: 0.35),
              ),
        ),
      ),
    );
  }
}
