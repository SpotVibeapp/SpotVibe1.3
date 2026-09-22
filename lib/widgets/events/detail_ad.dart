import 'package:flutter/material.dart';

import '../../services/ads_service.dart';
import '../common/ad_banner.dart';
import 'event_page_ad.dart';

/// The single ad slot on an event detail page for free (non-Premium) listings.
///
/// * When AdMob is supported (Android/iOS), it shows the real revenue banner
///   with the "Remove ads with Premium" upsell beneath it. The banner itself
///   collapses to nothing for Premium users, so ad-free stays a real benefit.
/// * On web/desktop (no ad SDK), it falls back to the in-house promo card so
///   the space is never blank.
class DetailAd extends StatelessWidget {
  const DetailAd({super.key});

  @override
  Widget build(BuildContext context) {
    if (AdsService.isSupported) {
      return const AdBanner();
    }
    return const EventPageAd();
  }
}
