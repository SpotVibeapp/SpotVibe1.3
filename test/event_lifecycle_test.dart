import 'package:flutter_test/flutter_test.dart';
import 'package:spotvibe_app/models/event.dart';
import 'package:spotvibe_app/repositories/event_repository.dart';
import 'package:spotvibe_app/services/event_service.dart';

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
  Future<void> toggleBookmark(String eventId) async {}

  @override
  Future<void> toggleInterested(String eventId) async {}
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
}
