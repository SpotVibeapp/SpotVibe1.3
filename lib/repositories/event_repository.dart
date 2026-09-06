import '../data/el_paso_events.dart';
import '../models/event.dart';
import '../models/event_save.dart';
import 'local_saves_store.dart';

/// Data-source contract for the public event feed.
///
/// - [FirebaseEventRepository] — Firestore + El Paso seed (production)
/// - [MockEventRepository] — in-memory curated El Paso events only
///
/// Live Ticketmaster listings are merged in [EventService], not here.
abstract class EventRepository {
  Future<Event?> getEventById(String id);
  Future<List<Event>> getUpcomingEvents();
  Future<List<Event>> getEventsForLocation({
    required String city,
    required String state,
    required String zip,
  });

  /// The user's bookmark / interested flags, keyed by event id.
  ///
  /// Backed by Firestore for signed-in users (with a device-local offline
  /// overlay) and by SharedPreferences for guests — so saves survive feed
  /// refreshes, app restarts, and offline usage in every configuration.
  Future<Map<String, EventSave>> getSaves();

  /// Persists the bookmark / interested flags for [eventId].
  ///
  /// Writing the desired state (instead of a blind toggle) keeps the local
  /// optimistic copy and the remote store from ever diverging.
  Future<void> setSave(
    String eventId, {
    required bool bookmarked,
    required bool interested,
  });
}

/// Offline / test feed: curated El Paso events only. No invented national
/// listings and no "Live Music Night — City" templates.
///
/// Bookmarks / interested flags persist to SharedPreferences so they survive
/// feed refreshes and app restarts even without a backend (guests, tests).
class MockEventRepository implements EventRepository {
  final LocalSavesStore _saves = LocalSavesStore();

  List<Event> _seed() {
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day);
    return buildElPasoSeedEvents(midnight);
  }

  Future<List<Event>> _applySaves(List<Event> events) async {
    if (events.isEmpty) return events;
    final Map<String, EventSave> saves;
    try {
      saves = await _saves.load();
    } catch (_) {
      return events; // never break the feed over a save-overlay failure
    }
    if (saves.isEmpty) return events;
    return events
        .map((e) {
          final s = saves[e.id];
          if (s == null) return e;
          return s.applyTo(e);
        })
        .toList();
  }

  @override
  Future<Event?> getEventById(String id) async {
    Event match;
    try {
      match = _seed().firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
    return (await _applySaves([match])).first;
  }

  @override
  Future<List<Event>> getUpcomingEvents() async {
    return _applySaves(_seed());
  }

  @override
  Future<List<Event>> getEventsForLocation({
    required String city,
    required String state,
    required String zip,
  }) async {
    final key = city.toLowerCase().trim();
    if (key == kElPasoCity.toLowerCase()) {
      return _applySaves(_seed());
    }
    // Other cities come from Ticketmaster via EventService — never invent them.
    return const [];
  }

  @override
  Future<Map<String, EventSave>> getSaves() => _saves.load();

  @override
  Future<void> setSave(
    String eventId, {
    required bool bookmarked,
    required bool interested,
  }) {
    if (bookmarked || interested) {
      return _saves.set(eventId, bookmarked: bookmarked, interested: interested);
    }
    return _saves.remove(eventId);
  }
}
