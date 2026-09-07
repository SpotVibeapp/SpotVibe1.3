import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spotvibe_app/models/event.dart';
import 'package:spotvibe_app/services/live_event_source.dart';
import 'package:spotvibe_app/services/ticketmaster_service.dart';

/// Serves canned Discovery pages keyed by the `page` query param and
/// records every request so tests can assert on what was sent.
class _FakeDiscoveryAdapter implements HttpClientAdapter {
  _FakeDiscoveryAdapter(this.pages, {this.failPages = const {}});

  /// page index -> list of event JSON objects.
  final Map<int, List<Map<String, dynamic>>> pages;
  final Set<int> failPages;
  final List<Uri> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options.uri);
    final page = int.parse(options.uri.queryParameters['page'] ?? '0');
    if (failPages.contains(page)) {
      return ResponseBody.fromString('{"fault":"boom"}', 500,
          headers: {Headers.contentTypeHeader: ['application/json']});
    }
    final events = pages[page] ?? const <Map<String, dynamic>>[];
    final body = events.isEmpty
        ? <String, dynamic>{'page': {'number': page}}
        : <String, dynamic>{
            '_embedded': {'events': events},
            'page': {'number': page},
          };
    return ResponseBody.fromString(jsonEncode(body), 200,
        headers: {Headers.contentTypeHeader: ['application/json']});
  }

  @override
  void close({bool force = false}) {}
}

/// A minimal future Ticketmaster listing; [n] keeps ids and titles
/// unique so nothing collapses in dedupe.
Map<String, dynamic> _listing(int n) => {
      'id': 'G5v$n',
      'name': 'Show number $n',
      'dates': {
        'start': {'dateTime': '2027-01-01T20:00:00Z'},
      },
    };

TicketmasterService _serviceWith(_FakeDiscoveryAdapter adapter) {
  final dio = Dio()..httpClientAdapter = adapter;
  return TicketmasterService(
    dio: dio,
    apiKey: 'test-key',
    clock: () => DateTime.utc(2026, 9, 7, 12),
  );
}

