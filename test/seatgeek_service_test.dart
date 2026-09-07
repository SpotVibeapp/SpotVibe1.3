import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spotvibe_app/models/event.dart';
import 'package:spotvibe_app/services/live_event_source.dart';
import 'package:spotvibe_app/services/seatgeek_service.dart';

/// Serves canned SeatGeek pages keyed by the `page` query param and records
/// every request. Paths ending in a numeric id return a single document.
class _FakeSeatGeekAdapter implements HttpClientAdapter {
  _FakeSeatGeekAdapter(
    this.pages, {
    this.failPages = const {},
    this.singles = const {},
    this.failAll = false,
  });

  /// page number (1-indexed) -> event JSON objects.
  final Map<int, List<Map<String, dynamic>>> pages;
  final Set<int> failPages;

  /// SeatGeek numeric id -> single event JSON.
  final Map<String, Map<String, dynamic>> singles;
  final bool failAll;
  final List<Uri> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options.uri);
    if (failAll) {
      return ResponseBody.fromString('{"status":500}', 500,
          headers: {Headers.contentTypeHeader: ['application/json']});
    }
    final last = options.uri.pathSegments.last;
    if (int.tryParse(last) != null) {
      final single = singles[last];
      if (single == null) {
        return ResponseBody.fromString('{"status":404}', 404,
            headers: {Headers.contentTypeHeader: ['application/json']});
      }
      return ResponseBody.fromString(jsonEncode(single), 200,
          headers: {Headers.contentTypeHeader: ['application/json']});
    }
    final page = int.parse(options.uri.queryParameters['page'] ?? '1');
    if (failPages.contains(page)) {
      return ResponseBody.fromString('{"status":500}', 500,
          headers: {Headers.contentTypeHeader: ['application/json']});
    }
    final events = pages[page] ?? const <Map<String, dynamic>>[];
    final body = <String, dynamic>{
      'meta': {'total': events.length, 'per_page': 100, 'page': page},
      'events': events,
    };
    return ResponseBody.fromString(jsonEncode(body), 200,
        headers: {Headers.contentTypeHeader: ['application/json']});
  }

  @override
  void close({bool force = false}) {}
}

/// A minimal future SeatGeek listing; [n] keeps ids and titles unique.
Map<String, dynamic> _listing(int n) => {
      'id': 6000000 + n,
      'title': 'SeatGeek show $n',
      'datetime_utc': '2027-01-02T02:00:00',
      'venue': {'name': 'Venue $n', 'city': 'El Paso', 'state': 'TX'},
    };

SeatGeekService _serviceWith(_FakeSeatGeekAdapter adapter) {
  final dio = Dio()..httpClientAdapter = adapter;
  return SeatGeekService(
    dio: dio,
    clientId: 'test-client',
    clock: () => DateTime.utc(2026, 9, 7, 12),
  );
}

