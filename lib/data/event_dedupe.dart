import '../models/event.dart';

/// Normalizes a title/venue for comparison (lowercase, letters/digits only).
String normalizeEventText(String raw) {
  var text = raw
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
      .trim();
  if (text.startsWith('the ')) text = text.substring(4);
  return text;
}

/// Same show = same day + similar title + similar venue.
String eventFingerprint(Event event) {
  final title = normalizeEventText(event.title);
  final venue = normalizeEventText(
    event.location.isNotEmpty ? event.location : event.fullLocation,
  );
  final day = DateTime(
    event.dateTime.year,
    event.dateTime.month,
    event.dateTime.day,
  ).toIso8601String();
  return '$title|$venue|$day';
}

bool _hasRealImage(Event event) {
  final url = event.imageUrl;
  if (url.isEmpty) return false;
  // Generic avatars / empty placeholders are not event photos.
  if (url.contains('ui-avatars.com')) return false;
  return true;
}

int _quality(Event event) {
  var score = 0;
  if (event.id.startsWith('tm_')) score += 40;
  if (_hasRealImage(event)) score += 30;
  if (event.sourceUrl != null && event.sourceUrl!.isNotEmpty) score += 10;
  if (event.description.length > 80) score += 5;
  score += event.interestedCount.clamp(0, 20);
  return score;
}

/// Drops exact id dupes and same-show listings. Prefers Ticketmaster rows
/// (official photos + ticket URLs) over curated placeholders.
List<Event> dedupeEvents(List<Event> events) {
  final byId = <String, Event>{};
  for (final event in events) {
    final existing = byId[event.id];
    if (existing == null || _quality(event) > _quality(existing)) {
      byId[event.id] = event;
    }
  }

  final byFingerprint = <String, Event>{};
  for (final event in byId.values) {
    final key = eventFingerprint(event);
    final existing = byFingerprint[key];
    if (existing == null || _quality(event) > _quality(existing)) {
      byFingerprint[key] = event;
    }
  }
  return byFingerprint.values.toList();
}
