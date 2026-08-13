/// Launch pricing. One paid tier — monthly only.
const double kFreePrice = 0;
const double kPremiumMonthlyPrice = 15;
const String kPremiumMonthlyLabel = r'$15/month';
const String kPremiumPlanName = 'SpotVibe Premium';

/// Consumer/organizer entitlement id in RevenueCat.
const String kPremiumEntitlementHint = 'pro';

const List<String> kFreePlanPerks = [
  'Post unlimited one-time events (one active at a time)',
  'Basic event page — title, description, photo, location, time',
  'Event appears in the public feed',
];

const List<(String, String)> kPremiumPlanPerks = [
  ('Recurring events', 'Post once — repeats weekly or monthly'),
  ('Featured placement', 'Top of the category feed 1× per week'),
  ('Analytics dashboard', 'Views, saves, and click-throughs'),
  ('Custom branding', 'Logo and brand colors on your event page'),
  ('Contact button', 'Phone, website, and social links'),
  ('No ads', 'Clean event pages with no ads'),
  ('Claim existing events', 'Take over a listing after promoter verification'),
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

/// Upcoming (not yet started) events count toward the free "one active" cap.
int countActiveUserEvents(Iterable<DateTime> startTimes, {DateTime? now}) {
  final clock = now ?? DateTime.now();
  return startTimes.where((t) => t.isAfter(clock)).length;
}

bool canPostAnotherFreeEvent(int activeCount, {required bool isPremium}) {
  if (isPremium) return true;
  return activeCount < 1;
}