void main() {
  test('formats a UTC lower-bound for Ticketmaster searches', () {
    expect(
      ticketmasterStartDateTime(DateTime.utc(2026, 9, 5, 18, 4, 9, 999)),
      '2026-09-05T18:04:09Z',
    );
    expect(kTicketmasterOngoingLookback, const Duration(hours: 24));
  });

  test('preserves an explicit Ticketmaster event end time for live visibility',
      () {
    final event = eventFromTicketmaster({
      'id': 'live-with-end',
      'name': 'Live Source Event',
      'dates': {
        'start': {'dateTime': '2026-09-05T18:00:00Z'},
        'end': {'dateTime': '2026-09-05T22:00:00Z'},
      },
    });

    expect(event, isNotNull);
    expect(event!.endDateTime?.toUtc(), DateTime.utc(2026, 9, 5, 22));
    expect(
      event.isVisibleAt(now: DateTime.utc(2026, 9, 5, 20)),
      isTrue,
    );
    expect(
      event.isVisibleAt(now: DateTime.utc(2026, 9, 5, 22)),
      isFalse,
    );
  });

  test('reads a local Ticketmaster end only when its time is supplied', () {
    final event = eventFromTicketmaster({
      'id': 'local-end',
      'name': 'Local Source Event',
      'dates': {
        'start': {'localDate': '2026-09-05', 'localTime': '18:00:00'},
        'end': {'localDate': '2026-09-05', 'localTime': '22:00:00'},
      },
    });

    expect(event, isNotNull);
    expect(event!.endDateTime, DateTime(2026, 9, 5, 22));
  });

  test('does not invent a Ticketmaster end time when the source lacks one', () {
    final event = eventFromTicketmaster({
      'id': 'unknown-end',
      'name': 'Source Event Without End',
      'dates': {
        'start': {'dateTime': '2026-09-05T18:00:00Z'},
        'end': {'dateTime': '2026-09-05T17:00:00Z'},
      },
    });

    expect(event, isNotNull);
    expect(event!.endDateTime, isNull);
  });

  test('picks the widest 16:9 Ticketmaster image', () {
    final url = pickTicketmasterImage([
      {'url': 'https://s1.ticketm.net/small.jpg', 'width': 100, 'ratio': '4_3'},
      {'url': 'https://s1.ticketm.net/wide.jpg', 'width': 640, 'ratio': '16_9'},
      {'url': 'https://s1.ticketm.net/huge_square.jpg', 'width': 2000, 'ratio': '1_1'},
    ]);
    expect(url, 'https://s1.ticketm.net/wide.jpg');
  });

  test('prefers team art over a huge baseball-glove stock image', () {
    final url = pickTicketmasterImage([
      {
        'url': 'https://s1.ticketm.net/dam/c/fbc/baseball-glove_TABLET_LANDSCAPE_LARGE_16_9.jpg',
        'width': 2048,
        'ratio': '16_9',
        'fallback': true,
      },
      {
        'url': 'https://s1.ticketm.net/dam/a/e67/chihuahuas-logo_RETINA_PORTRAIT_16_9.jpg',
        'width': 640,
        'ratio': '16_9',
        'fallback': true,
      },
    ]);
    expect(url, contains('chihuahuas-logo'));
  });

  test('uses the ballpark photo when Ticketmaster only sent stock art', () {
    final event = eventFromTicketmaster({
      'id': 'G5vYZglove',
      'name': 'El Paso Chihuahuas vs. Round Rock Express',
      'images': [
        {
          'url': 'https://s1.ticketm.net/dam/c/aaa/baseball-glove_16_9.jpg',
          'width': 2048,
          'ratio': '16_9',
          'fallback': true,
        },
      ],
      'dates': {
        'start': {'dateTime': '2026-08-20T01:05:00Z'},
      },
      '_embedded': {
        'venues': [
          {
            'name': 'Southwest University Park',
            'city': {'name': 'El Paso'},
            'state': {'stateCode': 'TX'},
          },
        ],
      },
    });
    expect(event, isNotNull);
    expect(event!.imageUrl, contains('southwest_university_park'));
    expect(event.imageUrl.startsWith('assets/venues/'), isTrue);
  });

  test('prefers unique attraction art over fallback and /dam/c/ stock', () {
    final url = pickTicketmasterImage([
      {
        'url': 'https://s1.ticketm.net/dam/c/fbc/genre-stock_TABLET_LANDSCAPE_LARGE_16_9.jpg',
        'width': 2048,
        'ratio': '16_9',
        'fallback': false,
      },
      {
        'url': 'https://s1.ticketm.net/dam/a/e67/artist_RETINA_PORTRAIT_16_9.jpg',
        'width': 640,
        'ratio': '16_9',
        'fallback': true,
      },
      {
        'url': 'https://s1.ticketm.net/dam/a/e67/artist_TABLET_LANDSCAPE_16_9.jpg',
        'width': 1024,
        'ratio': '16_9',
        'fallback': false,
      },
    ]);
    expect(url, 'https://s1.ticketm.net/dam/a/e67/artist_TABLET_LANDSCAPE_16_9.jpg');
  });

  test('returns empty when every image is generic stock', () {
    expect(
      pickTicketmasterImage([
        {
          'url': 'https://s1.ticketm.net/dam/c/aaa/music_16_9.jpg',
          'width': 2048,
          'ratio': '16_9',
          'fallback': true,
        },
      ]),
      isEmpty,
    );
  });

  test('uses attraction art when the event only has stock images', () {
    final event = eventFromTicketmaster({
      'id': 'G5vYZ9xyz',
      'name': 'Bad Bunny',
      'url': 'https://www.ticketmaster.com/event/G5vYZ9xyz',
      'images': [
        {
          'url': 'https://s1.ticketm.net/dam/c/fbc/music-stock_16_9.jpg',
          'width': 2048,
          'ratio': '16_9',
          'fallback': true,
        },
      ],
      'dates': {
        'start': {'dateTime': '2026-09-20T01:05:00Z'},
      },
      '_embedded': {
        'attractions': [
          {
            'name': 'Bad Bunny',
            'images': [
              {
                'url': 'https://s1.ticketm.net/dam/a/bbb/bad-bunny_TABLET_LANDSCAPE_LARGE_16_9.jpg',
                'width': 2048,
                'ratio': '16_9',
                'fallback': false,
              },
            ],
          },
        ],
        'venues': [
          {
            'name': 'Don Haskins Center',
            'city': {'name': 'El Paso'},
            'state': {'stateCode': 'TX'},
          },
        ],
      },
    });
    expect(event, isNotNull);
    expect(event!.imageUrl, contains('bad-bunny'));
    expect(isGenericEventImage(event.imageUrl), isFalse);
  });

  test('maps a Discovery API event to Event with official image', () {
    final event = eventFromTicketmaster({
      'id': 'G5vYZ9abc',
      'name': 'El Paso Chihuahuas vs. Albuquerque Isotopes',
      'url': 'https://www.ticketmaster.com/event/G5vYZ9abc',
      'info': 'Gates open one hour before first pitch.',
      'images': [
        {'url': 'https://s1.ticketm.net/dam/chihuahuas.jpg', 'width': 1024, 'ratio': '16_9'},
      ],
      'dates': {
        'start': {'dateTime': '2026-08-20T01:05:00Z'},
      },
      'priceRanges': [
        {'min': 12.0},
      ],
      'classifications': [
        {
          'segment': {'name': 'Sports'},
          'genre': {'name': 'Baseball'},
        },
      ],
      '_embedded': {
        'venues': [
          {
            'name': 'Southwest University Park',
            'postalCode': '79901',
            'city': {'name': 'El Paso'},
            'state': {'stateCode': 'TX'},
            'address': {'line1': '1 Ballpark Plaza'},
            'location': {'latitude': '31.7601', 'longitude': '-106.4933'},
          },
        ],
      },
    });

    expect(event, isNotNull);
    expect(event!.id, 'tm_G5vYZ9abc');
    expect(event.title, contains('Chihuahuas'));
    expect(event.location, 'Southwest University Park');
    expect(event.city, 'El Paso');
    expect(event.state, 'TX');
    expect(event.category, 'Sports');
    expect(event.source, EventSource.ticketmaster);
    expect(event.imageUrl, 'https://s1.ticketm.net/dam/chihuahuas.jpg');
    expect(event.cost, 12.0);
    expect(event.sourceUrl, contains('ticketmaster.com'));
    expect(event.latitude, closeTo(31.7601, 0.0001));
  });

  test('returns null when start date is missing', () {
    expect(eventFromTicketmaster({'id': 'x', 'name': 'No Date'}), isNull);
  });

  test('unconfigured client does not hit the network', () async {
    final tm = TicketmasterService(apiKey: '');
    expect(tm.isConfigured, isFalse);
    final events = await tm.search(city: 'El Paso', stateCode: 'TX');
    expect(events, isEmpty);
  });

  test('is a LiveEventSource that owns tm_ ids', () {
    final tm = TicketmasterService(apiKey: 'k');
    expect(tm, isA<LiveEventSource>());
    expect(tm.source, EventSource.ticketmaster);
    expect(tm.ownsId('tm_G5v1'), isTrue);
    expect(tm.ownsId('sg_1'), isFalse);
  });

  group('category → classificationName', () {
    test('maps the unambiguous SpotVibe categories only', () {
      expect(ticketmasterClassificationFor('Music'), 'Music');
      expect(ticketmasterClassificationFor('Sports'), 'Sports');
      expect(ticketmasterClassificationFor('Arts'), 'Arts & Theatre');
      expect(ticketmasterClassificationFor('Family'), 'Family');
      expect(ticketmasterClassificationFor('Film'), 'Film');
      expect(ticketmasterClassificationFor('Food'), isNull);
      expect(ticketmasterClassificationFor('All'), isNull);
      expect(ticketmasterClassificationFor(null), isNull);
    });

    test('is sent to the API for a mapped category and omitted otherwise',
        () async {
      final adapter = _FakeDiscoveryAdapter({0: [_listing(1)]});
      final tm = _serviceWith(adapter);

      await tm.search(city: 'El Paso', stateCode: 'TX', category: 'Arts');
      await tm.search(city: 'El Paso', stateCode: 'TX', category: 'Food');

      expect(adapter.requests, hasLength(2));
      expect(adapter.requests[0].queryParameters['classificationName'],
          'Arts & Theatre');
      expect(
        adapter.requests[1].queryParameters.containsKey('classificationName'),
        isFalse,
      );
    });
  });

  group('radius parameter', () {
    test('rounds to whole miles and clamps to the API ceiling', () {
      expect(ticketmasterRadiusParam(25.0), 25);
      expect(ticketmasterRadiusParam(37.6), 38);
      expect(ticketmasterRadiusParam(0.2), 1);
      expect(ticketmasterRadiusParam(-5), 1);
      expect(ticketmasterRadiusParam(200), 200);
      expect(ticketmasterRadiusParam(999), 200);
      expect(ticketmasterRadiusParam(double.nan), 1);
      expect(ticketmasterRadiusParam(double.infinity), 1);
    });

    test('is sent to the API as requested', () async {
      final adapter = _FakeDiscoveryAdapter({0: [_listing(1)]});
      final tm = _serviceWith(adapter);

      await tm.search(lat: 31.76, lng: -106.49, radiusMiles: 75);

      expect(adapter.requests, hasLength(1));
      final q = adapter.requests.single.queryParameters;
      expect(q['radius'], '75');
      expect(q['unit'], 'miles');
      expect(q['latlong'], '31.7600,-106.4900');
      expect(q['size'], '$kTicketmasterPageSize');
      expect(q['page'], '0');
    });
  });

  group('page budget', () {
    test('honours the caller budget below the deep-paging cap', () {
      expect(ticketmasterPageBudget(200, 3), 3);
      expect(ticketmasterPageBudget(200, 1), 1);
    });

    test('never lets size * page reach 1000', () {
      // size 200: pages 0..4 allowed (200*4 = 800 < 1000), page 5 is not.
      expect(ticketmasterPageBudget(200, 50), 5);
      // size 100: pages 0..9.
      expect(ticketmasterPageBudget(100, 50), 10);
      // size 1000: only page 0 (1000*1 is not < 1000).
      expect(ticketmasterPageBudget(1000, 50), 1);
    });

    test('is zero for nonsense input', () {
      expect(ticketmasterPageBudget(0, 3), 0);
      expect(ticketmasterPageBudget(200, 0), 0);
      expect(ticketmasterPageBudget(-1, -1), 0);
    });
  });

  group('pagination', () {
    test('stops after a short page without asking for the next one',
        () async {
      // Page size 3: page 0 is full, page 1 is short -> no page 2 call.
      final adapter = _FakeDiscoveryAdapter({
        0: [_listing(1), _listing(2), _listing(3)],
        1: [_listing(4)],
        2: [_listing(99)], // must never be requested
      });
      final tm = _serviceWith(adapter);

      final events = await tm.search(
          lat: 31.76, lng: -106.49, size: 3, maxPages: 5);

      expect(
        events.map((e) => e.id),
        ['tm_G5v1', 'tm_G5v2', 'tm_G5v3', 'tm_G5v4'],
      );
      expect(
        adapter.requests.map((u) => u.queryParameters['page']),
        ['0', '1'],
      );
    });

    test('stops at maxPages even when every page is full', () async {
      final adapter = _FakeDiscoveryAdapter({
        0: [_listing(1), _listing(2)],
        1: [_listing(3), _listing(4)],
        2: [_listing(5), _listing(6)],
      });
      final tm = _serviceWith(adapter);

      final events = await tm.search(
          lat: 31.76, lng: -106.49, size: 2, maxPages: 2);

      expect(events, hasLength(4));
      expect(adapter.requests, hasLength(2));
    });

    test('a single short page makes exactly one request', () async {
      final adapter = _FakeDiscoveryAdapter({0: [_listing(1)]});
      final tm = _serviceWith(adapter);

      final events = await tm.search(lat: 31.76, lng: -106.49);

      expect(events, hasLength(1));
      expect(adapter.requests, hasLength(1));
    });

    test('an empty result set is a normal empty list', () async {
      final adapter = _FakeDiscoveryAdapter({});
      final tm = _serviceWith(adapter);

      expect(await tm.search(lat: 31.76, lng: -106.49), isEmpty);
      expect(adapter.requests, hasLength(1));
    });

    test('keeps earlier pages when a later page fails', () async {
      final adapter = _FakeDiscoveryAdapter(
        {
          0: [_listing(1), _listing(2)],
          1: [_listing(3), _listing(4)],
        },
        failPages: {1},
      );
      final tm = _serviceWith(adapter);

      final events = await tm.search(
          lat: 31.76, lng: -106.49, size: 2, maxPages: 3);

      expect(events.map((e) => e.id), ['tm_G5v1', 'tm_G5v2']);
    });

    test('a failing first page still degrades to an empty list', () async {
      final adapter = _FakeDiscoveryAdapter(
        {0: [_listing(1)]},
        failPages: {0},
      );
      final tm = _serviceWith(adapter);

      expect(await tm.search(lat: 31.76, lng: -106.49), isEmpty);
    });

    test('paged events are all resolvable by id afterwards', () async {
      final adapter = _FakeDiscoveryAdapter({
        0: [_listing(1), _listing(2)],
        1: [_listing(3)],
      });
      final tm = _serviceWith(adapter);
      await tm.search(lat: 31.76, lng: -106.49, size: 2);

      // Served from the search cache: no extra request.
      final before = adapter.requests.length;
      final hit = await tm.getEventById('tm_G5v3');
      expect(hit?.title, 'Show number 3');
      expect(adapter.requests.length, before);
    });
  });
}
