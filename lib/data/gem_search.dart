import '../models/gem.dart';
import '../repositories/gem_repository.dart';
import 'gem_listing.dart';

const List<double> kGemRadiusMilesOptions = [5, 15, 30, 60];
const int kGemSearchPageSize = 40;
const double kPromotedMaxPageShare = 0.30;
const int kPromotedMinCasualBetween = 2;
const double kPromotedPinStackMiles = 0.08;

enum GemSortOrder { nearest, newest, mostLiked }

/// Lowercase tokens written on the gem doc so keyword search can run on the
/// device after a geo query (Firestore cannot combine two array-contains).
List<String> gemSearchTokensFor({
  String? name,
  String? summary,
  String? address,
  String? city,
  String? category,
  String? businessType,
  String? offerTitle,
  String? offerText,
}) {
  final tokens = <String>{};
  void add(String? raw) {
    if (raw == null || raw.trim().isEmpty) return;
    for (final part in raw.toLowerCase().split(RegExp(r'[^a-z0-9]+'))) {
      if (part.length >= 2) tokens.add(part);
    }
  }

  add(name);
  add(summary);
  add(address);
  add(city);
  add(category);
  add(businessType);
  add(offerTitle);
  add(offerText);
  return tokens.take(80).toList();
}

List<String> gemSearchTokensFromGem(Gem gem) => gemSearchTokensFor(
      name: gem.name,
      summary: gem.summary,
      address: gem.address,
      city: gem.city,
      category: gem.category.key,
      businessType: gem.businessType?.key,
      offerTitle: gem.offerTitle ?? gem.promoTitle,
      offerText: gem.offerText ?? gem.promoDetails,
    );

bool gemMatchesKeyword(Gem gem, String query) {
  final terms = query
      .toLowerCase()
      .split(RegExp(r'[^a-z0-9]+'))
      .where((t) => t.length >= 2)
      .toList();
  if (terms.isEmpty) return true;
  final hay = (gem.searchTokens.isNotEmpty
          ? gem.searchTokens
          : gemSearchTokensFromGem(gem))
      .map((t) => t.toLowerCase())
      .toList();
  return terms.every((term) => hay.any((token) => token.contains(term)));
}

bool gemIsPromoted(Gem gem, {DateTime? now}) =>
    gem.listingTier == GemListingTier.promoted || gemIsRich(gem, now: now);

bool gemHasActiveOffer(Gem gem, {DateTime? now}) {
  final clock = now ?? DateTime.now();
  final until = gem.offerUntil ?? gem.promoEndsAt;
  if (until != null && !until.isAfter(clock)) return false;
  if (gem.hasOffer) return true;
  final title = (gem.offerTitle ?? gem.promoTitle ?? '').trim();
  final text = (gem.offerText ?? gem.promoDetails ?? '').trim();
  return title.isNotEmpty || text.isNotEmpty;
}

/// Mix promoted cards into a page so they are at most about one in three
/// and about 30% of the page, and never stack two promoted cards together
/// when a casual card is still available.
List<Gem> interleavePromoted(
  Iterable<Gem> gems, {
  int pageSize = kGemSearchPageSize,
  DateTime? now,
}) {
  final promoted = <Gem>[];
  final casual = <Gem>[];
  for (final gem in gems) {
    if (gemIsPromoted(gem, now: now)) {
      promoted.add(gem);
    } else {
      casual.add(gem);
    }
  }
  final out = <Gem>[];
  var p = 0;
  var c = 0;
  var casualSincePromo = kPromotedMinCasualBetween;
  final maxPromo = (pageSize * kPromotedMaxPageShare).floor();
  while (out.length < pageSize && (c < casual.length || p < promoted.length)) {
    final promoShareOk =
        p < promoted.length &&
        (out.isEmpty
            ? maxPromo > 0
            : (p + 1) <= ((out.length + 1) / 3).ceil()) &&
        (p + 1) <= maxPromo;
    final canPromo = promoShareOk && casualSincePromo >= kPromotedMinCasualBetween;
    if (canPromo && (c >= casual.length || casualSincePromo >= kPromotedMinCasualBetween)) {
      out.add(promoted[p]);
      p += 1;
      casualSincePromo = 0;
    } else if (c < casual.length) {
      out.add(casual[c]);
      c += 1;
      casualSincePromo += 1;
    } else if (promoShareOk) {
      out.add(promoted[p]);
      p += 1;
      casualSincePromo = 0;
    } else {
      break;
    }
  }
  return out;
}

/// Drop a promoted map pin when it would sit on top of a casual pin.
List<Gem> mapPinsWithoutStackedPromos(
  Iterable<Gem> gems, {
  double minMiles = kPromotedPinStackMiles,
  DateTime? now,
}) {
  final casual = gems.where((g) => !gemIsPromoted(g, now: now)).toList();
  final promoted = gems.where((g) => gemIsPromoted(g, now: now)).toList();
  final pins = [...casual];
  for (final gem in promoted) {
    final stacks = casual.any((other) =>
        GemRepository.distanceMiles(
              gem.latitude,
              gem.longitude,
              other.latitude,
              other.longitude,
            ) <=
            minMiles);
    if (!stacks) pins.add(gem);
  }
  return pins;
}

List<Gem> dealsNearYou(
  Iterable<Gem> gems, {
  required double lat,
  required double lng,
  required double radiusMiles,
  DateTime? now,
}) {
  final clock = now ?? DateTime.now();
  final out = gems.where((gem) {
    if (!gemHasActiveOffer(gem, now: clock)) return false;
    return GemRepository.distanceMiles(lat, lng, gem.latitude, gem.longitude) <=
        radiusMiles;
  }).toList()
    ..sort((a, b) => GemRepository.distanceMiles(lat, lng, a.latitude, a.longitude)
        .compareTo(
            GemRepository.distanceMiles(lat, lng, b.latitude, b.longitude)));
  return out;
}

List<Gem> sortGems(
  Iterable<Gem> gems, {
  required GemSortOrder order,
  double? lat,
  double? lng,
}) {
  final list = gems.toList();
  switch (order) {
    case GemSortOrder.nearest:
      if (lat == null || lng == null) {
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      } else {
        list.sort((a, b) => GemRepository.distanceMiles(lat, lng, a.latitude, a.longitude)
            .compareTo(GemRepository.distanceMiles(lat, lng, b.latitude, b.longitude)));
      }
    case GemSortOrder.newest:
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    case GemSortOrder.mostLiked:
      list.sort((a, b) {
        final likes = b.likeCount.compareTo(a.likeCount);
        return likes != 0 ? likes : b.createdAt.compareTo(a.createdAt);
      });
  }
  return list;
}

List<Gem> gemsOpenNow(Iterable<Gem> gems, {DateTime? now}) {
  final clock = now ?? DateTime.now();
  return gems.where((gem) => gem.hours.isOpenAt(clock)).toList();
}
