import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:spotvibe_app/models/event.dart';
import 'package:spotvibe_app/models/event_save.dart';
import 'package:spotvibe_app/repositories/event_repository.dart';
import 'package:spotvibe_app/providers/event_provider.dart';
import 'package:spotvibe_app/repositories/user_event_repository.dart';
import 'package:spotvibe_app/services/event_service.dart';
import 'package:spotvibe_app/services/live_event_source.dart';
import 'package:spotvibe_app/services/ticketmaster_service.dart';

class _FixedEventRepository implements EventRepository {
  final List<Event> events;

  _FixedEventRepository(this.events);

  @override
  Future<Event?> getEventById(String id) async {
    for (final event in events) {
      if (event.id == id) return event;
    }
    return null;
  }

  @override
  Future<List<Event>> getEventsForLocation({
    required String city,
    required String state,
    required String zip,
  }) async => events;

  @override
  Future<List<Event>> getUpcomingEvents() async => events;

  @override
  Future<Map<String, EventSave>> getSaves() async => {};

  @override
  Future<void> setSave(
    String eventId, {
    required bool bookmarked,
    required bool interested,
  }) async {}
}

class _ControlledEventRepository implements EventRepository {
  final Completer<void> cityRequested = Completer<void>();
  final Completer<void> allRequested = Completer<void>();
  final Completer<List<Event>> cityResults = Completer<List<Event>>();
  final Completer<List<Event>> allResults = Completer<List<Event>>();

  @override
  Future<Event?> getEventById(String id) async => null;

  @override
  Future<List<Event>> getEventsForLocation({
    required String city,
    required String state,
    required String zip,
  }) {
    if (!cityRequested.isCompleted) cityRequested.complete();
    return cityResults.future;
  }

  @override
  Future<List<Event>> getUpcomingEvents() {
    if (!allRequested.isCompleted) allRequested.complete();
    return allResults.future;
  }

  @override
  Future<Map<String, EventSave>> getSaves() async => {};

  @override
  Future<void> setSave(
    String eventId, {
    required bool bookmarked,
    required bool interested,
  }) async {}
}

/// A scripted live provider: hands back [results] (or throws [error]) and
/// records what it was asked, so tests can pin the fan-out contract.
class _FakeLiveSource implements LiveEventSource {
  _FakeLiveSource(
    this.source, {
    required this.prefix,
    this.results = const [],
    this.error,
    this.configured = true,
  });

  @override
  final EventSource source;
  final String prefix;
  final List<Event> results;
  final Object? error;
  final bool configured;
  int searchCalls = 0;
  int lookupCalls = 0;

  @override
  bool get isConfigured => configured;

  @override
  bool ownsId(String id) => id.startsWith(prefix);

  @override
  Future<List<Event>> search({
    String? city,
    String? stateCode,
    String? keyword,
    String? category,
    double? lat,
    double? lng,
    double radiusMiles = 40,
  }) async {
    searchCalls++;
    if (error != null) throw error!;
    return results;
  }

  @override
  Future<Event?> getEventById(String id) async {
    lookupCalls++;
    if (error != null) throw error!;
    for (final event in results) {
      if (event.id == id) return event;
    }
    return null;
  }
}

/// A live-provider row: same title/venue/day as another provider's row
/// means the same show, which dedupe must collapse.
Event _liveEvent({
  required String id,
  required EventSource source,
  required DateTime startsAt,
  String title = 'Khruangbin',
  String venue = 'Abraham Chavez Theatre',
}) {
  return Event(
    id: id,
    title: title,
    description: '$title at $venue.',
    dateTime: startsAt,
    endDateTime: startsAt.add(const Duration(hours: 3)),
    location: venue,
    address: '1 Civic Center Plaza',
    city: 'El Paso',
    state: 'TX',
    imageUrl: '',
    isTicketed: true,
    category: 'Music',
    organizerName: venue,
    organizerAvatarUrl: '',
    latitude: 31.7574,
    longitude: -106.4907,
    source: source,
    sourceUrl: 'https://example.test/$id',
  );
}

Event _event({
  required String id,
  required DateTime startsAt,
  DateTime? endsAt,
}) {
  return Event(
    id: id,
    title: 'Real event $id',
    description: 'A real listing used to test event timing.',
    dateTime: startsAt,
    endDateTime: endsAt,
    location: 'Test Venue',
    address: '1 Main Street',
    city: 'El Paso',
    state: 'TX',
    imageUrl: '',
    category: 'Music',
    organizerName: 'Test Organizer',
    organizerAvatarUrl: '',
  );
}

