import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spotvibe_app/data/geo_cells.dart';
import 'package:spotvibe_app/repositories/event_repository.dart';
import 'package:spotvibe_app/repositories/firebase_event_repository.dart';

const _elPaso = FeedArea(lat: 31.7619, lng: -106.485, radiusMiles: 40);

Map<String, dynamic> _doc({
  required String title,
  required DateTime start,
  DateTime? end,
  double lat = 0,
  double lng = 0,
  String kind = 'curated',
  String city = 'El Paso',
  String? creatorId,
}) {
  return {
    'title': title,
    'description': '',
    'dateTimeMs': start.millisecondsSinceEpoch,
    'endDateTimeMs': end?.millisecondsSinceEpoch,
    'visibleUntilMs': (end ?? start).millisecondsSinceEpoch,
    'location': 'Venue',
    'address': '',
    'city': city,
    'state': 'TX',
    'zipCode': '',
    'category': 'Music',
    'organizerName': 'Org',
    'latitude': lat,
    'longitude': lng,
    'geoCells': geoCellsFor(lat, lng),
    'kind': kind,
    'cityKey': city.toLowerCase(),
    if (creatorId != null) 'creatorId': creatorId,
  };
}

void main() {
  late FakeFirebaseFirestore db;
  late FirebaseEventRepository repo;
  final now = DateTime.utc(2026, 10, 19, 18);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    db = FakeFirebaseFirestore();
    await db.collection('meta').doc('event_seed').set({'version': 999});
    repo = FirebaseEventRepository(firestore: db, currentUid: () => null);
  });

  test('plan: geo cover plus first-party, time-only for any distance', () {
    final local = FeedQueryPlan.forArea(_elPaso);
    expect(local.queries.keys, unorderedEquals(['geo', 'firstParty']));
    expect(local.geoCells, contains('9ts'));

    final any = FeedQueryPlan.forArea(
      const FeedArea(lat: 31.76, lng: -106.48, radiusMiles: 100),
    );
    expect(any.queries.keys, ['all']);
    expect(FeedQueryPlan.forArea(null).queries.keys, ['all']);

    final city = FeedQueryPlan.forArea(_elPaso, cityKey: 'el paso');
    expect(city.queries.keys, unorderedEquals(['city', 'geo']));
  });

  test('ended events are never read; ongoing ones are', () async {
    final events = db.collection('events');
    await events
        .doc('past')
        .set(
          _doc(
            title: 'Past',
            start: now.subtract(const Duration(days: 2)),
            end: now.subtract(const Duration(days: 2, hours: -2)),
            lat: 31.76,
            lng: -106.48,
          ),
        );
    await events
        .doc('ongoing')
        .set(
          _doc(
            title: 'Ongoing',
            start: now.subtract(const Duration(hours: 1)),
            end: now.add(const Duration(hours: 2)),
            lat: 31.76,
            lng: -106.48,
          ),
        );
    final page = await repo.getFeedPage(area: _elPaso, now: now);
    expect(page.events.map((e) => e.id), ['ongoing']);
  });

  test(
    'geo bound excludes far events but keeps first-party without coords',
    () async {
      final events = db.collection('events');
      await events
          .doc('near')
          .set(
            _doc(
              title: 'Near',
              start: now.add(const Duration(days: 1)),
              lat: 31.80,
              lng: -106.40,
            ),
          );
      await events
          .doc('denver')
          .set(
            _doc(
              title: 'Denver',
              start: now.add(const Duration(days: 1)),
              lat: 39.74,
              lng: -104.99,
              city: 'Denver',
            ),
          );
      await events
          .doc('mine')
          .set(
            _doc(
              title: 'Local open mic',
              start: now.add(const Duration(days: 2)),
              kind: 'user',
              creatorId: 'u1',
            ),
          );
      final page = await repo.getFeedPage(area: _elPaso, now: now);
      expect(page.events.map((e) => e.id), unorderedEquals(['near', 'mine']));
    },
  );

  for (final area in [_elPaso, null]) {
    test(
      'pagination walks every page in end-time order (area: ${area != null})',
      () async {
        final events = db.collection('events');
        for (var i = 0; i < 7; i++) {
          await events
              .doc('e$i')
              .set(
                _doc(
                  title: 'Show $i',
                  start: now.add(Duration(hours: i + 1)),
                  lat: 31.76,
                  lng: -106.48,
                ),
              );
        }
        final seen = <String>[];
        FeedCursor? cursor;
        var pages = 0;
        do {
          final page = await repo.getFeedPage(
            area: area,
            after: cursor,
            pageSize: 3,
            now: now,
          );
          seen.addAll(page.events.map((e) => e.id));
          cursor = page.cursor;
          pages++;
          if (!page.hasMore) break;
        } while (pages < 10);
        expect(seen, ['e0', 'e1', 'e2', 'e3', 'e4', 'e5', 'e6']);
        expect(pages, 3);
      },
    );
  }

  test('city search uses cityKey and the geo cover', () async {
    final events = db.collection('events');
    await events
        .doc('lc')
        .set(
          _doc(
            title: 'Las Cruces',
            start: now.add(const Duration(days: 1)),
            city: 'Las Cruces',
            lat: 32.31,
            lng: -106.78,
          ),
        );
    await events
        .doc('ep')
        .set(
          _doc(
            title: 'El Paso, no coords',
            start: now.add(const Duration(days: 1)),
            kind: 'user',
            creatorId: 'u1',
          ),
        );
    await events
        .doc('nyc')
        .set(
          _doc(
            title: 'Elsewhere',
            start: now.add(const Duration(days: 1)),
            kind: 'user',
            city: 'New York',
            creatorId: 'u2',
          ),
        );
    final page = await repo.getFeedPage(
      area: _elPaso,
      cityKey: 'el paso',
      now: now,
    );
    expect(page.events.map((e) => e.id), unorderedEquals(['lc', 'ep']));
  });
}