void main() {
  test('SeatGeekService is a LiveEventSource that owns sg_ ids', () {
    final service = SeatGeekService(clientId: 'x');
    expect(service, isA<LiveEventSource>());
    expect(service.source, EventSource.seatgeek);
    expect(service.isConfigured, isTrue);
    expect(service.ownsId('sg_123'), isTrue);
    expect(service.ownsId('tm_123'), isFalse);
    expect(service.ownsId('evt_ep_1'), isFalse);
  });

  test('without a client id the source is unconfigured and returns nothing',
      () async {
    final adapter = _FakeSeatGeekAdapter({1: [_listing(1)]});
    final dio = Dio()..httpClientAdapter = adapter;
    final service = SeatGeekService(dio: dio, clientId: '');

    expect(service.isConfigured, isFalse);
    expect(await service.search(lat: 31.76, lng: -106.48), isEmpty);
    expect(await service.getEventById('sg_6000001'), isNull);
    expect(adapter.requests, isEmpty, reason: 'no key → no network');
  });

  group('taxonomy and range helpers', () {
    test('map the SpotVibe categories that have a clean SeatGeek equivalent',
        () {
      expect(seatGeekTaxonomyFor('Music'), 'concert');
      expect(seatGeekTaxonomyFor('Sports'), 'sports');
      expect(seatGeekTaxonomyFor('Arts'), 'theater');
      expect(seatGeekTaxonomyFor('Fun & Games'), 'comedy');
      expect(seatGeekTaxonomyFor('Food'), isNull);
      expect(seatGeekTaxonomyFor('All'), isNull);
      expect(seatGeekTaxonomyFor(null), isNull);
    });

    test('range is whole miles clamped to the shared ceiling', () {
      expect(seatGeekRangeParam(25), '25mi');
      expect(seatGeekRangeParam(0.2), '1mi');
      expect(seatGeekRangeParam(0), '1mi');
      expect(seatGeekRangeParam(150.6), '151mi');
      expect(seatGeekRangeParam(500), '${kSeatGeekMaxRadiusMiles.round()}mi');
      expect(seatGeekRangeParam(double.infinity), '1mi');
    });
  });

  group('search', () {
    test('sends geo, range, taxonomy, keyword and a UTC lower bound',
        () async {
      final adapter = _FakeSeatGeekAdapter({1: [_listing(1)]});
      final service = _serviceWith(adapter);

      final events = await service.search(
        lat: 31.7619,
        lng: -106.485,
        radiusMiles: 60,
        category: 'Music',
        keyword: 'jazz',
      );

      expect(events, hasLength(1));
      expect(adapter.requests, hasLength(1));
      final q = adapter.requests.single.queryParameters;
      expect(adapter.requests.single.host, 'api.seatgeek.com');
      expect(adapter.requests.single.path, '/2/events');
      expect(q['client_id'], 'test-client');
      expect(q['lat'], '31.7619');
      expect(q['lon'], '-106.4850');
      expect(q['range'], '60mi');
      expect(q['taxonomies.name'], 'concert');
      expect(q['q'], 'jazz');
      expect(q['per_page'], '$kSeatGeekPageSize');
      expect(q['sort'], 'datetime_utc.asc');
      // The injected clock, no zone suffix (SeatGeek's format).
      expect(q['datetime_utc.gte'], '2026-09-07T12:00:00');
      expect(q['page'], '1');
    });

    test('falls back to venue.city/state when no coordinates are given',
        () async {
      final adapter = _FakeSeatGeekAdapter({1: [_listing(1)]});
      final service = _serviceWith(adapter);

      await service.search(city: 'Las Cruces', stateCode: 'NM');

      final q = adapter.requests.single.queryParameters;
      expect(q['venue.city'], 'Las Cruces');
      expect(q['venue.state'], 'NM');
      expect(q.containsKey('lat'), isFalse);
      expect(q.containsKey('range'), isFalse);
    });

    test('does nothing when it has neither coordinates nor a city', () async {
      final adapter = _FakeSeatGeekAdapter({1: [_listing(1)]});
      final service = _serviceWith(adapter);

      expect(await service.search(keyword: 'anything'), isEmpty);
      expect(adapter.requests, isEmpty);
    });

    test('stops after a short page without asking for the next one',
        () async {
      final full = List.generate(kSeatGeekPageSize, _listing);
      final adapter = _FakeSeatGeekAdapter({
        1: full,
        2: [_listing(9001)],
        3: [_listing(9002)],
      });
      final service = _serviceWith(adapter);

      final events = await service.search(lat: 31.76, lng: -106.48);

      expect(events, hasLength(kSeatGeekPageSize + 1));
      expect(
        adapter.requests.map((u) => u.queryParameters['page']),
        ['1', '2'],
        reason: 'page 2 was short, so page 3 is never requested',
      );
    });

    test('stops at maxPages even when every page is full', () async {
      List<Map<String, dynamic>> fullPage(int offset) => List.generate(
            kSeatGeekPageSize,
            (i) => _listing(offset + i),
          );
      final adapter = _FakeSeatGeekAdapter({
        1: fullPage(0),
        2: fullPage(1000),
        3: fullPage(2000),
        4: fullPage(3000),
      });
      final service = _serviceWith(adapter);

      final events = await service.search(lat: 31.76, lng: -106.48);

      expect(events, hasLength(kSeatGeekPageSize * kSeatGeekMaxPages));
      expect(
        adapter.requests.map((u) => u.queryParameters['page']),
        ['1', '2', '3'],
      );
    });

    test('a later page failing keeps the earlier pages', () async {
      final full = List.generate(kSeatGeekPageSize, _listing);
      final adapter = _FakeSeatGeekAdapter({1: full}, failPages: {2});
      final service = _serviceWith(adapter);

      final events = await service.search(lat: 31.76, lng: -106.48);

      expect(events, hasLength(kSeatGeekPageSize));
    });

    test('a failing first page yields an empty list, never a throw', () async {
      final adapter = _FakeSeatGeekAdapter({}, failAll: true);
      final service = _serviceWith(adapter);

      expect(await service.search(lat: 31.76, lng: -106.48), isEmpty);
    });

    test('skips past shows, TBD dates and standalone add-ons', () async {
      final adapter = _FakeSeatGeekAdapter({
        1: [
          _listing(1),
          {..._listing(2), 'datetime_utc': '2020-01-01T02:00:00'},
          {..._listing(3), 'date_tbd': true},
          {..._listing(4), 'title': 'Parking'},
          {..._listing(5), 'title': ''},
        ],
      });
      final service = _serviceWith(adapter);

      final events = await service.search(lat: 31.76, lng: -106.48);

      expect(events.map((e) => e.id), ['sg_6000001']);
    });
  });

  group('eventFromSeatGeek', () {
    test('maps a full document to a ticketed SeatGeek event', () {
      final event = eventFromSeatGeek({
        'id': 6162405,
        'title': 'Khruangbin',
        'url': 'https://seatgeek.com/khruangbin-tickets/6162405',
        'type': 'concert',
        'datetime_utc': '2026-10-15T02:00:00',
        'datetime_local': '2026-10-14T20:00:00',
        'time_tbd': false,
        'date_tbd': false,
        'taxonomies': [
          {'id': 2000000, 'name': 'concert', 'parent_id': null},
        ],
        'performers': [
          {
            'name': 'Khruangbin',
            'primary': true,
            'image': 'https://seatgeek.com/images/performers/khruangbin/huge.jpg',
            'images': {
              'huge': 'https://seatgeek.com/images/performers/khruangbin/huge.jpg',
            },
          },
        ],
        'venue': {
          'name': 'Abraham Chavez Theatre',
          'address': '1 Civic Center Plaza',
          'city': 'El Paso',
          'state': 'TX',
          'postal_code': '79901',
          'location': {'lat': 31.7574, 'lon': -106.4907},
        },
        'stats': {'lowest_price': null, 'average_price': null},
      })!;

      expect(event.id, 'sg_6162405');
      expect(event.title, 'Khruangbin');
      expect(event.source, EventSource.seatgeek);
      expect(event.sourceUrl, 'https://seatgeek.com/khruangbin-tickets/6162405');
      expect(event.isTicketed, isTrue);
      expect(event.cost, isNull, reason: 'stats prices are not trusted');
      expect(event.category, 'Music');
      expect(event.location, 'Abraham Chavez Theatre');
      expect(event.address, '1 Civic Center Plaza');
      expect(event.city, 'El Paso');
      expect(event.state, 'TX');
      expect(event.zipCode, '79901');
      expect(event.latitude, closeTo(31.7574, 1e-6));
      expect(event.longitude, closeTo(-106.4907, 1e-6));
      expect(event.imageUrl,
          'https://seatgeek.com/images/performers/khruangbin/huge.jpg');
      expect(event.organizerName, 'Abraham Chavez Theatre');
      // datetime_utc is read as UTC and converted to local.
      expect(event.dateTime.toUtc(), DateTime.utc(2026, 10, 15, 2));
    });

    test('reads a positive lowest_price when SeatGeek does publish one', () {
      final event = eventFromSeatGeek({
        ..._listing(7),
        'stats': {'lowest_price': 42},
      })!;
      expect(event.cost, 42.0);
    });

    test('classifies sports and comedy from taxonomies', () {
      final sports = eventFromSeatGeek({
        ..._listing(8),
        'type': 'minor_league_baseball',
        'taxonomies': [
          {'name': 'sports'},
          {'name': 'baseball'},
        ],
      })!;
      final comedy = eventFromSeatGeek({
        ..._listing(9),
        'type': 'comedy',
        'taxonomies': [
          {'name': 'comedy'},
        ],
      })!;
      expect(sports.category, 'Sports');
      expect(comedy.category, 'Fun & Games');
    });

    test('returns null for documents that cannot be shown honestly', () {
      expect(eventFromSeatGeek({'title': 'No id'}), isNull);
      expect(eventFromSeatGeek({'id': 1, 'title': ''}), isNull);
      expect(
        eventFromSeatGeek({'id': 2, 'title': 'No date'}),
        isNull,
      );
      expect(
        eventFromSeatGeek({
          'id': 3,
          'title': 'Date TBD',
          'datetime_utc': '2027-01-01T03:30:00',
          'date_tbd': true,
        }),
        isNull,
      );
    });

    test('a TBD time keeps the date and says so in the description', () {
      final event = eventFromSeatGeek({
        ..._listing(10),
        'datetime_utc': '2027-03-04T09:30:00',
        'time_tbd': true,
      })!;
      expect(event.description, contains('Start time to be announced'));
    });
  });

  group('getEventById', () {
    test('fetches a single sg_ event and caches it', () async {
      final adapter = _FakeSeatGeekAdapter({}, singles: {
        '6000042': _listing(42),
      });
      final service = _serviceWith(adapter);

      final first = await service.getEventById('sg_6000042');
      final second = await service.getEventById('sg_6000042');

      expect(first?.id, 'sg_6000042');
      expect(second?.id, 'sg_6000042');
      expect(adapter.requests, hasLength(1), reason: 'second hit is cached');
      expect(adapter.requests.single.path, '/2/events/6000042');
      expect(adapter.requests.single.queryParameters['client_id'],
          'test-client');
    });

    test('refuses ids it does not own or that are not numeric', () async {
      final adapter = _FakeSeatGeekAdapter({}, singles: {'1': _listing(1)});
      final service = _serviceWith(adapter);

      expect(await service.getEventById('tm_G5v1'), isNull);
      expect(await service.getEventById('sg_'), isNull);
      expect(await service.getEventById('sg_abc'), isNull);
      expect(adapter.requests, isEmpty);
    });

    test('returns null instead of throwing on 404 or 500', () async {
      final missing = _serviceWith(_FakeSeatGeekAdapter({}));
      expect(await missing.getEventById('sg_1'), isNull);

      final broken = _serviceWith(_FakeSeatGeekAdapter({}, failAll: true));
      expect(await broken.getEventById('sg_1'), isNull);
    });

    test('search results are served from cache for deep links', () async {
      final adapter = _FakeSeatGeekAdapter({1: [_listing(5)]});
      final service = _serviceWith(adapter);

      await service.search(lat: 31.76, lng: -106.48);
      final event = await service.getEventById('sg_6000005');

      expect(event?.title, 'SeatGeek show 5');
      expect(adapter.requests, hasLength(1));
    });
  });
}
