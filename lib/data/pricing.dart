/// Launch pricing. One paid tier — monthly only.
const double kFreePrice = 0;
const double kPremiumMonthlyPrice = 12.99;
const String kPremiumMonthlyLabel = r'$12.99/month';
const String kPremiumPlanName = 'SpotVibe Premium';

/// 7-day intro on the monthly product (configure the same offer in App Store /
/// Play / RevenueCat so the store charge matches this copy).
const int kPremiumTrialDays = 7;
const String kPremiumTrialLabel = '7-day free trial';

/// First [kFoundingMemberLimit] venues lock this price for as long as they stay subscribed.
const int kFoundingMemberLimit = 25;
const double kFoundingMonthlyPrice = 9.99;
const String kFoundingMonthlyLabel = r'$9.99/month';
const String kFoundingProductHint = 'founding';

/// Store / RevenueCat identifiers. Create these exact IDs in App Store Connect,
/// Google Play Console, and RevenueCat (see STORE_PRODUCTS.md).
const String kPremiumMonthlyProductId = 'spotvibe_premium_monthly';
const String kFoundingMonthlyProductId = 'spotvibe_premium_founding_monthly';
const String kPremiumOfferingId = 'default';
const String kFoundingOfferingId = 'founding';

/// Consumer/organizer entitlement id in RevenueCat.
const String kPremiumEntitlementHint = 'pro';
const String kProEntitlementIdAlias = 'pro';

bool isFoundingStoreProduct(String? productId) {
  if (productId == null || productId.isEmpty) return false;
  final id = productId.toLowerCase();
  if (id == kFoundingMonthlyProductId) return true;
  return id.contains(kFoundingProductHint);
}

bool isPremiumMonthlyStoreProduct(String? productId) {
  if (productId == null || productId.isEmpty) return false;
  final id = productId.toLowerCase();
  if (isFoundingStoreProduct(id)) return false;
  return id == kPremiumMonthlyProductId ||
      id.contains('premium_monthly') ||
      (id.contains('premium') && id.contains('month'));
}

/// Upcoming (not yet started) events that count toward the free cap.
const int kFreeUserActiveEventLimit = 2;

const List<String> kFreePlanPerks = [
  'Post up to 2 upcoming one-time events at a time',
  'Basic event page — title, short description, 1 cover photo, location, time',
  'Basic RSVP: going, a headcount, and the attendee name list',
  'Event appears in the public feed',
  'Public view, save, and share counts',
  'Edit your listing anytime',
  'Simple share card you can post anywhere',
  'Your first claim of an existing event is free',
  'Up to 4 event posts per calendar month (and 2 upcoming at a time)',
  'Share a basic Hidden Gem for free — a trail or a cool spot, no promotions',
];

const List<(String, String)> kPremiumPlanPerks = [
  ('Recurring events', 'Post once — repeats weekly or monthly'),
  ('Featured placement', 'Top of the category feed 1× per week'),
  ('Social media links', 'Instagram, Facebook, TikTok, X, and a website on the event page'),
  ('Full analytics dashboard', 'Views, taps, RSVPs, and saves — totals only, on top of public counts'),
  ('RSVP tools and ticket link', 'Capacity limits, reminders, attendee exports, and the Get-tickets button'),
  ('Custom branding', 'Logo and brand colors on your event page'),
  ('Contact button', 'Phone and website on your event page'),
  ('Additional event claims', 'Unlock more claims after your first free one'),
  ('Rich media gallery', 'Up to 5 photos and 3 short videos on every event'),
  ('Unlimited upcoming events', 'No two-event cap and no monthly post cap'),
  ('Early Hidden Gems', 'See newly added gems immediately, plus a nearby heads-up'),
  ('30-day business Hidden Gems', 'Photos, a full description, contact details, and promo offers. Renews with your \$12.99/month subscription.'),
];

/// Store intro-offer eligibility for the paywall CTA.
enum IntroOfferEligibility { unknown, eligible, ineligible }

enum PaywallCta { trial, subscribe, alreadyPremium }

/// Eligible users see "Start 7-day free trial". Everyone else — including
/// unknown eligibility — sees a priced Subscribe CTA so we never promise a
/// trial the store will not give.
PaywallCta paywallCta({
  required bool isSubscribed,
  required IntroOfferEligibility eligibility,
}) {
  if (isSubscribed) return PaywallCta.alreadyPremium;
  if (eligibility == IntroOfferEligibility.eligible) return PaywallCta.trial;
  return PaywallCta.subscribe;
}

bool paywallPromisesTrial(IntroOfferEligibility eligibility) =>
    eligibility == IntroOfferEligibility.eligible;

const _kPersonalEmailDomains = {
  'gmail.com',
  'googlemail.com',
  'yahoo.com',
  'yahoo.co.uk',
  'hotmail.com',
  'outlook.com',
  'live.com',
  'msn.com',
  'icloud.com',
  'me.com',
  'aol.com',
  'proton.me',
  'protonmail.com',
  'gmx.com',
  'mail.com',
};

/// True when [email] looks like a personal inbox, not a venue/work domain.
bool isPersonalEmail(String email) {
  final at = email.trim().toLowerCase().lastIndexOf('@');
  if (at < 0 || at == email.length - 1) return true;
  return _kPersonalEmailDomains.contains(email.trim().toLowerCase().substring(at + 1));
}

bool isValidEmail(String email) {
  final value = email.trim();
  return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value);
}

/// Upcoming (not yet started) events count toward the free cap.
int countActiveUserEvents(Iterable<DateTime> startTimes, {DateTime? now}) {
  final clock = now ?? DateTime.now();
  return startTimes.where((t) => t.isAfter(clock)).length;
}

bool canPostAnotherFreeEvent(int activeCount, {required bool isPremium}) {
  if (isPremium) return true;
  return activeCount < kFreeUserActiveEventLimit;
}

int countPostsInCalendarMonth(Iterable<DateTime> createdAts, {DateTime? now}) {
  final clock = now ?? DateTime.now();
  return createdAts.where((t) => t.year == clock.year && t.month == clock.month).length;
}

/// First approved claim is free. Later claims need Premium to unlock edits.
bool claimUnlocksWithoutPay({
  required int priorUnlockedClaims,
  required bool isPremium,
}) {
  if (isPremium) return true;
  return priorUnlockedClaims < 1;
}

bool foundingSlotsRemain(int claimedCount) =>
    claimedCount < kFoundingMemberLimit;

int foundingSlotsLeft(int claimedCount) {
  final left = kFoundingMemberLimit - claimedCount;
  return left < 0 ? 0 : left;
}

String priceLabel({required bool founding}) =>
    founding ? kFoundingMonthlyLabel : kPremiumMonthlyLabel;

double priceAmount({required bool founding}) =>
    founding ? kFoundingMonthlyPrice : kPremiumMonthlyPrice;

/// ISO week key used to enforce "featured 1× per week", e.g. `2026-W33`.
String isoWeekKey(DateTime date) {
  final utc = DateTime.utc(date.year, date.month, date.day);
  final thursday = utc.add(Duration(days: 4 - utc.weekday));
  final firstThursday = DateTime.utc(thursday.year, 1, 4);
  final week = 1 + ((thursday.difference(firstThursday).inDays) / 7).floor();
  return '${thursday.year}-W${week.toString().padLeft(2, '0')}';
}

bool isFeaturedInCurrentWeek(String? featuredWeekKey, {DateTime? now}) {
  if (featuredWeekKey == null || featuredWeekKey.isEmpty) return false;
  return featuredWeekKey == isoWeekKey(now ?? DateTime.now());
}
