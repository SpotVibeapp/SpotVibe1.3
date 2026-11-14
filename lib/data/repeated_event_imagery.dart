import 'package:intl/intl.dart';

import '../models/event.dart';
import 'event_dedupe.dart';
import 'event_images.dart';

/// Client-side grouping for listings that would otherwise look identical
/// because they share a cover photo or the same series title and venue.
class RepeatedEventBadge {
  final String dateLabel;
  final String? timeLabel;
  final String? subtitle;
  final int moreDates;

  const RepeatedEventBadge({
    required this.dateLabel,
    this.timeLabel,
    this.subtitle,
    this.moreDates = 0,
  });

  /// Visible lines on the badge, date first.
  List<String> get lines {
    final out = <String>[dateLabel];
    if (subtitle != null && subtitle!.isNotEmpty) out.add(subtitle!);
    if (timeLabel != null && timeLabel!.isNotEmpty) out.add(timeLabel!);
    return out;
  }
}

/// Key used to detect repeated imagery across a visible list.
/// Prefers a real, non-generic image URL; otherwise falls back to the
/// normalized title plus venue so recurring and duplicate posts still match.
String repeatedImageryKey(Event event) {
  final url = event.imageUrl.trim();
  if (url.isNotEmpty && !isGenericEventImage(url)) {
    return 'img:${_normalizeImageUrl(url)}';
  }
  final title = normalizeEventText(event.title);
  if (title.isEmpty) return '';
  final venue = normalizeEventText(event.location);
  return 'series:$title|$venue';
}

String _normalizeImageUrl(String raw) {
  final uri = Uri.tryParse(raw);
  if (uri == null || !uri.hasScheme) return raw.trim().toLowerCase();
  return uri.replace(query: '', fragment: '').toString().toLowerCase();
}

/// Keys that appear on two or more visible events.
Set<String> keysWithRepeatedImagery(Iterable<Event> visible) {
  final counts = <String, int>{};
  for (final event in visible) {
    final key = repeatedImageryKey(event);
    if (key.isEmpty) continue;
    counts[key] = (counts[key] ?? 0) + 1;
  }
  return {
    for (final entry in counts.entries)
      if (entry.value >= 2) entry.key,
  };
}

List<Event> eventsInSameSeries(Event event, Iterable<Event> visible) {
  final key = repeatedImageryKey(event);
  if (key.isEmpty) return const [];
  final peers = visible.where((other) => repeatedImageryKey(other) == key).toList()
    ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
  return peers;
}

/// Badge for [event] when it shares imagery with another visible listing.
RepeatedEventBadge? repeatedEventBadgeFor(
  Event event,
  Iterable<Event> visible, {
  String? locale,
}) {
  final key = repeatedImageryKey(event);
  if (key.isEmpty) return null;
  final peers = eventsInSameSeries(event, visible);
  if (peers.length < 2) return null;
  return buildRepeatedEventBadge(event, locale: locale, seriesLength: peers.length);
}

RepeatedEventBadge buildRepeatedEventBadge(
  Event event, {
  String? locale,
  int seriesLength = 2,
}) {
  final loc = (locale == null || locale.isEmpty) ? 'en' : locale;
  final dateLabel = DateFormat('E MMM d', loc).format(event.dateTime).toUpperCase();
  final showTime = event.dateTime.hour != 0 || event.dateTime.minute != 0;
  final timeLabel = showTime ? DateFormat.jm(loc).format(event.dateTime) : null;
  final subtitle = _subtitleFor(event, locale: loc);
  return RepeatedEventBadge(
    dateLabel: dateLabel,
    timeLabel: timeLabel,
    subtitle: subtitle,
    moreDates: seriesLength > 2 ? seriesLength - 1 : 0,
  );
}

String? _subtitleFor(Event event, {required String locale}) {
  final game = parseGameNumber('${event.title} ${event.description}');
  if (game != null) {
    return locale.startsWith('es')
        ? 'Juego ${game.$1} de ${game.$2}'
        : 'Game ${game.$1} of ${game.$2}';
  }
  final opponent = parseOpponent(event.title);
  if (opponent != null && opponent.isNotEmpty) {
    return locale.startsWith('es') ? 'vs. $opponent' : 'vs. $opponent';
  }
  return null;
}

/// Parses "Game 3 of 5" / "Game 3/5" from provider or user-written text.
(int, int)? parseGameNumber(String text) {
  final match = RegExp(
    r'\bgame\s+(\d+)\s*(?:of|/)\s*(\d+)\b',
    caseSensitive: false,
  ).firstMatch(text);
  if (match == null) return null;
  final current = int.tryParse(match.group(1)!);
  final total = int.tryParse(match.group(2)!);
  if (current == null || total == null || current <= 0 || total < current) {
    return null;
  }
  return (current, total);
}

/// Parses an opponent from titles like "Chihuahuas vs. Isotopes".
String? parseOpponent(String title) {
  final match = RegExp(
    r'\s+(?:vs\.?|versus|v\.)\s+(.+)$',
    caseSensitive: false,
  ).firstMatch(title.trim());
  if (match == null) return null;
  final raw = match.group(1)!.trim();
  if (raw.isEmpty) return null;
  // Drop a trailing game/date clause if present.
  return raw.replaceFirst(RegExp(r'\s+[-(].*$'), '').trim();
}
