import '../models/event.dart';
import 'event_images.dart';

/// Normalizes a title/venue for comparison (lowercase, letters/digits only).
String normalizeEventText(String raw) {
  var text = raw
      .toLowerCase()
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

/// "A vs B" / "A versus B" / "A @ B" → sorted team pair, or null.
String? sportsMatchupKey(String title) {
  final cleaned = stripListingNoise(title);
  final parts = cleaned.split(
    RegExp(r'\s+(?:vs\.?|versus|v\.|@)\s+', caseSensitive: false),
  );
  if (parts.length != 2) return null;
  final teams = parts.map(normalizeEventText).where((t) => t.isNotEmpty).toList()
    ..sort();
  if (teams.length != 2) return null;
  return teams.join('|');
}

/// Same show = same day + similar title/matchup + similar venue.
String eventFingerprint(Event event) {
  final venue = normalizeEventText(
    event.location.isNotEmpty ? event.location : event.fullLocation,
  );
  final day = DateTime(
    event.dateTime.year,
    event.dateTime.month,
    event.dateTime.day,
  ).toIso8601String();
  final matchup = sportsMatchupKey(event.title);
  if (matchup != null) return 'matchup:$matchup|$venue|$day';
  return '${normalizeEventText(stripListingNoise(event.title))}|$venue|$day';
}

bool _hasRealImage(Event event) => !isGenericEventImage(event.imageUrl);

/// Keep the higher-quality listing but steal a real photo from the loser
/// when the winner only has stock / empty art.
Event _withBestImage(Event winner, Event loser) {
  if (_hasRealImage(winner) || !_hasRealImage(loser)) return winner;
  return winner.copyWith(imageUrl: loser.imageUrl);
}

int _quality(Event event) {
  var score = 0;
  if (event.id.startsWith('tm_')) score += 40;
  if (_hasRealImage(event)) score += 30;
  if (event.sourceUrl != null && event.sourceUrl!.isNotEmpty) score += 10;
  if (event.description.length > 80) score += 5;
  if (!looksLikeStandaloneAddon(event.title)) score += 20;
  // Prefer the cleaner "Team vs Team" title over "Team vs Team - VIP Picnic".
  score += (90 - event.title.length).clamp(0, 25);
  score += event.interestedCount.clamp(0, 20);
  return score;
}

/// Drops exact id dupes and same-show listings. Prefers Ticketmaster rows
/// (official photos + ticket URLs) over curated placeholders.
List<Event> dedupeEvents(List<Event> events) {
  final byId = <String, Event>{};
  for (final event in events) {
    final existing = byId[event.id];
    if (existing == null) {
      byId[event.id] = event;
    } else if (_quality(event) > _quality(existing)) {
      byId[event.id] = _withBestImage(event, existing);
    } else {
      byId[event.id] = _withBestImage(existing, event);
    }
  }

  final byFingerprint = <String, Event>{};
  for (final event in byId.values) {
    final key = eventFingerprint(event);
    final existing = byFingerprint[key];
    if (existing == null) {
      byFingerprint[key] = event;
    } else if (_quality(event) > _quality(existing)) {
      byFingerprint[key] = _withBestImage(event, existing);
    } else {
      byFingerprint[key] = _withBestImage(existing, event);
    }
  }
  return byFingerprint.values.toList();
}
