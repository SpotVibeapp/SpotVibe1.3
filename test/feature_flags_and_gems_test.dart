
import 'package:flutter_test/flutter_test.dart';
import 'package:spotvibe_app/data/gem_visibility.dart';
import 'package:spotvibe_app/data/pricing.dart';
import 'package:spotvibe_app/models/gem.dart';
import 'package:spotvibe_app/services/feature_flags.dart';

Gem _gem({required DateTime created, String creatorId = 'a'}) {
  return Gem(
    id: 'g1',
    creatorId: creatorId,
    creatorName: 'Ada',
    name: 'Quiet trail',
    category: GemCategory.trail,
    summary: 'A quiet trail',
    description: 'A quiet trail in the foothills',
    latitude: 31.8,
    longitude: -106.4,
    address: 'El Paso',
    createdAt: created,
  );
}

void main() {
  test('basic RSVP is free by default; the ticket link stays Premium', () {
    expect(kDefaultGateBasicRsvpPremium, isFalse);
    expect(shouldGateBasicRsvp(basicRsvpFlagOn: false, isSubscribed: false), isFalse);
    expect(shouldGateBasicRsvp(basicRsvpFlagOn: true, isSubscribed: false), isTrue);
    expect(shouldGateBasicRsvp(basicRsvpFlagOn: true, isSubscribed: true), isFalse);
    expect(kDefaultGateRsvpTicketsPremium, isTrue);
    expect(
      shouldGateTicketLink(masterFlagOn: true, isSubscribed: false),
      isTrue,
    );
    expect(
      shouldGateTicketLink(masterFlagOn: true, isSubscribed: true),
      isFalse,
    );
    expect(
      shouldGateTicketLink(
        masterFlagOn: true,
        ticketLinkOverride: false,
        isSubscribed: false,
      ),
      isFalse,
    );
    expect(shouldGateRsvpTickets(flagOn: true, isSubscribed: false), isTrue);
  });

  test('free description cap defaults to about 300 and is clampable', () {
    expect(kDefaultFreeEventDescriptionMax, 300);
    expect(clampFreeEventDescriptionMax(20), kFreeEventDescriptionMaxFloor);
    expect(clampFreeEventDescriptionMax(900), kFreeEventDescriptionMaxCeiling);
    expect(clampFreeEventDescriptionMax(300), 300);
    expect(allowedFreeDescriptionLength(cap: 300), 300);
    expect(allowedFreeDescriptionLength(cap: 300, existingLength: 420), 420);
  });

  test('free organizers have a monthly post cap and a 2-upcoming cap', () {
    expect(canPostAnotherFreeEventThisMonth(3, isPremium: false, cap: 4), isTrue);
    expect(canPostAnotherFreeEventThisMonth(4, isPremium: false, cap: 4), isFalse);
    expect(canPostAnotherFreeEventThisMonth(40, isPremium: true, cap: 4), isTrue);
    expect(kDefaultFreeEventPostsPerMonth, 4);
    final now = DateTime(2026, 11, 14);
    expect(
      countPostsInCalendarMonth([
        DateTime(2026, 11, 1),
        DateTime(2026, 10, 31),
        DateTime(2026, 11, 14),
      ], now: now),
      2,
    );
  });

  test('casual share-a-spot gems are visible immediately', () {
    final created = DateTime.utc(2026, 11, 14, 12);
    final gem = _gem(created: created);
    expect(
      gemVisibleToViewer(
        gem,
        isPremium: false,
        viewerId: 'b',
        now: created.add(const Duration(hours: 1)),
      ),
      isTrue,
    );
  });

  test('new business promo gems are delayed for free viewers, not for Premium or the creator', () {
    final created = DateTime.utc(2026, 11, 14, 12);
    final gem = _gem(created: created).copyWith(listingKind: GemListingKind.business);
    final twelveHoursLater = created.add(const Duration(hours: 12));
    expect(
      gemVisibleToViewer(gem, isPremium: false, viewerId: 'b', now: twelveHoursLater),
      isFalse,
    );
    expect(
      gemVisibleToViewer(gem, isPremium: true, viewerId: 'b', now: twelveHoursLater),
      isTrue,
    );
    expect(
      gemVisibleToViewer(gem, isPremium: false, viewerId: 'a', now: twelveHoursLater),
      isTrue,
    );
    expect(
      gemVisibleToViewer(
        gem,
        isPremium: false,
        viewerId: 'b',
        now: created.add(const Duration(hours: 48)),
      ),
      isTrue,
    );
    expect(kDefaultGemEarlyAccessHours, 48);
  });
}
