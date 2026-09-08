import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spotvibe_app/data/event_dedupe.dart';
import 'package:spotvibe_app/models/event.dart';
import 'package:spotvibe_app/services/jambase_service.dart';
import 'package:spotvibe_app/services/live_event_source.dart';

/// Serves canned JamBase pages keyed by the `page` query param and records
/// every request. `/events/id/jambase:N` returns a single document.
class _FakeJamBaseAdapter implements HttpClientAdapter {
  _FakeJamBaseAdapter(
    this.pages, {
    this.failPages = const {},
    this.singles = const {},
    this.statusForAll,
  });

  /// page number (1-indexed) -> event JSON objects.
  final Map<int, List<Map<String, dynamic>>> pages;
  final Set<int> failPages;

  /// JamBase numeric id -> single event JSON.
  final Map<String, Map<String, dynamic>> singles;

  /// When set, every request answers with this status and a problem body.
  final int? statusForAll;
  final List<RequestOptions> requests = [];

  List<Uri> get uris => requests.map((r) => r.uri).toList(growable: false);

  static ResponseBody _json(Object body, int status) =>
      ResponseBody.fromString(jsonEncode(body), status, headers: {
        Headers.contentTypeHeader: ['application/json'],
      });

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final status = statusForAll;
    if (status != null) {
      return _json({'status': status, 'title': 'error'}, status);
    }
    final last = options.uri.pathSegments.last;
    if (last.startsWith('jambase:')) {
      final single = singles[last.substring('jambase:'.length)];
      if (single == null) return _json({'status': 404}, 404);
      return _json({'success': true, 'event': single}, 200);
    }
    final page = int.parse(options.uri.queryParameters['page'] ?? '1');
    if (failPages.contains(page)) return _json({'status': 500}, 500);
    final events = pages[page] ?? const <Map<String, dynamic>>[];
    final lastPage = pages.keys.isEmpty
        ? 1
        : pages.keys.reduce((a, b) => a > b ? a : b);
    return _json({
      'success': true,
      'pagination': {
        'page': page,
        'perPage': 100,
        'totalItems': pages.values.fold<int>(0, (n, l) => n + l.length),
        'totalPages': lastPage,
        'nextPage': page < lastPage ? page + 1 : null,
        'previousPage': page > 1 ? page - 1 : null,
      },
      'events': events,
    }, 200);
  }

  @override
  void close({bool force = false}) {}
}

/// A minimal future JamBase concert; [n] keeps ids and titles unique.
Map<String, dynamic> _concert(
  int n, {
  String startDate = '2027-01-01T20:00:00',
}) =>
    {
      '@type': 'Concert',
      'identifier': 'jambase:${16000000 + n}',
      'name': 'JamBase show $n',
      'url': 'https://www.jambase.com/show/jambase-show-$n',
      'eventStatus': 'scheduled',
      'startDate': startDate,
      'location': {
        'name': 'Venue $n',
        'address': {
          'addressLocality': 'El Paso',
          'addressRegion': {'alternateName': 'TX', 'identifier': 'US-TX'},
        },
      },
    };

