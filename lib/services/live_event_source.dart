import '../models/event.dart';

/// A remote catalogue of live events (Ticketmaster, SeatGeek, ...).
///
/// [EventService] fans out to every configured source, merges the results
/// with the curated/Firestore rows, and lets `dedupeEvents` collapse the
/// same show listed by more than one provider. Sources must therefore:
///
///  * prefix their ids (`tm_`, `sg_`, ...) so ids never collide;
///  * return `[]` — never throw — when unconfigured or when the network
///    fails, so one broken provider degrades to "fewer events" instead of
///    an empty feed;
///  * only return events that are still visible at the time of the call.
abstract class LiveEventSource {
  /// Which badge/filter the source's events carry.
  EventSource get source;

  /// Whether an API key was supplied at build time. Unconfigured sources
  /// are skipped without logging noise on every refresh.
  bool get isConfigured;

  /// Whether [id] was minted by this source (checked before [getEventById]
  /// so a `tm_` id is never sent to SeatGeek and vice versa).
  bool ownsId(String id);

  /// Upcoming events near a point or in a named city.
  ///
  /// Exactly one of ([lat], [lng]) or [city] is used: coordinates win when
  /// both are present. [category] is a SpotVibe category name ('Music',
  /// 'Sports', ...) that each source maps to its own taxonomy, or null for
  /// everything. [radiusMiles] only applies to coordinate searches.
  Future<List<Event>> search({
    String? city,
    String? stateCode,
    String? keyword,
    String? category,
    double? lat,
    double? lng,
    double radiusMiles = 40,
  });

  /// One event by its prefixed id, for cold-start deep links to events that
  /// were never in Firestore. Null when unknown or unconfigured.
  Future<Event?> getEventById(String id);
}
