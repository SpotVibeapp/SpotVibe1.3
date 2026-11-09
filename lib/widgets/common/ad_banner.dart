import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/subscription_provider.dart';
import '../../services/ads_mobile.dart';
import '../../services/ads_service.dart';

/// An anchored adaptive banner ad for free users.
///
/// * Premium users (the `pro` entitlement) never see it and never trigger an ad
///   request — it collapses to zero height, so ad-free is a real benefit.
/// * On web/desktop (no ad support) it renders nothing.
/// * While the ad loads it reserves a fixed-height slot so the surrounding
///   layout doesn't jump when the banner appears.
/// * When [showRemoveAdsUpsell] is true, a small "Remove ads with Premium" row
///   sits under the banner and routes to the paywall — turning the ad slot into
///   a conversion surface for the ad-free benefit.
class AdBanner extends StatefulWidget {
  final bool showRemoveAdsUpsell;

  const AdBanner({super.key, this.showRemoveAdsUpsell = true});

  @override
  State<AdBanner> createState() => _AdBannerState();
}

class _AdBannerState extends State<AdBanner> {
  @override
  Widget build(BuildContext context) {
    // The single source of truth for Premium is the SubscriptionProvider.
    final isSubscribed =
        context.watch<SubscriptionProvider>().isSubscribed;

    // Premium or unsupported platform (web) → no ad, no reserved space.
    if (isSubscribed || !AdsService.isSupported) {
      return const SizedBox.shrink();
    }

    final colors = Theme.of(context).colorScheme;
    const banner = MobileBannerAd();
    if (!widget.showRemoveAdsUpsell) return banner;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        banner,
        _RemoveAdsUpsell(colors: colors),
      ],
    );
  }
}

/// A slim "Remove ads with Premium" row shown beneath a banner. Tapping it opens
/// the paywall, so the ad itself sells the ad-free upgrade.
class _RemoveAdsUpsell extends StatelessWidget {
  final ColorScheme colors;

  const _RemoveAdsUpsell({required this.colors});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return InkWell(
      onTap: () => context.push('/paywall'),
      child: Container(
        width: double.infinity,
        color: colors.surfaceContainerHighest.withValues(alpha: 0.5),
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.block_rounded, size: 14, color: colors.primary),
            const SizedBox(width: 6),
            // Flexible so large system text on a narrow screen ellipsizes
            // instead of overflowing.
            Flexible(
              child: Text(
                'Remove ads with Premium',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: text.labelSmall?.copyWith(
                  color: colors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Icon(Icons.chevron_right_rounded, size: 16, color: colors.primary),
          ],
        ),
      ),
    );
  }
}
