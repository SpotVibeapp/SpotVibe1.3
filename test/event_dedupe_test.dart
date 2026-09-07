import 'package:flutter_test/flutter_test.dart';
import 'package:spotvibe_app/data/event_dedupe.dart';
import 'package:spotvibe_app/models/event.dart';

Event _event({
  required String id,
  required String title,
  required String location,
  required DateTime dateTime,
  String imageUrl = '',
  String description = 'Short',
  EventSource source = EventSource.local,
  String? sourceUrl,
  double latitude = 0,
  double longitude = 0,
}) {
  return Event(
    id: id,
    title: title,
    description: description,
    dateTime: dateTime,
    location: location,
    address: '1 Main',
    city: 'El Paso',
    state: 'TX',
    zipCode: '79901',
    imageUrl: imageUrl,
    category: 'Music',
    organizerName: 'Org',
    organizerAvatarUrl: 'https://ui-avatars.com/api/?name=Org',
    source: source,
    sourceUrl: sourceUrl,
    latitude: latitude,
    longitude: longitude,
  );
}

/// Don Haskins Center, as two providers might geocode it.
const _haskinsLat = 31.7726;
const _haskinsLng = -106.5047;

void main() {
  final night = DateTime(2026, 8, 14, 20);

  test('same title, venue, and day collapse to one event', () {
    final a = _event(
      id: 'evt_ep_002',
      title: 'Live at El Paso County Coliseum',
      location: 'El Paso County Coliseum',
      dateTime: night,
    );
    final b = _event(
      id: 'tm_abc123',
      title: 'Live at El Paso County Coliseum',
      location: 'El Paso County Coliseum',
      dateTime: night.add(const Duration(hours: 1)),
      imageUrl: 'https://s1.ticketm.net/dam/photo.jpg',
      source: EventSource.ticketmaster,
      sourceUrl: 'https://ticketmaster.com/event/abc',
      description: 'Official Ticketmaster listing with tickets and seating.',
    );
    final out = dedupeEvents([a, b]);
    expect(out, hasLength(1));
    expect(out.single.id, 'tm_abc123');
    expect(out.single.imageUrl, contains('ticketm.net'));
  });

  test('duplicate ids keep the higher-quality row', () {
    final weak = _event(
      id: 'same',
      title: 'Show',
      location: 'Hall',
      dateTime: night,
    );
    final strong = _event(
      id: 'same',
      title: 'Show',
      location: 'Hall',
      dateTime: night,
      imageUrl: 'https://example.com/real.jpg',
    );
    final out = dedupeEvents([weak, strong]);
    expect(out, hasLength(1));
    expect(out.single.imageUrl, 'https://example.com/real.jpg');
  });

  test('different days are not duplicates', () {
    final a = _event(
      id: 'a',
      title: 'Chihuahuas',
      location: 'Southwest University Park',
      dateTime: night,
    );
    final b = _event(
      id: 'b',
      title: 'Chihuahuas',
      location: 'Southwest University Park',
      dateTime: night.add(const Duration(days: 1)),
    );
    expect(dedupeEvents([a, b]), hasLength(2));
  });

  test('punctuation and case do not create extra copies', () {
    final a = _event(
      id: 'local',
      title: 'Plaza Theatre: Classic Film Night',
      location: 'Plaza Theatre',
      dateTime: night,
    );
    final b = _event(
      id: 'tm_plaza',
      title: 'Plaza Theatre Classic Film Night',
      location: 'The Plaza Theatre',
      dateTime: night,
      imageUrl: 'https://s1.ticketm.net/plaza.jpg',
      source: EventSource.ticketmaster,
    );
    final out = dedupeEvents([a, b]);
    expect(out, hasLength(1));
    expect(out.single.id, 'tm_plaza');
  });

  test('same-day Chihuahuas matchup listings collapse to one game', () {
    final listings = [
      _event(
        id: 'tm_main',
        title: 'El Paso Chihuahuas vs. Round Rock Express',
        location: 'Southwest University Park',
        dateTime: night,
        source: EventSource.ticketmaster,
        sourceUrl: 'https://ticketmaster.com/event/main',
        description: 'Official listing with tickets and seating chart.',
      ),
      _event(
        id: 'tm_vip',
        title: 'El Paso Chihuahuas vs. Round Rock Express - VIP Picnic',
        location: 'Southwest University Park',
        dateTime: night.add(const Duration(minutes: 30)),
        source: EventSource.ticketmaster,
      ),
      _event(
        id: 'tm_park',
        title: 'El Paso Chihuahuas vs Round Rock Express Parking',
        location: 'Southwest University Park',
        dateTime: night,
        source: EventSource.ticketmaster,
      ),
      _event(
        id: 'tm_theme',
        title: 'El Paso Chihuahuas vs. Round Rock Express - Fireworks Night',
        location: 'Southwest University Park',
        dateTime: night,
        source: EventSource.ticketmaster,
      ),
    ];
    final out = dedupeEvents(listings);
    expect(out, hasLength(1));
    expect(out.single.id, 'tm_main');
    expect(out.single.title, 'El Paso Chihuahuas vs. Round Rock Express');
  });

  test('Ticketmaster listing keeps a curated venue photo when TM art is stock', () {
    final local = _event(
      id: 'evt_ep_coliseum',
      title: 'Live at El Paso County Coliseum',
      location: 'El Paso County Coliseum',
      dateTime: night,
      imageUrl: 'assets/venues/county_coliseum.jpg',
    );
    final tm = _event(
      id: 'tm_abc123',
      title: 'Live at El Paso County Coliseum',
      location: 'El Paso County Coliseum',
      dateTime: night,
      imageUrl: 'https://s1.ticketm.net/dam/c/fbc/music-stock_16_9.jpg',
      source: EventSource.ticketmaster,
      sourceUrl: 'https://ticketmaster.com/event/abc',
      description: 'Official Ticketmaster listing with tickets and seating.',
    );
    final out = dedupeEvents([local, tm]);
    expect(out, hasLength(1));
    expect(out.single.id, 'tm_abc123');
    expect(out.single.imageUrl, contains('county_coliseum'));
  });
  test('same show on Ticketmaster and SeatGeek keeps the Ticketmaster row', () {
    final tm = _event(
      id: 'tm_G5vZ9',
      title: 'Khruangbin',
      location: 'Abraham Chavez Theatre',
      dateTime: night,
      imageUrl: 'https://s1.ticketm.net/dam/a/khruangbin.jpg',
      source: EventSource.ticketmaster,
      sourceUrl: 'https://ticketmaster.com/event/G5vZ9',
      description: 'Official Ticketmaster listing with tickets and seating.',
    );
    final sg = _event(
      id: 'sg_6162405',
      title: 'Khruangbin',
      location: 'Abraham Chavez Theatre',
      dateTime: night.add(const Duration(minutes: 30)),
      imageUrl: 'https://seatgeek.com/images/performers/khruangbin/huge.jpg',
      source: EventSource.seatgeek,
      sourceUrl: 'https://seatgeek.com/khruangbin-tickets/6162405',
      description: 'Official SeatGeek listing with tickets and seating.',
    );
    // Order must not matter.
    for (final input in [
      [tm, sg],
      [sg, tm],
    ]) {
      final out = dedupeEvents(input);
      expect(out, hasLength(1));
      expect(out.single.id, 'tm_G5vZ9');
      expect(out.single.source, EventSource.ticketmaster);
    }
  });

  test('a SeatGeek row still beats a curated placeholder for the same show',
      () {
    final local = _event(
      id: 'evt_ep_chavez',
      title: 'Khruangbin',
      location: 'Abraham Chavez Theatre',
      dateTime: night,
      imageUrl: 'assets/venues/abraham_chavez.jpg',
      source: EventSource.ticketmaster,
    );
    final sg = _event(
      id: 'sg_6162405',
      title: 'Khruangbin',
      location: 'Abraham Chavez Theatre',
      dateTime: night,
      source: EventSource.seatgeek,
      sourceUrl: 'https://seatgeek.com/khruangbin-tickets/6162405',
    );
    final out = dedupeEvents([local, sg]);
    expect(out, hasLength(1));
    expect(out.single.id, 'sg_6162405');
    // …but borrows the real venue photo the placeholder had.
    expect(out.single.imageUrl, contains('abraham_chavez'));
  });
  group('cross-provider venue spelling', () {
    test('Theatre and Theater are the same word', () {
      final a = _event(
        id: 'tm_1',
        title: 'Symphony Night',
        location: 'Abraham Chavez Theatre',
        dateTime: night,
      );
      final b = _event(
        id: 'sg_1',
        title: 'Symphony Night',
        location: 'Abraham Chavez Theater',
        dateTime: night,
      );
      expect(isSameShow(a, b), isTrue);
      expect(dedupeEvents([a, b]), hasLength(1));
    });

    test('a venue name inside a longer one is the same place', () {
      final tm = _event(
        id: 'tm_1',
        title: 'UTEP Miners vs New Mexico State Aggies',
        location: 'Don Haskins Center',
        dateTime: night,
      );
      final sg = _event(
        id: 'sg_1',
        title: 'New Mexico State Aggies at UTEP Miners',
        location: 'UTEP Don Haskins Center - El Paso',
        dateTime: night.add(const Duration(minutes: 5)),
      );
      final out = dedupeEvents([sg, tm]);
      expect(out, hasLength(1));
      expect(out.single.id, 'tm_1');
    });

    test('a generic short name cannot claim every venue that contains it',
        () {
      final a = _event(
        id: 'a',
        title: 'Salsa Night',
        location: 'Community Center',
        dateTime: night,
      );
      final b = _event(
        id: 'b',
        title: 'Salsa Night',
        location: 'Marty Robbins Community Center',
        dateTime: night,
      );
      expect(isSameShow(a, b), isFalse);
      expect(dedupeEvents([a, b]), hasLength(2));
    });

    test('unrelated venue names never merge without coordinates', () {
      final a = _event(
        id: 'a',
        title: 'Salsa Night',
        location: 'Don Haskins Center',
        dateTime: night,
      );
      final b = _event(
        id: 'b',
        title: 'Salsa Night',
        location: 'Lowbrow Palace',
        dateTime: night,
      );
      expect(dedupeEvents([a, b]), hasLength(2));
    });

    test('related names at the same coordinates are one venue', () {
      final a = _event(
        id: 'tm_1',
        title: 'Khruangbin',
        location: 'Haskins Ctr',
        dateTime: night,
        latitude: _haskinsLat,
        longitude: _haskinsLng,
      );
      final b = _event(
        id: 'sg_1',
        title: 'Khruangbin',
        location: 'Don Haskins Center',
        dateTime: night,
        latitude: _haskinsLat + 0.0004,
        longitude: _haskinsLng - 0.0003,
      );
      expect(isSameShow(a, b), isTrue);
    });

    test('a listing with no venue name defers to the map', () {
      final unnamed = _event(
        id: 'a',
        title: 'Khruangbin',
        location: '',
        dateTime: night,
        latitude: _haskinsLat,
        longitude: _haskinsLng,
      );
      final named = _event(
        id: 'b',
        title: 'Khruangbin',
        location: 'Don Haskins Center',
        dateTime: night,
        latitude: _haskinsLat,
        longitude: _haskinsLng,
      );
      expect(isSameShow(unnamed, named), isTrue);
      // …but not when it has no coordinates either.
      final nowhere = _event(
        id: 'c',
        title: 'Khruangbin',
        location: '',
        dateTime: night,
      );
      expect(isSameShow(nowhere, named), isFalse);
    });

    test('the same title at neighbouring but unrelated bars stays two events',
        () {
      // Two open mics on Texas Avenue, 30 m apart.
      final a = _event(
        id: 'a',
        title: 'Open Mic',
        location: 'Love Buzz',
        dateTime: night,
        latitude: 31.7590,
        longitude: -106.4880,
      );
      final b = _event(
        id: 'b',
        title: 'Open Mic',
        location: 'Monarch',
        dateTime: night,
        latitude: 31.7592,
        longitude: -106.4878,
      );
      expect(isSameShow(a, b), isFalse);
      expect(dedupeEvents([a, b]), hasLength(2));
    });

    test('names sharing a word at the same spot are one venue', () {
      // "SWU Park" / "Southwest University Park" share only "park", but sit
      // on the same coordinates: the same title there is the same night.
      final a = _event(
        id: 'tm_1',
        title: 'Fireworks Night',
        location: 'SWU Park',
        dateTime: night,
        latitude: 31.7601,
        longitude: -106.4933,
      );
      final b = _event(
        id: 'sg_1',
        title: 'Fireworks Night',
        location: 'Southwest University Park',
        dateTime: night,
        latitude: 31.7603,
        longitude: -106.4931,
      );
      expect(isSameShow(a, b), isTrue);
      final c = _event(
        id: 'a',
        title: 'Comic Con',
        location: 'El Paso Convention Center',
        dateTime: night,
        latitude: 31.7585,
        longitude: -106.4889,
      );
      final d = _event(
        id: 'b',
        title: 'Comic Con',
        location: 'Judson F. Williams Convention Center',
        dateTime: night,
        latitude: 31.7586,
        longitude: -106.4890,
      );
      expect(isSameShow(c, d), isTrue);
    });

    test('a sports matchup bridges venue names with nothing in common', () {
      final tm = _event(
        id: 'tm_1',
        title: 'El Paso Chihuahuas vs Round Rock Express',
        location: 'The Ballpark',
        dateTime: night,
        latitude: 31.7601,
        longitude: -106.4933,
      );
      final sg = _event(
        id: 'sg_1',
        title: 'Round Rock Express at El Paso Chihuahuas',
        location: 'Southwest University Park',
        dateTime: night,
        latitude: 31.7603,
        longitude: -106.4931,
      );
      expect(isSameShow(tm, sg), isTrue);
      // The same two names with an ordinary title are not enough: that is
      // exactly what two neighbouring venues' same-named nights look like.
      final promo = _event(
        id: 'tm_2',
        title: 'Fireworks Night',
        location: 'The Ballpark',
        dateTime: night,
        latitude: 31.7601,
        longitude: -106.4933,
      );
      final other = _event(
        id: 'sg_2',
        title: 'Fireworks Night',
        location: 'Southwest University Park',
        dateTime: night,
        latitude: 31.7603,
        longitude: -106.4931,
      );
      expect(isSameShow(promo, other), isFalse);
    });

    test('identical names far apart are different branches', () {
      final west = _event(
        id: 'a',
        title: 'Trivia Night',
        location: 'Deadbeach Brewery',
        dateTime: night,
        latitude: 31.7590,
        longitude: -106.4880,
      );
      final east = _event(
        id: 'b',
        title: 'Trivia Night',
        location: 'Deadbeach Brewery',
        dateTime: night,
        latitude: 31.8500,
        longitude: -106.5600,
      );
      expect(isSameShow(west, east), isFalse);
      expect(dedupeEvents([west, east]), hasLength(2));
    });
  });

  group('cross-provider title decoration', () {
    test('a tour name after the artist is dropped', () {
      expect(
        eventTitleCore('Bad Bunny: Debí Tirar Más Fotos World Tour'),
        'bad bunny',
      );
      expect(eventTitleCore("Drake - It's All a Blur Tour"), 'drake');
      expect(eventTitleCore('Segundo Barrio Mural Walking Tour'),
          'segundo barrio mural walking tour');
    });

    test('framing and support acts are dropped', () {
      expect(eventTitleCore('An Evening with Ben Folds'), 'ben folds');
      expect(eventTitleCore('Khruangbin with Special Guest Men I Trust'),
          'khruangbin');
      expect(eventTitleCore('Khruangbin w/ Men I Trust'), 'khruangbin');
      expect(eventTitleCore('Khruangbin Live in Concert'), 'khruangbin');
    });

    test('accents do not split a show', () {
      final a = _event(
        id: 'tm_1',
        title: 'Bad Bunny: Debí Tirar Más Fotos World Tour',
        location: 'Sun Bowl Stadium',
        dateTime: night,
      );
      final b = _event(
        id: 'sg_1',
        title: 'Bad Bunny - Debi Tirar Mas Fotos World Tour',
        location: 'Sun Bowl Stadium',
        dateTime: night,
      );
      final c = _event(
        id: 'evt_ep_sunbowl',
        title: 'Bad Bunny',
        location: 'Sun Bowl Stadium',
        dateTime: night,
      );
      final out = dedupeEvents([c, b, a]);
      expect(out, hasLength(1));
      expect(out.single.id, 'tm_1');
    });

    test('a whole-word prefix at the same venue is the same show', () {
      final a = _event(
        id: 'tm_1',
        title: 'Khruangbin',
        location: 'Abraham Chavez Theatre',
        dateTime: night,
      );
      final b = _event(
        id: 'sg_1',
        title: 'Khruangbin & Friends Holiday Show',
        location: 'Abraham Chavez Theatre',
        dateTime: night,
      );
      expect(isSameShow(a, b), isTrue);
    });

    test('a short or partial-word prefix is not a match', () {
      final yoga = _event(
        id: 'a',
        title: 'Yoga',
        location: 'Sun Studio',
        dateTime: night,
      );
      final nidra = _event(
        id: 'b',
        title: 'Yoga Nidra Workshop',
        location: 'Sun Studio',
        dateTime: night,
      );
      expect(isSameShow(yoga, nidra), isFalse);
      final tool = _event(
        id: 'c',
        title: 'Tool',
        location: 'County Coliseum',
        dateTime: night,
      );
      final tribute = _event(
        id: 'd',
        title: 'Toolbox Comedy Night',
        location: 'County Coliseum',
        dateTime: night,
      );
      expect(isSameShow(tool, tribute), isFalse);
    });

    test('a prefix match needs an exact venue, not just a nearby one', () {
      final a = _event(
        id: 'a',
        title: 'Christmas Concert',
        location: 'First Baptist Church',
        dateTime: night,
        latitude: 31.7600,
        longitude: -106.4900,
      );
      final b = _event(
        id: 'b',
        title: 'Christmas Concert Sing-Along',
        location: 'Grace Chapel',
        dateTime: night,
        latitude: 31.7601,
        longitude: -106.4901,
      );
      expect(isSameShow(a, b), isFalse);
    });

    test('the away-at-home form matches the versus form', () {
      expect(
        sportsMatchupKey('Round Rock Express at El Paso Chihuahuas'),
        sportsMatchupKey('El Paso Chihuahuas vs. Round Rock Express'),
      );
      expect(
        sportsMatchupKey('Sunset at Scenic Drive Overlook'),
        isNot(sportsMatchupKey('Downtown Farmers Market at San Jacinto Plaza')),
      );
    });
  });

  group('merged rows keep the best of both', () {
    test('coordinates are borrowed from the dropped duplicate', () {
      final located = _event(
        id: 'evt_ep_1',
        title: 'Khruangbin',
        location: 'Abraham Chavez Theatre',
        dateTime: night,
        latitude: 31.7574,
        longitude: -106.4907,
      );
      final richer = _event(
        id: 'tm_1',
        title: 'Khruangbin',
        location: 'Abraham Chavez Theatre',
        dateTime: night,
        imageUrl: 'https://s1.ticketm.net/dam/a/khruangbin.jpg',
        sourceUrl: 'https://ticketmaster.com/event/1',
      );
      final out = dedupeEvents([located, richer]).single;
      expect(out.id, 'tm_1');
      expect(out.latitude, closeTo(31.7574, 1e-9));
      expect(out.longitude, closeTo(-106.4907, 1e-9));
    });

    test('three listings of one show leave exactly one row', () {
      final rows = [
        _event(
          id: 'evt_ep_1',
          title: 'Khruangbin',
          location: 'Abraham Chavez Theatre',
          dateTime: night,
          imageUrl: 'assets/venues/abraham_chavez.jpg',
        ),
        _event(
          id: 'sg_1',
          title: 'Khruangbin with Special Guest Men I Trust',
          location: 'Abraham Chavez Theater',
          dateTime: night.add(const Duration(minutes: 30)),
          sourceUrl: 'https://seatgeek.com/e/1',
        ),
        _event(
          id: 'tm_1',
          title: 'Khruangbin',
          location: 'Abraham Chavez Theatre - El Paso',
          dateTime: night,
          sourceUrl: 'https://ticketmaster.com/event/1',
        ),
      ];
      for (final input in [rows, rows.reversed.toList()]) {
        final out = dedupeEvents(input);
        expect(out, hasLength(1));
        expect(out.single.id, 'tm_1');
        expect(out.single.imageUrl, contains('abraham_chavez'));
      }
    });
  });
}
