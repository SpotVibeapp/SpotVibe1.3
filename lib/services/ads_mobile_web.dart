import 'package:flutter/widgets.dart';

/// Web builds do not ship Google Mobile Ads. The slot collapses.
Future<void> initializeMobileAds() async {}

Future<void> runMobileAdConsent() async {}

class MobileBannerAd extends StatelessWidget {
  const MobileBannerAd({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