/// A rich document exercising every field the mapper reads.
final Map<String, dynamic> _lowbrow = {
  '@type': 'Concert',
  'name': 'Khruangbin',
  'identifier': 'jambase:16013248',
  'url': 'https://www.jambase.com/show/khruangbin-lowbrow-palace-20261003',
  'image': 'https://www.jambase.com/wp-content/uploads/khruangbin.jpg',
  'x-subtitle': 'Album release party',
  'eventStatus': 'scheduled',
  'startDate': '2026-10-03T20:00:00',
  'doorTime': '2026-10-03T19:00:00',
  'eventAttendanceMode': 'offline',
  'isAccessibleForFree': false,
  'location': {
    '@type': 'MusicVenue',
    'name': 'Lowbrow Palace',
    'identifier': 'jambase:62108',
    'address': {
      'streetAddress': '111 E Robinson Ave',
      'addressLocality': 'El Paso',
      'postalCode': '79902',
      'addressRegion': {
        'name': 'Texas',
        'alternateName': 'TX',
        'identifier': 'US-TX',
      },
      'addressCountry': {'identifier': 'US', 'name': 'United States'},
      'x-timezone': 'America/Denver',
    },
    'geo': {'latitude': 31.7669, 'longitude': -106.4941},
  },
  'offers': [
    {
      'url': 'https://www.ticketweb.com/event/khruangbin-lowbrow-palace/1234?REFID=jambase',
      'category': 'ticketingLinkSecondary',
      'priceSpecification': {'minPrice': 35, 'maxPrice': 45, 'priceCurrency': 'USD'},
    },
    {
      'url': 'https://www.etix.com/ticket/p/98765/khruangbin?partner=jambase',
      'category': 'ticketingLinkPrimary',
      'priceSpecification': {'minPrice': 28, 'maxPrice': 40, 'priceCurrency': 'USD'},
    },
  ],
  'performer': [
    {
      'name': 'Men I Trust',
      'image': 'https://www.jambase.com/wp-content/uploads/men-i-trust.jpg',
      'x-isHeadliner': false,
      'x-performanceRank': 2,
    },
    {
      'name': 'Khruangbin',
      'image': 'https://www.jambase.com/wp-content/uploads/khruangbin-band.jpg',
      'x-isHeadliner': true,
      'x-performanceRank': 1,
    },
  ],
};

final DateTime _now = DateTime(2026, 9, 7, 19, 30);

JamBaseService _serviceWith(
  _FakeJamBaseAdapter adapter, {
  DateTime Function()? clock,
  JamBaseStore? store,
  Duration cacheTtl = kJamBaseCacheTtl,
  int monthlyBudget = kJamBaseMonthlyCallBudget,
}) {
  final dio = Dio()..httpClientAdapter = adapter;
  return JamBaseService(
    dio: dio,
    apiKey: 'jbd_test',
    clock: clock ?? () => _now,
    store: store,
    cacheTtl: cacheTtl,
    monthlyBudget: monthlyBudget,
  );
}

