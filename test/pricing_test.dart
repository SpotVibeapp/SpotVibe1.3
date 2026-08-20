import 'package:flutter_test/flutter_test.dart';
import 'package:spotvibe_app/data/pricing.dart';
import 'package:spotvibe_app/models/event_claim.dart';
import 'package:spotvibe_app/repositories/event_claim_repository.dart';
import 'package:spotvibe_app/repositories/founding_member_repository.dart';
import 'package:spotvibe_app/repositories/user_event_repository.dart';
import 'package:spotvibe_app/services/event_analytics_service.dart';
import 'package:spotvibe_app/services/event_service.dart';
import 'package:spotvibe_app/models/event.dart';

void main() {
  test('launch Premium is \$12.99 monthly with a 7-day trial', () {
    expect(kPremiumMonthlyPrice, 12.99);
    expect(kFreePrice, 0);
    expect(kPremiumTrialDays, 7);
    expect(kFreeUserActiveEventLimit, 2);
  });

  test('free users may post two upcoming events', () {
    expect(canPostAnotherFreeEvent(0, isPremium: false), isTrue);
    expect(canPostAnotherFreeEvent(1, isPremium: false), isTrue);
    expect(canPostAnotherFreeEvent(2, isPremium: false), isFalse);
    expect(canPostAnotherFreeEvent(3, isPremium: true), isTrue);
  });

  test('active events are those still in the future', () {
    final now = DateTime(2026, 8, 13, 12);
    final count = countActiveUserEvents([
      DateTime(2026, 8, 12),
      DateTime(2026, 8, 20),
      DateTime(2026, 9, 1),
    ], now: now);
    expect(count, 2);
  });

  test('personal email domains are flagged for claim proof', () {
    expect(isPersonalEmail('owner@plaza-theatre.com'), isFalse);
    expect(isPersonalEmail('promoter@gmail.com'), isTrue);
    expect(isValidEmail('bad'), isFalse);
    expect(isValidEmail('a@b.co'), isTrue);
  });

  test('first claim unlocks without pay; later claims need Premium', () {
    expect(
      claimUnlocksWithoutPay(priorUnlockedClaims: 0, isPremium: false),
      isTrue,
    );
    expect(
      claimUnlocksWithoutPay(priorUnlockedClaims: 1, isPremium: false),
      isFalse,
    );
    expect(
      claimUnlocksWithoutPay(priorUnlockedClaims: 4, isPremium: true),
      isTrue,
    );
  });

  test('store product ids match the App Store / Play SKUs', () {
    expect(kPremiumMonthlyProductId, 'spotvibe_premium_monthly');
    expect(kFoundingMonthlyProductId, 'spotvibe_premium_founding_monthly');
    expect(isFoundingStoreProduct('spotvibe_premium_founding_monthly'), isTrue);
    expect(isFoundingStoreProduct('spotvibe_premium_monthly'), isFalse);
    expect(isPremiumMonthlyStoreProduct('spotvibe_premium_monthly'), isTrue);
    expect(isPremiumMonthlyStoreProduct('spotvibe_premium_founding_monthly'), isFalse);
  });

  test('founding roster locks 25 venues at \$9.99', () {
    expect(foundingSlotsRemain(0), isTrue);
    expect(foundingSlotsLeft(24), 1);
    expect(foundingSlotsRemain(25), isFalse);
    expect(priceLabel(founding: true), r'$9.99/month');
    expect(priceAmount(founding: false), 12.99);
  });

  test('featured week key is stable for a Thursday in the same ISO week', () {
    final monday = DateTime(2026, 8, 10);
    final sunday = DateTime(2026, 8, 16);
    expect(isoWeekKey(monday), isoWeekKey(sunday));
    expect(isFeaturedInCurrentWeek(isoWeekKey(monday), now: sunday), isTrue);
    expect(isFeaturedInCurrentWeek('1999-W01', now: monday), isFalse);
  });

  test('featured events are promoted to the top of the feed', () {
    final week = isoWeekKey(DateTime.now());
    final later = Event(
      id: 'a',
      title: 'Later',
      description: 'd',
      dateTime: DateTime(2026, 8, 20),
      location: 'x',
      address: 'x',
      imageUrl: '',
      category: 'Music',
      organizerName: 'o',
      organizerAvatarUrl: '',
    );
    final featured = Event(
      id: 'b',
      title: 'Featured',
      description: 'd',
      dateTime: DateTime(2026, 8, 22),
      location: 'x',
      address: 'x',
      imageUrl: '',
      category: 'Music',
      organizerName: 'o',
      organizerAvatarUrl: '',
      featuredWeekKey: week,
      isCreatorPro: true,
    );
    final sorted = promoteFeaturedEvents([later, featured]);
    expect(sorted.first.id, 'b');
    expect(sorted.first.isFeaturedThisWeek, isTrue);
  });

  test('claims remain pending until an admin approves the handoff', () async {
    final repo = MockEventClaimRepository();
    final claim = await repo.submit(
      EventClaim(
        id: '',
        eventId: 'evt1',
        eventTitle: 'Show',
        venueName: 'Plaza',
        userId: 'u1',
        fullName: 'Owner',
        email: 'owner@plaza-theatre.com',
        phone: '',
        organization: 'Plaza',
        role: ClaimRole.owner,
        proofMethod: ClaimProofMethod.officialEmail,
        proofUrl: '',
        statement: 'I run the box office.',
        status: ClaimStatus.pending,
        createdAt: DateTime(2026, 8, 12),
      ),
    );
    expect(claim.status, ClaimStatus.pending);
    expect(claim.unlocked, isFalse);
    expect(await repo.isApprovedPromoter(eventId: 'evt1', userId: 'u1'), isFalse);

    await repo.updateClaimStatus(claim.id, approve: true);
    expect(await repo.isApprovedPromoter(eventId: 'evt1', userId: 'u1'), isTrue);
  });

  test('admin approval unlocks a submitted claim without client self-unlock', () async {
    final repo = MockEventClaimRepository();
    Future<EventClaim> submit(String eventId, String email) {
      return repo.submit(
        EventClaim(
          id: '',
          eventId: eventId,
          eventTitle: 'Show',
          venueName: 'Venue',
          userId: 'u1',
          fullName: 'Owner',
          email: email,
          phone: '',
          organization: 'Co',
          role: ClaimRole.owner,
          proofMethod: ClaimProofMethod.officialEmail,
          proofUrl: '',
          statement: 'Authorized.',
          status: ClaimStatus.pending,
          createdAt: DateTime(2026, 8, 12),
        ),
      );
    }

    await submit('evt1', 'owner@plaza-theatre.com');
    final second = await submit('evt2', 'owner@plaza-theatre.com');
    expect(second.status, ClaimStatus.pending);
    expect(second.unlocked, isFalse);
    expect(await repo.unlockEligibleForUser('u1'), 0);

    await repo.updateClaimStatus(second.id, approve: true);
    expect(await repo.isApprovedPromoter(eventId: 'evt2', userId: 'u1'), isTrue);
  });

  test('founding repository stops at 25 members', () async {
    final repo = MockFoundingMemberRepository(
      seedIds: List.generate(24, (i) => 'v$i'),
    );
    final last = await repo.claimSlot('venue-25');
    expect(last.userIsMember, isTrue);
    expect(last.remaining, 0);
    final extra = await repo.claimSlot('venue-26');
    expect(extra.userIsMember, isFalse);
    expect(extra.claimedCount, 25);
  });

  test('analytics increments are live and session-deduped', () async {
    final repo = UserEventRepository();
    final created = await repo.createEvent(
      creatorId: 'u1',
      title: 'Live Night',
      description: 'desc',
      dateTime: DateTime.now().add(const Duration(days: 3)),
      location: 'Bar',
      address: '1 Main',
      category: 'Music',
      organizerName: 'Sam',
      isCreatorPro: true,
    );
    expect(created.analyticsViews, 0);
    final analytics = EventAnalyticsService(repository: repo);
    await analytics.recordView(created.id);
    await analytics.recordView(created.id);
    await analytics.recordSave(created.id);
    await analytics.recordClick(created.id);
    final updated = await repo.getEventById(created.id);
    expect(updated!.analyticsViews, 1);
    expect(updated.analyticsSaves, 1);
    expect(updated.analyticsClicks, 1);
  });
}
