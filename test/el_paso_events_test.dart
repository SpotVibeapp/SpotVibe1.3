import 'package:flutter_test/flutter_test.dart';
import 'package:spotvibe_app/data/el_paso_events.dart';
import 'package:spotvibe_app/data/event_codec.dart';
import 'package:spotvibe_app/repositories/event_repository.dart';

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

  test('mock default feed includes the El Paso seed', () async {
    final repo = MockEventRepository();
    final events = await repo.getUpcomingEvents();
    expect(events.any((e) => e.id == 'evt_ep_001'), isTrue);
    expect(events.any((e) => e.city == 'El Paso'), isTrue);
  });
}
