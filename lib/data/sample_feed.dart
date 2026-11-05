import '../models/event.dart';
import 'el_paso_events.dart';

/// Bundled placeholder events for a cold or empty feed.
///
/// These are the curated El Paso rows already shipped in the app, marked
/// [Event.isSample] so the UI can label them. Nothing here is written to
/// Firestore. Callers show them only after an explicit opt-in, or when a
/// Firestore read has already failed and the repository is on its offline
/// fallback.
List<Event> buildSampleFeedEvents(DateTime now) {
  final midnight = DateTime(now.year, now.month, now.day);
  return [
    for (final event in buildElPasoSeedEvents(midnight))
      event.copyWith(isSample: true),
  ];
}

/// How the home feed should treat an empty live result and any sample rows
/// a failed Firestore read already returned.
///
/// [optIn] is the person's choice: `null` leaves live rows alone and does
/// not invent a feed, `true` fills a quiet home feed with samples, `false`
/// strips samples (including the offline fallback).
class SampleFeedDecision {
  const SampleFeedDecision({required this.events, required this.showingSamples});

  final List<Event> events;
  final bool showingSamples;
}

SampleFeedDecision applySampleFeed({
  required List<Event> loaded,
  required bool? optIn,
  required bool homeFeed,
  required List<Event> samples,
}) {
  var events = loaded;
  if (optIn == false) {
    events = events.where((event) => !event.isSample).toList(growable: false);
  } else if (events.isEmpty && optIn == true && homeFeed) {
    events = samples;
  }
  final showingSamples =
      events.isNotEmpty && events.every((event) => event.isSample);
  return SampleFeedDecision(events: events, showingSamples: showingSamples);
}
