import '../data/el_paso_events.dart';
import '../models/event.dart';

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
  Future<void> toggleBookmark(String eventId);
  Future<void> toggleInterested(String eventId);
}

/// Offline / test feed: curated El Paso events only. No invented national
/// listings and no "Live Music Night — City" templates.
class MockEventRepository implements EventRepository {
  List<Event> _seed() {
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day);
    return buildElPasoSeedEvents(midnight);
  }

  @override
  Future<Event?> getEventById(String id) async {
    try {
      return _seed().firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<Event>> getUpcomingEvents() async {
    return _seed();
  }

  @override
  Future<List<Event>> getEventsForLocation({
    required String city,
    required String state,
    required String zip,
  }) async {
    final key = city.toLowerCase().trim();
    if (key == kElPasoCity.toLowerCase()) {
      return _seed();
    }
    // Other cities come from Ticketmaster via EventService — never invent them.
    return const [];
  }

  @override
  Future<void> toggleBookmark(String eventId) async {}

  @override
  Future<void> toggleInterested(String eventId) async {}
}
