import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';

import '../../providers/subscription_provider.dart';
import '../../services/ads_service.dart';

/// An anchored adaptive banner ad for free users.
///
/// * Premium users (the `pro` entitlement) never see it and never trigger an ad
///   request — it collapses to zero height, so ad-free is a real benefit.
/// * On web/desktop (no ad support) it renders nothing.
/// * While the ad loads it reserves a fixed-height slot so the surrounding
///   layout doesn't jump when the banner appears.
class AdBanner extends StatefulWidget {
  const AdBanner({super.key});

  @override
  State<AdBanner> createState() => _AdBannerState();
}

class _AdBannerState extends State<AdBanner> {
  BannerAd? _ad;
  bool _loaded = false;
  bool _requested = false;

  /// Reserve roughly a standard banner's height while loading so nothing jumps.
  static const double _placeholderHeight = 56;

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  Future<void> _loadAd() async {
    if (_requested || !AdsService.isSupported) return;
    _requested = true;

    // Adaptive banner sized to the current screen width for best fill/UX.
    final width = MediaQuery.of(context).size.width.truncate();
    final size = await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(
      width,
    );
    if (!mounted) return;

    final ad = BannerAd(
      size: size ?? AdSize.banner,
      adUnitId: AdsService.bannerUnitId,
      request: const AdRequest(),
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
    // The single source of truth for Premium is the SubscriptionProvider.
    final isSubscribed =
        context.watch<SubscriptionProvider>().isSubscribed;

    // Premium or unsupported platform → no ad, no reserved space.
    if (isSubscribed || !AdsService.isSupported) {
      return const SizedBox.shrink();
    }

    // Kick off the first load lazily once we have a BuildContext with size.
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

    // Loading / not-yet-filled placeholder keeps layout stable.
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