void main() {
  test('active feed retains an event that is currently happening', () async {
    final now = DateTime.now();
    final live = _event(
      id: 'live',
      startsAt: now.subtract(const Duration(hours: 1)),
      endsAt: now.add(const Duration(hours: 2)),
    );
    final service = EventService(repository: _FixedEventRepository([live]));

    final events = await service.getUpcomingEvents();

    expect(events, [live]);
    expect(live.isHappeningNow, isTrue);
  });

  test('main search routes a recognized city to real location search', () {
    final service = EventService(repository: _FixedEventRepository(const []));
    final provider = EventProvider(service: service);

    provider.search('Dallas');

    expect(provider.areaQuery, 'Dallas');
    expect(provider.searchQuery, isEmpty);

    provider.search('jazz');
    expect(provider.areaQuery, isEmpty);
    expect(provider.searchQuery, 'jazz');

    expect(service.isRecognizedLocationQuery('Dallas Mavericks'), isFalse);
    expect(service.isRecognizedLocationQuery('Dallas, TX'), isTrue);
  });

  test('a slower old city lookup cannot replace the newest search', () async {
    final now = DateTime.now();
    final cityEvent = _event(
      id: 'dallas-result',
      startsAt: now.add(const Duration(days: 2)),
      endsAt: now.add(const Duration(days: 2, hours: 2)),
    );
    final keywordEvent = _event(
      id: 'jazz-result',
      startsAt: now.add(const Duration(days: 3)),
      endsAt: now.add(const Duration(days: 3, hours: 2)),
    ).copyWith(title: 'Jazz festival');
    final repository = _ControlledEventRepository();
    final provider = EventProvider(
      service: EventService(repository: repository),
    );

    provider.search('Dallas');
    await repository.cityRequested.future;
    provider.search('jazz');
    await repository.allRequested.future;

    repository.allResults.complete([keywordEvent]);
    await Future<void>.delayed(const Duration(milliseconds: 10));
    repository.cityResults.complete([cityEvent]);
    await Future<void>.delayed(const Duration(milliseconds: 10));

    expect(provider.events.map((event) => event.id), ['jazz-result']);
    expect(provider.isLoading, isFalse);
    provider.dispose();
  });

  test('explicit city searches ignore the device’s local radius', () async {
    final startsAt = DateTime.now().add(const Duration(days: 2));
    final dallas = _event(
      id: 'dallas-city-search',
      startsAt: startsAt,
      endsAt: startsAt.add(const Duration(hours: 2)),
    ).copyWith(
      city: 'Dallas',
      state: 'TX',
      latitude: 32.7767,
      longitude: -96.7970,
    );
    final service = EventService(repository: _FixedEventRepository([dallas]));

    final events = await service.getUpcomingEvents(
      areaQuery: 'Dallas',
      userLat: 31.7619,
      userLng: -106.4850,
      searchRadius: 25,
      sortByDistance: true,
    );

    expect(events, [dallas]);
  });

  test('city-and-state searches resolve the assistant location label', () async {
    final startsAt = DateTime.now().add(const Duration(days: 2));
    final elPaso = _event(
      id: 'el-paso-search',
      startsAt: startsAt,
      endsAt: startsAt.add(const Duration(hours: 2)),
    );
    final service = EventService(repository: _FixedEventRepository([elPaso]));

    final events = await service.getUpcomingEvents(areaQuery: 'El Paso, TX');

    expect(events, [elPaso]);
  });

  test('active feed removes events after their explicit end time', () async {
    final now = DateTime.now();
    final finished = _event(
      id: 'finished',
      startsAt: now.subtract(const Duration(hours: 3)),
      endsAt: now.subtract(const Duration(minutes: 1)),
    );
    final service = EventService(repository: _FixedEventRepository([finished]));

    expect(await service.getUpcomingEvents(), isEmpty);
    expect(finished.isHappeningNow, isFalse);
  });

  test('legacy started events do not pretend to be live without an end time',
      () async {
    final legacy = _event(
      id: 'legacy',
      startsAt: DateTime.now().subtract(const Duration(hours: 1)),
    );
    final service = EventService(repository: _FixedEventRepository([legacy]));

    expect(await service.getUpcomingEvents(), isEmpty);
  });

  test('renaming an organizer updates only that creator’s own events', () async {
    final repository = UserEventRepository();
    final start = DateTime.now().add(const Duration(days: 3));
    final mine = await repository.createEvent(
      creatorId: 'spotvibe-admin',
      title: 'Official listing',
      description: 'A real event listed by the company.',
      dateTime: start,
      endDateTime: start.add(const Duration(hours: 3)),
      location: 'Community Hall',
      address: '1 Main Street',
      category: 'Community',
      organizerName: 'Blake',
    );
    final other = await repository.createEvent(
      creatorId: 'another-organizer',
      title: 'Other listing',
      description: 'A real event listed by a different organizer.',
      dateTime: start,
      endDateTime: start.add(const Duration(hours: 3)),
      location: 'Community Hall',
      address: '1 Main Street',
      category: 'Community',
      organizerName: 'Another organizer',
    );

    final renamed = await repository.updateOrganizerNameForCreator(
      'spotvibe-admin',
      'SpotVibe',
    );

    expect(renamed, 1);
    expect((await repository.getEventById(mine.id))!.organizerName, 'SpotVibe');
    expect(
      (await repository.getEventById(other.id))!.organizerName,
      'Another organizer',
    );
  });

  group('ticketmasterRadiusForFeed', () {
    test('passes an ordinary slider value straight through', () {
      expect(ticketmasterRadiusForFeed(5), 5);
      expect(ticketmasterRadiusForFeed(25), 25);
      expect(ticketmasterRadiusForFeed(60), 60);
      expect(ticketmasterRadiusForFeed(99.9), 99.9);
    });

    test('"any distance" (100) fetches the widest radius the API allows',
        () {
      expect(ticketmasterRadiusForFeed(100), kTicketmasterMaxRadiusMiles);
      expect(ticketmasterRadiusForFeed(150), kTicketmasterMaxRadiusMiles);
    });

    test('garbage falls back to the default pull radius', () {
      expect(ticketmasterRadiusForFeed(0), kDefaultTicketmasterRadiusMiles);
      expect(ticketmasterRadiusForFeed(-1), kDefaultTicketmasterRadiusMiles);
      expect(
        ticketmasterRadiusForFeed(double.nan),
        kDefaultTicketmasterRadiusMiles,
      );
    });
  });
  group('multi-source live listings', () {
    // Noon, five days out: far enough to be upcoming, and a 30-minute
    // offset can never roll the fingerprint onto another day.
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day + 5, 12);

    test('the same show from two providers collapses to one row, TM wins',
        () async {
      final tmRow = _liveEvent(
        id: 'tm_G5vABC',
        source: EventSource.ticketmaster,
        startsAt: start,
      );
      final sgRow = _liveEvent(
        id: 'sg_6162405',
        source: EventSource.seatgeek,
        startsAt: start.add(const Duration(minutes: 30)),
      );
      final service = EventService(
        repository: _FixedEventRepository(const []),
        sources: [
          // SeatGeek first on purpose: order must not decide the winner.
          _FakeLiveSource(EventSource.seatgeek,
              prefix: 'sg_', results: [sgRow]),
          _FakeLiveSource(EventSource.ticketmaster,
              prefix: 'tm_', results: [tmRow]),
        ],
      );

      final events = await service.getUpcomingEvents(
        userLat: 31.7619,
        userLng: -106.485,
        searchRadius: 25,
      );

      expect(events.map((e) => e.id), ['tm_G5vABC']);
      expect(events.single.source, EventSource.ticketmaster);
    });

    test('different shows from different providers are all kept', () async {
      final service = EventService(
        repository: _FixedEventRepository(const []),
        sources: [
          _FakeLiveSource(EventSource.ticketmaster, prefix: 'tm_', results: [
            _liveEvent(
              id: 'tm_1',
              source: EventSource.ticketmaster,
              startsAt: start,
              title: 'Sun Bowl Parade',
            ),
          ]),
          _FakeLiveSource(EventSource.seatgeek, prefix: 'sg_', results: [
            _liveEvent(
              id: 'sg_1',
              source: EventSource.seatgeek,
              startsAt: start,
              title: 'El Paso Chihuahuas vs Round Rock Express',
              venue: 'Southwest University Park',
            ),
          ]),
        ],
      );

      final events = await service.getUpcomingEvents(
        userLat: 31.7619,
        userLng: -106.485,
        searchRadius: 25,
      );

      expect(events.map((e) => e.id).toSet(), {'tm_1', 'sg_1'});
    });

    test('one provider throwing still leaves the others on the feed',
        () async {
      final good = _FakeLiveSource(EventSource.seatgeek, prefix: 'sg_', results: [
        _liveEvent(id: 'sg_ok', source: EventSource.seatgeek, startsAt: start),
      ]);
      final bad = _FakeLiveSource(
        EventSource.ticketmaster,
        prefix: 'tm_',
        error: StateError('ticketmaster is down'),
      );
      final curated = _event(
        id: 'curated',
        startsAt: start,
        endsAt: start.add(const Duration(hours: 2)),
      );
      final service = EventService(
        repository: _FixedEventRepository([curated]),
        sources: [bad, good],
      );

      final events = await service.getUpcomingEvents();

      expect(bad.searchCalls, 1);
      expect(good.searchCalls, 1);
      expect(events.map((e) => e.id).toSet(), {'curated', 'sg_ok'});
    });

    test('every provider failing degrades to the curated feed, not a crash',
        () async {
      final curated = _event(
        id: 'curated',
        startsAt: start,
        endsAt: start.add(const Duration(hours: 2)),
      );
      final service = EventService(
        repository: _FixedEventRepository([curated]),
        sources: [
          _FakeLiveSource(EventSource.ticketmaster,
              prefix: 'tm_', error: Exception('boom')),
          _FakeLiveSource(EventSource.seatgeek,
              prefix: 'sg_', error: Exception('boom')),
        ],
      );

      expect(
        (await service.getUpcomingEvents()).map((e) => e.id),
        ['curated'],
      );
    });

    test('unconfigured providers are never called', () async {
      final idle = _FakeLiveSource(
        EventSource.seatgeek,
        prefix: 'sg_',
        configured: false,
        results: [
          _liveEvent(id: 'sg_x', source: EventSource.seatgeek, startsAt: start),
        ],
      );
      final service = EventService(
        repository: _FixedEventRepository(const []),
        sources: [idle],
      );

      expect(await service.getUpcomingEvents(), isEmpty);
      expect(idle.searchCalls, 0);
    });

    test('rows a provider does not own are dropped before merging', () async {
      final lying = _FakeLiveSource(EventSource.seatgeek, prefix: 'sg_', results: [
        _liveEvent(id: 'sg_mine', source: EventSource.seatgeek, startsAt: start),
        _liveEvent(
          id: 'tm_not_mine',
          source: EventSource.ticketmaster,
          startsAt: start,
          title: 'Something else',
        ),
      ]);
      final service = EventService(
        repository: _FixedEventRepository(const []),
        sources: [lying],
      );

      final events = await service.getUpcomingEvents();

      expect(events.map((e) => e.id), ['sg_mine']);
    });

    test('the legacy ticketmaster: parameter still wires a single source',
        () async {
      final service = EventService(
        repository: _FixedEventRepository(const []),
        ticketmaster: TicketmasterService(apiKey: ''),
      );

      expect(service.liveSourceKinds, [EventSource.ticketmaster]);
      // Unconfigured, so it contributes nothing and hits no network.
      expect(await service.getUpcomingEvents(), isEmpty);
    });

    group('getEventById dispatch', () {
      test('routes each prefix to the provider that owns it', () async {
        final tm = _FakeLiveSource(EventSource.ticketmaster, prefix: 'tm_', results: [
          _liveEvent(id: 'tm_1', source: EventSource.ticketmaster, startsAt: start),
        ]);
        final sg = _FakeLiveSource(EventSource.seatgeek, prefix: 'sg_', results: [
          _liveEvent(id: 'sg_1', source: EventSource.seatgeek, startsAt: start),
        ]);
        final service = EventService(
          repository: _FixedEventRepository(const []),
          sources: [tm, sg],
        );

        expect((await service.getEventById('sg_1'))?.id, 'sg_1');
        expect(tm.lookupCalls, 0);
        expect(sg.lookupCalls, 1);

        expect((await service.getEventById('tm_1'))?.id, 'tm_1');
        expect(tm.lookupCalls, 1);
        expect(sg.lookupCalls, 1);

        expect(await service.getEventById('evt_ep_9'), isNull);
        expect(tm.lookupCalls, 1);
        expect(sg.lookupCalls, 1);
      });

      test('the repository wins over live providers', () async {
        final local = _event(
          id: 'sg_local_copy',
          startsAt: start,
          endsAt: start.add(const Duration(hours: 1)),
        );
        final sg = _FakeLiveSource(EventSource.seatgeek, prefix: 'sg_', results: [
          _liveEvent(id: 'sg_local_copy', source: EventSource.seatgeek, startsAt: start),
        ]);
        final service = EventService(
          repository: _FixedEventRepository([local]),
          sources: [sg],
        );

        expect(await service.getEventById('sg_local_copy'), same(local));
        expect(sg.lookupCalls, 0);
      });

      test('a provider throwing on lookup yields null for the not-found screen',
          () async {
        final service = EventService(
          repository: _FixedEventRepository(const []),
          sources: [
            _FakeLiveSource(EventSource.seatgeek,
                prefix: 'sg_', error: Exception('offline')),
          ],
        );

        expect(await service.getEventById('sg_404'), isNull);
      });
    });
  });
}
