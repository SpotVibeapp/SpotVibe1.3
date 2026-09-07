import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:spotvibe_app/models/event.dart';
import 'package:spotvibe_app/models/event_save.dart';
import 'package:spotvibe_app/repositories/event_repository.dart';
import 'package:spotvibe_app/providers/event_provider.dart';
import 'package:spotvibe_app/repositories/user_event_repository.dart';
import 'package:spotvibe_app/services/event_service.dart';
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
}
