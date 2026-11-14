import '../models/event_social_link.dart';
import '../models/gem.dart';

const int kGemRichDurationDays = 30;
const int kGemRichReminderDays = 3;

bool gemIsRich(Gem gem, {DateTime? now}) {
  final until = gem.richUntil;
  if (until == null) return false;
  return until.isAfter(now ?? DateTime.now());
}

/// Public view of a gem: if the 30-day promotional window has lapsed,
/// photos, the long description, business contact and offer fields are
/// hidden. The basic card (name, category, pin, short text) stays.
Gem gemForDisplay(Gem gem, {DateTime? now}) {
  if (gemIsRich(gem, now: now)) return gem;
  return gem.copyWith(
    description: '',
    imageUrls: const [],
    clearContactPhone: true,
    clearContactWebsite: true,
    socialLinks: const EventSocialLinks.empty(),
    clearPromoTitle: true,
    clearPromoDetails: true,
    clearPromoStartsAt: true,
    clearPromoEndsAt: true,
    listingKind: GemListingKind.community,
  );
}

bool shouldRemindGemRichExpiry(Gem gem, {DateTime? now}) {
  if (!gemIsRich(gem, now: now) || gem.richUntil == null) return false;
  final clock = now ?? DateTime.now();
  final remaining = gem.richUntil!.difference(clock);
  return remaining <= const Duration(days: kGemRichReminderDays) &&
      remaining > Duration.zero;
}

/// Client-side hint used by the submit form. Server-side flagging uses the
/// same patterns in functions/lib/gemPerks.js.
bool looksLikeBusinessPromo({
  String? summary,
  String? description,
  String? phone,
  String? website,
  String? promoTitle,
  String? promoDetails,
}) {
  if ((phone ?? '').trim().isNotEmpty) return true;
  if ((website ?? '').trim().isNotEmpty) return true;
  if ((promoTitle ?? '').trim().isNotEmpty) return true;
  if ((promoDetails ?? '').trim().isNotEmpty) return true;
  final text = [summary, description].where((s) => s != null && s.trim().isNotEmpty).join(' ');
  if (text.isEmpty) return false;
  final patterns = [
    RegExp(r'happy\s*hour', caseSensitive: false),
    RegExp(r'\d{1,2}\s*%\s*off', caseSensitive: false),
    RegExp(r'\b(discount|coupon|promo code|two for one|buy one get one|\bbogo\b)\b', caseSensitive: false),
    RegExp(r'\b(sale|special offer|limited time)\b', caseSensitive: false),
    RegExp(r'\b(call|text|whatsapp|order now|book now|visit us)\b', caseSensitive: false),
    RegExp(r'\+?\d[\d\s().-]{7,}\d'),
    RegExp(r'https?://', caseSensitive: false),
    RegExp(r'\bwww\.[a-z0-9.-]+\.[a-z]{2,}\b', caseSensitive: false),
    RegExp(r'\b(instagram|facebook|tiktok)\.com\b', caseSensitive: false),
  ];
  return patterns.any((re) => re.hasMatch(text));
}
