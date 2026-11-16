
import 'package:flutter_test/flutter_test.dart';
import 'package:spotvibe_app/data/pricing.dart';
import 'package:spotvibe_app/repositories/firebase_user_event_repository.dart';

void main() {
  test('paywall promises a trial only when the store says eligible', () {
    expect(
      paywallCta(
        isSubscribed: false,
        eligibility: IntroOfferEligibility.eligible,
      ),
      PaywallCta.trial,
    );
    expect(
      paywallCta(
        isSubscribed: false,
        eligibility: IntroOfferEligibility.ineligible,
      ),
      PaywallCta.subscribe,
    );
    expect(
      paywallCta(
        isSubscribed: false,
        eligibility: IntroOfferEligibility.unknown,
      ),
      PaywallCta.subscribe,
    );
    expect(
      paywallCta(
        isSubscribed: true,
        eligibility: IntroOfferEligibility.eligible,
      ),
      PaywallCta.alreadyPremium,
    );
    expect(paywallPromisesTrial(IntroOfferEligibility.unknown), isFalse);
    expect(paywallPromisesTrial(IntroOfferEligibility.eligible), isTrue);
  });

  test('free-tier copy still includes the 2-event cap and first claim', () {
    expect(kFreePlanPerks, contains('Post up to 2 upcoming one-time events at a time'));
    expect(kFreePlanPerks, contains('Your first claim of an existing event is free'));
    expect(kFreePlanPerks, contains('Public view, save, and share counts'));
    expect(
      kPremiumPlanPerks.any((perk) => perk.$1 == 'Unlimited upcoming events'),
      isTrue,
    );
    expect(kPremiumMonthlyPrice, 12.99);
    expect(kFoundingMonthlyPrice, 9.99);
  });

  test('direct-write fallback strips Premium perk fields and extra media', () {
    final stripped = FirebaseUserEventRepository.freeShapedFallback({
      'title': 'Open mic',
      'recurringType': 'weekly',
      'contactPhone': '+1 555',
      'brandColor': '#ff0',
      'isPremiumListing': true,
      'isCreatorPro': true,
      'featuredWeekKey': '2026-W46',
      'imageUrls': ['https://x.test/a.jpg', 'https://x.test/b.jpg'],
      'videoUrls': ['https://x.test/v1.mp4', 'https://x.test/v2.mp4'],
    });
    expect(stripped['recurringType'], 'none');
    expect(stripped['contactPhone'], isNull);
    expect(stripped['brandColor'], isNull);
    expect(stripped['isPremiumListing'], isFalse);
    expect(stripped['isCreatorPro'], isFalse);
    expect(stripped.containsKey('featuredWeekKey'), isFalse);
    expect(stripped['imageUrls'], ['https://x.test/a.jpg']);
    expect(stripped['videoUrls'], ['https://x.test/v1.mp4']);
  });
}
