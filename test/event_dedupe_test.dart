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
  );
}

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
}
