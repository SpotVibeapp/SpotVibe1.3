import 'dart:math' as math;

import '../models/event.dart';
import 'event_images.dart';

/// Two listings closer than this sit at the same place *when their venue
/// names already look related* ("UTEP Don Haskins Ctr" / "Don Haskins
/// Center") or one side has no name at all. Wide enough for geocoder drift
/// across a stadium footprint. Unrelated names are never merged on distance
/// alone: downtown's bars and museums share blocks, not events.
const double kSameVenueMetres = 250;

/// Two listings farther apart than this are at different places whatever
/// their names say — the guard that keeps "Trivia Night" at two branches
/// of the same chain from collapsing when both carry coordinates.
const double kDifferentVenueMetres = 2000;

const Map<String, String> _accentFolds = {
  'á': 'a', 'à': 'a', 'â': 'a', 'ä': 'a', 'ã': 'a', 'å': 'a',
  'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e',
  'í': 'i', 'ì': 'i', 'î': 'i', 'ï': 'i',
  'ó': 'o', 'ò': 'o', 'ô': 'o', 'ö': 'o', 'õ': 'o',
  'ú': 'u', 'ù': 'u', 'û': 'u', 'ü': 'u',
  'ñ': 'n', 'ç': 'c',
};

final RegExp _accentPattern = RegExp('[${_accentFolds.keys.join()}]');

/// Words that carry no identity in a venue name and are dropped before
/// comparing word sets.
const Set<String> _venueGlue = {
  'the', 'a', 'an', 'of', 'and', 'at', 'in', 'on', 'for',
  'de', 'del', 'la', 'las', 'los', 'el', 'y',
};

/// Spelling variants unified so "Theatre"/"Theater" and "Ctr"/"Center" are
/// the same word.
const Map<String, String> _venueSynonyms = {
  'theatre': 'theater',
  'centre': 'center',
  'ctr': 'center',
  'cntr': 'center',
  'amphitheatre': 'amphitheater',
  'ampitheater': 'amphitheater',
  'amph': 'amphitheater',
  'univ': 'university',
  'pk': 'park',
  'stad': 'stadium',
  'aud': 'auditorium',
  'mt': 'mount',
  'mtn': 'mountain',
  'ft': 'fort',
};

/// Place qualifiers: words that locate a venue rather than name it. Ignored
/// both for proving two names mean the same place and for deciding whether
/// two names are related at all.
const Set<String> _placeQualifiers = {
  'paso', 'texas', 'tx', 'downtown', 'east', 'west', 'north', 'south',
  'central', 'city', 'county', 'state', 'new', 'old', 'upper', 'lower',
  'inc', 'llc',
};

/// Venue types: too common to prove two names mean the same place on their
/// own ("Community Center" is not every community center), but enough to
/// show two names at the same coordinates are *related* ("El Paso
/// Convention Center" / "Judson F. Williams Convention Center").
const Set<String> _venueTypes = {
  'center', 'theater', 'amphitheater', 'park', 'stadium', 'arena', 'hall',
  'club', 'bar', 'grill', 'lounge', 'room', 'museum', 'gallery', 'church',
  'school', 'field', 'fields', 'complex', 'pavilion', 'ballroom',
  'auditorium', 'library', 'garden', 'gardens', 'house', 'venue', 'cafe',
  'restaurant', 'brewery', 'brewing', 'winery', 'hotel', 'resort', 'mall',
  'market', 'district', 'street', 'st', 'avenue', 'ave', 'blvd',
  'boulevard', 'road', 'rd', 'drive', 'dr', 'suite', 'ste', 'national',
  'memorial', 'community', 'convention', 'entertainment', 'event', 'events',
  'sports', 'recreation', 'rec',
};

/// Normalizes a title/venue for comparison: lowercase, accents folded
/// ("Debí" and "Debi" are the same show), letters/digits only.
String normalizeEventText(String raw) {
  var text = raw
      .toLowerCase()
      .replaceAllMapped(_accentPattern, (m) => _accentFolds[m[0]] ?? m[0]!)
      .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
      .trim();
  if (text.startsWith('the ')) text = text.substring(4);
  return text;
}

