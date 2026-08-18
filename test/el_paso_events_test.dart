import 'package:flutter_test/flutter_test.dart';
import 'package:spotvibe_app/data/el_paso_events.dart';
import 'package:spotvibe_app/data/event_codec.dart';
import 'package:spotvibe_app/models/event.dart';
import 'package:spotvibe_app/repositories/event_repository.dart';
import 'package:spotvibe_app/widgets/common/source_badge.dart';

void main() {
  test('El Paso seed has unique ids at real venues', () {
    final midnight = DateTime(2026, 8, 12);
    final events = buildElPasoSeedEvents(midnight);
    expect(events.length, greaterThanOrEqualTo(15));
    expect(events.map((e) => e.id).toSet().length, events.length);
    expect(events.every((e) => e.city == 'El Paso'), isTrue);
    expect(events.every((e) => e.latitude != 0 && e.longitude != 0), isTrue);
    expect(events.any((e) => e.location.contains('Southwest University Park')),
        isTrue);
    expect(events.any((e) => e.location.contains('County Coliseum')), isTrue);
    expect(events.any((e) => e.location.contains('Plaza Theatre')), isTrue);
  });

  test('event codec round-trips an El Paso event', () {
    final original = buildElPasoSeedEvents(DateTime(2026, 8, 12)).first;
    final map = eventToMap(original);
    final restored = eventFromMap(original.id, map);
    expect(restored.id, original.id);
    expect(restored.title, original.title);
    expect(restored.city, 'El Paso');
    expect(restored.dateTime, original.dateTime);
    expect(restored.latitude, original.latitude);
    expect(map['cityKey'], 'el paso');
  });

  test('seed photos are venue files, not generic stock', () {
    final events = buildElPasoSeedEvents(DateTime(2026, 8, 12));
    expect(events.every((e) => !e.imageUrl.contains('unsplash.com')), isTrue);
    final withPhotos = events.where((e) => e.imageUrl.isNotEmpty);
    expect(
      withPhotos.every((e) =>
          e.imageUrl.startsWith('assets/venues/') ||
          e.imageUrl.contains('commons.wikimedia.org')),
      isTrue,
    );
  });

  test('mock feed is only the El Paso seed — no invented national events',
      () async {
    final repo = MockEventRepository();
    final events = await repo.getUpcomingEvents();
    final seed = buildElPasoSeedEvents(DateTime.now());
    expect(events.length, seed.length);
    expect(events.every((e) => e.city == 'El Paso'), isTrue);
    expect(events.any((e) => e.title.contains('Live Music Night')), isFalse);
    expect(events.any((e) => e.id.startsWith('evt_fb_')), isFalse);
    expect(events.any((e) => e.id.startsWith('gen_')), isFalse);

    final houston = await repo.getEventsForLocation(
      city: 'Houston',
      state: 'TX',
      zip: '77002',
    );
    expect(houston, isEmpty);
  });

  test('seed sources are honest — local or Ticketmaster only', () {
    final events = buildElPasoSeedEvents(DateTime(2026, 8, 12));
    expect(
      events.every((e) =>
          e.source == EventSource.local ||
          e.source == EventSource.ticketmaster),
      isTrue,
    );
    expect(events.every((e) => e.bookmarkedCount == 0), isTrue);
    expect(events.every((e) => e.interestedCount == 0), isTrue);
    expect(SourceBadge.isHonest(EventSource.ticketmaster), isTrue);
    expect(SourceBadge.isHonest(EventSource.facebook), isFalse);
  });
}
