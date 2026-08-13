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
  'Basic event page — title, description, photo, location, time',
  'Event appears in the public feed',
];

const List<(String, String)> kPremiumPlanPerks = [
  ('Recurring events', 'Post once — repeats weekly or monthly'),
  ('Featured placement', 'Top of the category feed 1× per week'),
  ('Analytics dashboard', 'Live views, saves, and click-throughs'),
  ('Custom branding', 'Logo and brand colors on your event page'),
  ('Contact button', 'Phone, website, and social links'),
  ('No ads', 'Clean event pages with no ads'),
  ('Claim existing events', 'Verify first. Your first claim is free'),
];

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