/// Drops Ticketmaster product tails (Parking, VIP, theme nights) so the
/// same game is not listed four times.
String stripListingNoise(String title) {
  var text = title.trim();
  text = text.replaceAll(RegExp(r'\s*[\(\[\{][^\)\]\}]*[\)\]\}]'), '');
  text = text.replaceAll(
    RegExp(
      r'\s*[-–—|]\s*(parking|vip|suite|suites|hospitality|presale|pre-sale|'
      r'theme night|fireworks|kids eat free|group|pass|package|add-?on|'
      r'flex plan|season ticket).*$',
      caseSensitive: false,
    ),
    '',
  );
  text = text.replaceAll(
    RegExp(
      r'\s+\b(parking( pass)?|vip experience|suites?)\s*$',
      caseSensitive: false,
    ),
    '',
  );
  return text.trim();
}

bool looksLikeStandaloneAddon(String title) {
  final text = normalizeEventText(stripListingNoise(title));
  if (text.isEmpty) return true;
  const addons = {
    'parking',
    'parking pass',
    'vip',
    'vip experience',
    'suite',
    'suites',
    'hospitality',
    'club access',
  };
  return addons.contains(text);
}

/// "A vs B" / "A versus B" / "A @ B" / "A at B" → sorted team pair, or null.
///
/// "at" covers the away-at-home form SeatGeek favours ("Round Rock Express
/// at El Paso Chihuahuas") so it meets Ticketmaster's "El Paso Chihuahuas
/// vs. Round Rock Express". The key is order-independent, so it only ever
/// equals another key built from the same two names.
String? sportsMatchupKey(String title) {
  final cleaned = stripListingNoise(title);
  final parts = cleaned.split(
    RegExp(r'\s+(?:vs\.?|versus|v\.|@|at)\s+', caseSensitive: false),
  );
  if (parts.length != 2) return null;
  final teams = parts.map(normalizeEventText).where((t) => t.isNotEmpty).toList()
    ..sort();
  if (teams.length != 2) return null;
  return teams.join('|');
}

/// The part of a title providers agree on. Removes listing noise, tour
/// names after a separator ("Drake: It's All a Blur Tour" → "Drake"),
/// support-act tails ("with special guest …", "feat. …"), "An Evening With"
/// framing and "Live" / "In Concert" endings.
String eventTitleCore(String title) {
  var text = stripListingNoise(title);
  text = text.replaceFirst(
    RegExp(r'\s*[:\-–—|]\s+[^:\-–—|]*\btour\b.*$', caseSensitive: false),
    '',
  );
  text = text.replaceFirst(
    RegExp(
      r'\s+(?:with special guests?|w/|feat\.?|featuring)\s+.*$',
      caseSensitive: false,
    ),
    '',
  );
  text = normalizeEventText(text);
  text = text.replaceFirst(
    RegExp(r'^(an evening with|a night with|an afternoon with) '),
    '',
  );
  text = text.replaceFirst(RegExp(r' (live in concert|in concert|live)$'), '');
  return text.trim();
}

/// Canonical word set for a venue name: accents folded, glue words dropped,
/// spelling variants unified. Empty for an empty name.
Set<String> venueTokens(String venue) {
  final out = <String>{};
  for (final word in normalizeEventText(venue).split(' ')) {
    if (word.isEmpty || _venueGlue.contains(word)) continue;
    out.add(_venueSynonyms[word] ?? word);
  }
  return out;
}

/// Tokens that actually name the place: neither qualifiers nor types.
Set<String> _distinctive(Set<String> tokens) => tokens
    .where((t) => !_placeQualifiers.contains(t) && !_venueTypes.contains(t))
    .toSet();

/// Tokens that say something about the place, qualifiers aside.
Set<String> _substantive(Set<String> tokens) =>
    tokens.where((t) => !_placeQualifiers.contains(t)).toSet();

/// Whether [short] is a whole-word prefix of [long] ("bad bunny" opens
/// "bad bunny debi tirar mas fotos"; "tool" does not open "toolbox comedy
/// night"). The stem must carry some identity — two words or eight letters
/// — so "yoga" cannot claim "yoga nidra" and "tool" cannot claim "tool
/// tribute night".
bool _isWordPrefix(String short, String long) {
  if (long.length <= short.length || !long.startsWith('$short ')) return false;
  return short.length >= 8 || short.contains(' ');
}