void main() {
  test('JamBaseService is a LiveEventSource that owns jb_ ids', () {
    final service = JamBaseService(apiKey: 'jbd_x');
    expect(service, isA<LiveEventSource>());
    expect(service.source, EventSource.jambase);
    expect(service.isConfigured, isTrue);
    expect(service.ownsId('jb_16013248'), isTrue);
    expect(service.ownsId('sg_123'), isFalse);
    expect(service.ownsId('tm_123'), isFalse);
    expect(service.ownsId('evt_ep_1'), isFalse);
  });

  test('without a key the source is unconfigured and returns nothing',
      () async {
    final adapter = _FakeJamBaseAdapter({1: [_concert(1)]});
    final dio = Dio()..httpClientAdapter = adapter;
    final service = JamBaseService(dio: dio, apiKey: '');

    expect(service.isConfigured, isFalse);
    expect(await service.search(lat: 31.76, lng: -106.48), isEmpty);
    expect(await service.getEventById('jb_16000001'), isNull);
    expect(adapter.requests, isEmpty, reason: 'no key → no network');
  });

  group('query helpers', () {
    test('only Music (or no filter) can contain JamBase rows', () {
      expect(jamBaseServes(null), isTrue);
      expect(jamBaseServes('All'), isTrue);
      expect(jamBaseServes('Music'), isTrue);
      expect(jamBaseServes('Sports'), isFalse);
      expect(jamBaseServes('Arts'), isFalse);
      expect(jamBaseServes('Family'), isFalse);
    });

    test('radius snaps up to a bucket so the slider cannot mint requests',
        () {
      expect(jamBaseRadiusBucket(10), 25);
      expect(jamBaseRadiusBucket(25), 25);
      expect(jamBaseRadiusBucket(26), 50);
      expect(jamBaseRadiusBucket(40), 50);
      expect(jamBaseRadiusBucket(75), 100);
      expect(jamBaseRadiusBucket(200), 200);
      expect(jamBaseRadiusBucket(500), 200);
      expect(jamBaseRadiusBucket(0), 25);
      expect(jamBaseRadiusBucket(double.nan), 25);
      expect(jamBaseRadiusBucket(double.infinity), 200);
    });

    test('dates are the local calendar day, zero padded', () {
      expect(jamBaseDateParam(DateTime(2026, 9, 7, 23, 59)), '2026-09-07');
      expect(jamBaseDateParam(DateTime(2027, 1, 1)), '2027-01-01');
    });

    test('identifiers are parsed strictly', () {
      expect(jamBaseNumericId('jambase:16013248'), '16013248');
      expect(jamBaseNumericId(' jambase:7 '), '7');
      expect(jamBaseNumericId('ticketmaster:G5vYZ4ZpZAfdJ'), isNull);
      expect(jamBaseNumericId('jambase:'), isNull);
      expect(jamBaseNumericId(16013248), isNull);
      expect(jamBaseNumericId(null), isNull);
    });

    test('venue-local times are read as local; offsets are honoured', () {
      expect(
        parseJamBaseLocalTime('2026-10-03T20:00:00'),
        DateTime(2026, 10, 3, 20),
      );
      expect(
        parseJamBaseLocalTime('2026-10-05', endOfDay: true),
        DateTime(2026, 10, 5, 23, 59, 59),
      );
      expect(parseJamBaseLocalTime('2026-10-05'), DateTime(2026, 10, 5));
      final zoned = parseJamBaseLocalTime('2026-10-03T20:00:00Z')!;
      expect(zoned.isUtc, isFalse);
      expect(zoned.toUtc(), DateTime.utc(2026, 10, 3, 20));
      expect(parseJamBaseLocalTime('soon'), isNull);
      expect(parseJamBaseLocalTime(null), isNull);
    });

    test('the ticket URL is the primary offer, verbatim, else JamBase', () {
      expect(
        jamBaseTicketUrl(_lowbrow),
        'https://www.etix.com/ticket/p/98765/khruangbin?partner=jambase',
      );
      final secondaryOnly = Map<String, dynamic>.from(_lowbrow)
        ..['offers'] = [_lowbrow['offers'][0]];
      expect(jamBaseTicketUrl(secondaryOnly), contains('ticketweb.com'));
      final noOffers = Map<String, dynamic>.from(_lowbrow)..remove('offers');
      expect(jamBaseTicketUrl(noOffers), startsWith('https://www.jambase.com/'));
      final nothing = Map<String, dynamic>.from(noOffers)..remove('url');
      expect(jamBaseTicketUrl(nothing), isNull);
    });
  });

  group('mapper', () {
    test('maps a full concert document', () {
      final event = eventFromJamBase(_lowbrow)!;
      expect(event.id, 'jb_16013248');
      expect(event.source, EventSource.jambase);
      expect(event.title, 'Khruangbin');
      expect(event.dateTime, DateTime(2026, 10, 3, 20));
      expect(event.endDateTime, isNull);
      expect(event.location, 'Lowbrow Palace');
      expect(event.address, '111 E Robinson Ave');
      expect(event.city, 'El Paso');
      expect(event.state, 'TX');
      expect(event.zipCode, '79902');
      expect(event.latitude, closeTo(31.7669, 1e-9));
      expect(event.longitude, closeTo(-106.4941, 1e-9));
      expect(event.category, 'Music');
      expect(event.isTicketed, isTrue);
      expect(event.isFree, isFalse);
      expect(event.cost, 28, reason: 'lowest published minPrice');
      expect(event.sourceUrl,
          'https://www.etix.com/ticket/p/98765/khruangbin?partner=jambase');
      expect(event.imageUrl, contains('khruangbin.jpg'));
      expect(event.organizerName, 'Lowbrow Palace');
      expect(event.description, contains('Album release party'));
      expect(event.description,
          contains('Khruangbin with Men I Trust at Lowbrow Palace.'));
      expect(event.description, contains('JamBase'));
    });

    test('a custom title beats the artist name and a headliner photo fills '
        'in for missing event art', () {
      final json = Map<String, dynamic>.from(_lowbrow)
        ..['x-customTitle'] = 'An Evening With Khruangbin'
        ..remove('image');
      final event = eventFromJamBase(json)!;
      expect(event.title, 'An Evening With Khruangbin');
      expect(event.imageUrl, contains('khruangbin-band.jpg'));
    });

    test('free shows are free; unpriced paid shows are still ticketed', () {
      final free = Map<String, dynamic>.from(_lowbrow)
        ..['isAccessibleForFree'] = true;
      final freeEvent = eventFromJamBase(free)!;
      expect(freeEvent.isFree, isTrue);
      expect(freeEvent.cost, isNull);
      expect(freeEvent.isTicketed, isFalse);
      expect(freeEvent.description, contains('Free show.'));

      final unpriced = Map<String, dynamic>.from(_lowbrow)
        ..['offers'] = [
          {'url': 'https://tickets.example.com/1', 'category': 'ticketingLinkPrimary'},
        ];
      final unpricedEvent = eventFromJamBase(unpriced)!;
      expect(unpricedEvent.cost, isNull);
      expect(unpricedEvent.isTicketed, isTrue);
      expect(unpricedEvent.isFree, isFalse);
      expect(unpricedEvent.costLabel, 'Tickets');
    });

    test('festivals keep a multi-day window', () {
      final json = Map<String, dynamic>.from(_lowbrow)
        ..['@type'] = 'Festival'
        ..['name'] = 'Neon Desert Music Festival'
        ..['startDate'] = '2027-05-22T12:00:00'
        ..['endDate'] = '2027-05-23';
      final event = eventFromJamBase(json)!;
      expect(event.dateTime, DateTime(2027, 5, 22, 12));
      expect(event.endDateTime, DateTime(2027, 5, 23, 23, 59, 59));
      expect(event.description, startsWith('Album release party Festival at'));
      // An end that does not follow the start is dropped, not trusted.
      final bad = Map<String, dynamic>.from(json)..['endDate'] = '2027-05-21';
      expect(eventFromJamBase(bad)!.endDateTime, isNull);
    });

    test('state falls back from alternateName to the ISO identifier', () {
      final json = jsonDecode(jsonEncode(_lowbrow)) as Map<String, dynamic>;
      (json['location']['address']['addressRegion'] as Map).remove('alternateName');
      expect(eventFromJamBase(json)!.state, 'TX');
      json['location']['address']['addressRegion'] = 'US-NM';
      expect(eventFromJamBase(json)!.state, 'NM');
    });

    test('cancelled and online-only shows are dropped', () {
      final cancelled = Map<String, dynamic>.from(_lowbrow)
        ..['eventStatus'] = 'cancelled';
      expect(eventFromJamBase(cancelled), isNull);
      final online = Map<String, dynamic>.from(_lowbrow)
        ..['eventAttendanceMode'] = 'online';
      expect(eventFromJamBase(online), isNull);
      final postponed = Map<String, dynamic>.from(_lowbrow)
        ..['eventStatus'] = 'postponed';
      expect(eventFromJamBase(postponed)!.description, contains('Postponed'));
    });

    test('documents without an id, title or start are skipped', () {
      expect(eventFromJamBase({..._lowbrow, 'identifier': 'seatgeek:1'}),
          isNull);
      expect(eventFromJamBase({..._lowbrow, 'name': '  '}), isNull);
      expect(eventFromJamBase({..._lowbrow, 'startDate': 'TBA'}), isNull);
    });

    test('a slimmed document maps identically to the full one', () {
      final full = eventFromJamBase(_lowbrow)!;
      final slim = slimJamBaseDoc(_lowbrow);
      // Round-trip through JSON as the persisted cache does.
      final restored = jsonDecode(jsonEncode(slim)) as Map<String, dynamic>;
      final again = eventFromJamBase(restored)!;
      expect(again.id, full.id);
      expect(again.title, full.title);
      expect(again.dateTime, full.dateTime);
      expect(again.location, full.location);
      expect(again.address, full.address);
      expect(again.state, full.state);
      expect(again.latitude, full.latitude);
      expect(again.cost, full.cost);
      expect(again.sourceUrl, full.sourceUrl);
      expect(again.imageUrl, full.imageUrl);
      expect(again.description, full.description);
      expect(slim.containsKey('doorTime'), isFalse);
      expect((slim['location'] as Map).containsKey('identifier'), isFalse);
    });

    test('JamBase rows outrank SeatGeek but not Ticketmaster in dedupe', () {
      final jb = eventFromJamBase(_lowbrow)!;
      Event mirror(String id, EventSource source) => Event(
            id: id,
            title: jb.title,
            description: jb.description,
            dateTime: jb.dateTime,
            location: jb.location,
            address: jb.address,
            city: jb.city,
            state: jb.state,
            imageUrl: jb.imageUrl,
            category: jb.category,
            organizerName: jb.organizerName,
            organizerAvatarUrl: jb.organizerAvatarUrl,
            latitude: jb.latitude,
            longitude: jb.longitude,
            source: source,
            sourceUrl: 'https://example.com/$id',
          );
      final sg = mirror('sg_1', EventSource.seatgeek);
      final tm = mirror('tm_1', EventSource.ticketmaster);
      expect(dedupeEvents([sg, jb]).single.id, 'jb_16013248');
      expect(dedupeEvents([jb, sg]).single.id, 'jb_16013248');
      expect(dedupeEvents([jb, tm]).single.id, 'tm_1');
      expect(dedupeEvents([tm, jb, sg]).single.id, 'tm_1');
    });
  });

  group('search', () {
    test('sends a bearer header, geo bucket and a local date lower bound',
        () async {
      final adapter = _FakeJamBaseAdapter({1: [_concert(1)]});
      final service = _serviceWith(adapter);

      final events = await service.search(
        lat: 31.7619,
        lng: -106.4842,
        radiusMiles: 40,
        category: 'Music',
        keyword: 'jazz',
      );

      expect(events, hasLength(1));
      expect(events.single.id, 'jb_16000001');
      expect(adapter.requests, hasLength(1));
      final request = adapter.requests.single;
      final q = request.uri.queryParameters;
      expect(request.uri.host, 'api.data.jambase.com');
      expect(request.uri.path, '/v3/events');
      expect(request.headers['Authorization'], 'Bearer jbd_test');
      expect(request.headers['Accept'], 'application/json');
      expect(request.headers['User-Agent'], startsWith('SpotVibe/'));
      expect(q.containsKey('apikey'), isFalse, reason: 'never in the URL');
      expect(q['geoLatitude'], '31.76');
      expect(q['geoLongitude'], '-106.48');
      expect(q['geoRadiusAmount'], '50');
      expect(q['geoRadiusUnits'], 'mi');
      expect(q['eventDateFrom'], '2026-09-07');
      expect(q.containsKey('eventDateTo'), isFalse);
      expect(q['perPage'], '$kJamBasePageSize');
      expect(q['sort'], 'eventDate');
      expect(q['page'], '1');
      expect(q.containsKey('name'), isFalse,
          reason: 'keywords are filtered locally, not per keystroke');
    });

    test('falls back to city/state when no coordinates are given', () async {
      final adapter = _FakeJamBaseAdapter({1: [_concert(1)]});
      final service = _serviceWith(adapter);

      await service.search(city: 'Las Cruces', stateCode: 'nm');

      final q = adapter.uris.single.queryParameters;
      expect(q['geoCityName'], 'Las Cruces');
      expect(q['geoStateIso'], 'US-NM');
      expect(q.containsKey('geoLatitude'), isFalse);
      expect(q.containsKey('geoRadiusAmount'), isFalse);
    });

    test('returns nothing without a place, and nothing for non-music '
        'categories, without touching the network', () async {
      final adapter = _FakeJamBaseAdapter({1: [_concert(1)]});
      final service = _serviceWith(adapter);

      expect(await service.search(keyword: 'anything'), isEmpty);
      expect(
        await service.search(lat: 31.76, lng: -106.48, category: 'Sports'),
        isEmpty,
      );
      expect(adapter.requests, isEmpty);
    });

    test('walks pages while JamBase reports a next page', () async {
      final adapter = _FakeJamBaseAdapter({
        1: List.generate(100, (i) => _concert(i)),
        2: [_concert(200), _concert(201)],
      });
      final service = _serviceWith(adapter);

      final events = await service.search(lat: 31.76, lng: -106.48);

      expect(events, hasLength(102));
      expect(adapter.requests, hasLength(2));
      expect(adapter.uris.last.queryParameters['page'], '2');
    });

    test('stops after a short page without asking for another', () async {
      final adapter = _FakeJamBaseAdapter({1: [_concert(1), _concert(2)]});
      final service = _serviceWith(adapter);

      await service.search(lat: 31.76, lng: -106.48);

      expect(adapter.requests, hasLength(1));
    });

    test('a failed later page keeps the earlier one', () async {
      final adapter = _FakeJamBaseAdapter({
        1: List.generate(100, (i) => _concert(i)),
        2: [_concert(200)],
      }, failPages: {2});
      final service = _serviceWith(adapter);

      final events = await service.search(lat: 31.76, lng: -106.48);

      expect(events, hasLength(100));
    });

    test('a failed first page yields an empty list, not an exception',
        () async {
      final service = _serviceWith(_FakeJamBaseAdapter({}, statusForAll: 500));
      expect(await service.search(lat: 31.76, lng: -106.48), isEmpty);
    });

    test('past, cancelled and add-on rows are filtered out', () async {
      final adapter = _FakeJamBaseAdapter({
        1: [
          _concert(1, startDate: '2026-09-07T19:00:00'),
          _concert(2),
          {..._concert(3), 'eventStatus': 'cancelled'},
          {..._concert(4), 'name': 'Parking'},
        ],
      });
      final service = _serviceWith(adapter);

      final events = await service.search(lat: 31.76, lng: -106.48);

      expect(events.map((e) => e.id).toList(), ['jb_16000002']);
    });
  });

  group('cache and quota', () {
    test('the same area is served from cache within the TTL', () async {
      final adapter = _FakeJamBaseAdapter({1: [_concert(1)]});
      var now = _now;
      final service = _serviceWith(adapter, clock: () => now);

      final first = await service.search(lat: 31.7619, lng: -106.4842);
      // GPS jitter, a different keyword and a slider notch inside the same
      // bucket must not cost a request.
      now = now.add(const Duration(minutes: 1));
      final second = await service.search(
        lat: 31.7623,
        lng: -106.4846,
        radiusMiles: 45,
        keyword: 'blues',
      );

      expect(first, hasLength(1));
      expect(second, hasLength(1));
      expect(adapter.requests, hasLength(1), reason: 'second hit is cached');
      expect(await service.callsThisMonth(), 1);
    });

    test('a new bucket, city or later day is a new request', () async {
      final adapter = _FakeJamBaseAdapter({1: [_concert(1)]});
      var now = _now;
      final service = _serviceWith(adapter, clock: () => now);

      await service.search(lat: 31.76, lng: -106.48, radiusMiles: 25);
      await service.search(lat: 31.76, lng: -106.48, radiusMiles: 60);
      await service.search(city: 'Las Cruces', stateCode: 'NM');
      now = now.add(const Duration(hours: 6));
      await service.search(lat: 31.76, lng: -106.48, radiusMiles: 25);

      expect(adapter.requests, hasLength(4));
    });

    test('an expired entry is refetched', () async {
      final adapter = _FakeJamBaseAdapter({1: [_concert(1)]});
      var now = _now;
      final service = _serviceWith(
        adapter,
        clock: () => now,
        cacheTtl: const Duration(minutes: 30),
      );

      await service.search(lat: 31.76, lng: -106.48);
      now = now.add(const Duration(minutes: 31));
      await service.search(lat: 31.76, lng: -106.48);

      expect(adapter.requests, hasLength(2));
    });

    test('the cache survives a restart through the store', () async {
      final store = MemoryJamBaseStore();
      final adapter = _FakeJamBaseAdapter({1: [_concert(1)]});
      await _serviceWith(adapter, store: store).search(lat: 31.76, lng: -106.48);

      final relaunched = _serviceWith(adapter, store: store);
      final events = await relaunched.search(lat: 31.76, lng: -106.48);

      expect(events.single.id, 'jb_16000001');
      expect(adapter.requests, hasLength(1));
      expect(await relaunched.callsThisMonth(), 1);
      // A deep link to a cached row needs no request either.
      expect((await relaunched.getEventById('jb_16000001'))?.id, 'jb_16000001');
      expect(adapter.requests, hasLength(1));
    });

    test('concurrent searches for one area share a single request', () async {
      final adapter = _FakeJamBaseAdapter({1: [_concert(1)]});
      final service = _serviceWith(adapter);

      final results = await Future.wait([
        service.search(lat: 31.76, lng: -106.48),
        service.search(lat: 31.76, lng: -106.48),
        service.search(lat: 31.76, lng: -106.48),
      ]);

      expect(results.every((r) => r.length == 1), isTrue);
      expect(adapter.requests, hasLength(1));
    });

    test('the monthly budget stops requests and resets next month',
        () async {
      final adapter = _FakeJamBaseAdapter({1: [_concert(1)]});
      var now = _now;
      final service = _serviceWith(
        adapter,
        clock: () => now,
        cacheTtl: Duration.zero,
        monthlyBudget: 2,
      );

      await service.search(lat: 31.76, lng: -106.48);
      await service.search(lat: 31.76, lng: -106.48);
      final third = await service.search(lat: 31.76, lng: -106.48);

      expect(adapter.requests, hasLength(2));
      expect(third, hasLength(1), reason: 'stale cache beats an empty feed');
      expect(await service.callsThisMonth(), 2);

      now = DateTime(2026, 10, 1, 9);
      await service.search(lat: 31.76, lng: -106.48);
      expect(adapter.requests, hasLength(3));
      expect(await service.callsThisMonth(), 1);
    });

    test('a rejected key disables the source for the session', () async {
      final adapter = _FakeJamBaseAdapter({}, statusForAll: 401);
      final service = _serviceWith(adapter, cacheTtl: Duration.zero);

      expect(await service.search(lat: 31.76, lng: -106.48), isEmpty);
      expect(await service.search(lat: 31.76, lng: -106.48), isEmpty);
      expect(await service.getEventById('jb_1'), isNull);

      expect(adapter.requests, hasLength(1));
      expect(await service.callsThisMonth(), 1);
    });

    test('a 429 pauses requests instead of retrying every minute', () async {
      final adapter = _FakeJamBaseAdapter({}, statusForAll: 429);
      var now = _now;
      final service = _serviceWith(
        adapter,
        clock: () => now,
        cacheTtl: Duration.zero,
      );

      await service.search(lat: 31.76, lng: -106.48);
      now = now.add(const Duration(minutes: 1));
      await service.search(lat: 31.76, lng: -106.48);
      expect(adapter.requests, hasLength(1));

      now = now.add(kJamBaseRateLimitPause);
      await service.search(lat: 31.76, lng: -106.48);
      expect(adapter.requests, hasLength(2));
    });
  });

  group('getEventById', () {
    test('fetches a single jb_ event by JamBase identifier and caches it',
        () async {
      final adapter = _FakeJamBaseAdapter({}, singles: {'16013248': _lowbrow});
      final service = _serviceWith(adapter);

      final first = await service.getEventById('jb_16013248');
      final second = await service.getEventById('jb_16013248');

      expect(first?.id, 'jb_16013248');
      expect(first?.title, 'Khruangbin');
      expect(second?.id, 'jb_16013248');
      expect(adapter.requests, hasLength(1), reason: 'second hit is cached');
      expect(adapter.uris.single.path, '/v3/events/id/jambase:16013248');
      expect(adapter.requests.single.headers['Authorization'],
          'Bearer jbd_test');
    });

    test('refuses ids it does not own or that are not numeric', () async {
      final adapter = _FakeJamBaseAdapter({}, singles: {'1': _concert(1)});
      final service = _serviceWith(adapter);

      expect(await service.getEventById('sg_1'), isNull);
      expect(await service.getEventById('jb_'), isNull);
      expect(await service.getEventById('jb_abc'), isNull);
      expect(adapter.requests, isEmpty);
    });

    test('returns null instead of throwing on 404 or 500', () async {
      final missing = _serviceWith(_FakeJamBaseAdapter({}));
      expect(await missing.getEventById('jb_1'), isNull);

      final broken = _serviceWith(_FakeJamBaseAdapter({}, statusForAll: 500));
      expect(await broken.getEventById('jb_1'), isNull);
    });

    test('search results are served from memory for deep links', () async {
      final adapter = _FakeJamBaseAdapter({1: [_concert(5)]});
      final service = _serviceWith(adapter);

      await service.search(lat: 31.76, lng: -106.48);
      final event = await service.getEventById('jb_16000005');

      expect(event?.title, 'JamBase show 5');
      expect(adapter.requests, hasLength(1));
    });
  });
}