double _metresBetween(double lat1, double lng1, double lat2, double lng2) {
  const earthRadius = 6371000.0;
  double rad(double deg) => deg * math.pi / 180;
  final dLat = rad(lat2 - lat1);
  final dLng = rad(lng2 - lng1);
  final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(rad(lat1)) *
          math.cos(rad(lat2)) *
          math.sin(dLng / 2) *
          math.sin(dLng / 2);
  return earthRadius * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
}

bool _hasCoords(Event event) => !(event.latitude == 0 && event.longitude == 0);

double? _gapMetres(Event a, Event b) => _hasCoords(a) && _hasCoords(b)
    ? _metresBetween(a.latitude, a.longitude, b.latitude, b.longitude)
    : null;

/// How sure one signal is that two listings agree.
enum _Tier {
  /// Nothing in common.
  none,

  /// Titles: one is a whole-word prefix of the other.
  /// Venues: coordinates coincide but the names share no word at all.
  near,

  /// Venues only: coordinates coincide and the names share a word, or one
  /// side has no name to disagree with.
  weak,

  /// Exact: same title / same matchup; same venue words or one name inside
  /// the other.
  strong,
}

/// Pre-computed comparison keys for one listing, so a day's worth of
/// pairwise checks does not re-normalise strings.
class _Row {
  _Row(this.event)
      : day = event.dateTime.year * 10000 +
            event.dateTime.month * 100 +
            event.dateTime.day,
        title = eventTitleCore(event.title),
        matchup = sportsMatchupKey(event.title),
        named = event.location.trim().isNotEmpty,
        venue = venueTokens(
          event.location.isNotEmpty ? event.location : event.fullLocation,
        ),
        quality = _quality(event);

  /// The listing this row currently stands for; grows richer as duplicates
  /// are absorbed into it.
  Event event;
  final int day;
  final String title;
  final String? matchup;
  final bool named;
  final Set<String> venue;
  late final Set<String> distinctive = _distinctive(venue);
  late final Set<String> substantive = _substantive(venue);
  final int quality;
}

_Tier _titleTier(_Row a, _Row b) {
  if (a.title.isEmpty || b.title.isEmpty) return _Tier.none;
  if (a.title == b.title) return _Tier.strong;
  if (a.matchup != null && a.matchup == b.matchup) return _Tier.strong;
  if (_isWordPrefix(a.title, b.title) || _isWordPrefix(b.title, a.title)) {
    return _Tier.near;
  }
  return _Tier.none;
}

_Tier _venueTier(_Row a, _Row b) {
  final gap = _gapMetres(a.event, b.event);
  // Coordinates outrank names in the negative: however alike two names
  // are, listings a couple of kilometres apart are not the same place.
  if (gap != null && gap > kDifferentVenueMetres) return _Tier.none;

  // Same words in any order, spelling variants unified.
  if (a.venue.isNotEmpty &&
      a.venue.length == b.venue.length &&
      a.venue.containsAll(b.venue)) {
    return _Tier.strong;
  }
  // One name inside the other ("haskins center" ⊂ "utep don haskins
  // center", "plaza theater" ⊂ "plaza theater el paso"), provided the short
  // side says something specific: a bare "community center" must not claim
  // every community center in town.
  final short = a.venue.length <= b.venue.length ? a : b;
  final long = identical(short, a) ? b : a;
  if (short.distinctive.isNotEmpty && long.venue.containsAll(short.venue)) {
    return _Tier.strong;
  }

  if (gap == null || gap > kSameVenueMetres) return _Tier.none;
  // Same spot. A side with no name at all defers to the map. Names that
  // share any real word — "haskins", or just "convention center" — are one
  // venue written two ways. Names with nothing in common ("Love Buzz" /
  // "Monarch") are neighbours, and neighbours host different nights.
  if (!a.named || !b.named) return _Tier.weak;
  if (a.substantive.intersection(b.substantive).isNotEmpty) return _Tier.weak;
  return _Tier.near;
}

bool _sameShow(_Row a, _Row b) {
  if (a.day != b.day) return false;
  final title = _titleTier(a, b);
  if (title == _Tier.none) return false;
  return switch (_venueTier(a, b)) {
    _Tier.none => false,
    // Same named place: an exact title or a prefix of it is enough.
    _Tier.strong => true,
    // Related place: the title must be exact. Two fuzzy signals do not add
    // up to one certain one.
    _Tier.weak => title == _Tier.strong,
    // Same spot, names with nothing in common: only a sports matchup is
    // specific enough to bridge that — the same two teams cannot meet twice
    // in one day two doors apart, whereas "Open Mic" at neighbouring bars
    // is two different nights.
    _Tier.near => a.matchup != null && a.matchup == b.matchup,
  };
}

/// Whether two listings describe the same show: same calendar day, same
/// title (exact, sports matchup, or one a whole-word prefix of the other)
/// and same place (same words, one name inside the other, or related names
/// at the same coordinates) — never when coordinates put them more than
/// [kDifferentVenueMetres] apart. Symmetric.
bool isSameShow(Event a, Event b) => _sameShow(_Row(a), _Row(b));

bool _hasRealImage(Event event) => !isGenericEventImage(event.imageUrl);

/// Keep the higher-quality listing but steal a real photo from the loser
/// when the winner only has stock / empty art.
Event _withBestImage(Event winner, Event loser) {
  if (_hasRealImage(winner) || !_hasRealImage(loser)) return winner;
  return winner.copyWith(imageUrl: loser.imageUrl);
}

/// The surviving row, enriched with whatever the dropped duplicate knew
/// that it did not: a real photo, or coordinates for distance sorting.
Event _absorb(Event winner, Event loser) {
  var merged = _withBestImage(winner, loser);
  if (!_hasCoords(merged) && _hasCoords(loser)) {
    merged = merged.copyWith(
      latitude: loser.latitude,
      longitude: loser.longitude,
    );
  }
  return merged;
}

int _quality(Event event) {
  var score = 0;
  // Live provider rows beat curated placeholders (official photo, real
  // ticket URL). Keyed on the id prefix, not `source`: curated seed rows
  // borrow the Ticketmaster badge but must never outrank the real listing.
  // Ticketmaster edges SeatGeek because its link is the primary box office
  // rather than a marketplace mirror of the same show.
  if (event.id.startsWith('tm_')) {
    score += 40;
  } else if (event.id.startsWith('sg_')) {
    score += 35;
  }
  if (_hasRealImage(event)) score += 30;
  if (event.sourceUrl != null && event.sourceUrl!.isNotEmpty) score += 10;
  if (event.description.length > 80) score += 5;
  if (!looksLikeStandaloneAddon(event.title)) score += 20;
  // Prefer the cleaner "Team vs Team" title over "Team vs Team - VIP Picnic".
  score += (90 - event.title.length).clamp(0, 25);
  score += event.interestedCount.clamp(0, 20);
  return score;
}

/// Drops exact id dupes and same-show listings. Prefers live ticketing
/// rows (official photos + ticket URLs) over curated placeholders, and
/// collapses the same show when two providers both list it — tolerant of
/// venue spelling, tour-name tails, accents and the away-at-home sports
/// form.
///
/// Input order does not decide the winner; row quality does. Ties keep the
/// earlier row. Output order is unspecified; callers sort.
List<Event> dedupeEvents(List<Event> events) {
  final byId = <String, Event>{};
  for (final event in events) {
    final existing = byId[event.id];
    if (existing == null) {
      byId[event.id] = event;
    } else if (_quality(event) > _quality(existing)) {
      byId[event.id] = _absorb(event, existing);
    } else {
      byId[event.id] = _absorb(existing, event);
    }
  }

  // Best rows first so a cluster's representative is always its richest
  // member; index breaks ties so results do not depend on sort stability.
  final rows = byId.values.map(_Row.new).toList(growable: false);
  final order = List<int>.generate(rows.length, (i) => i)
    ..sort((i, j) {
      final byQuality = rows[j].quality.compareTo(rows[i].quality);
      return byQuality != 0 ? byQuality : i.compareTo(j);
    });

  // Only listings on the same calendar day can be the same show, so compare
  // within day buckets rather than across the whole feed.
  final byDay = <int, List<_Row>>{};
  for (final index in order) {
    final row = rows[index];
    final reps = byDay.putIfAbsent(row.day, () => <_Row>[]);
    _Row? match;
    for (final rep in reps) {
      if (_sameShow(rep, row)) {
        match = rep;
        break;
      }
    }
    if (match == null) {
      reps.add(row);
    } else {
      match.event = _absorb(match.event, row.event);
    }
  }
  return [
    for (final reps in byDay.values)
      for (final rep in reps) rep.event,
  ];
}
