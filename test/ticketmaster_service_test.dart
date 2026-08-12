import 'package:flutter_test/flutter_test.dart';
import 'package:spotvibe_app/models/event.dart';
import 'package:spotvibe_app/services/ticketmaster_service.dart';

void main() {
  test('picks the widest 16:9 Ticketmaster image', () {
    final url = pickTicketmasterImage([
      {'url': 'https://s1.ticketm.net/small.jpg', 'width': 100, 'ratio': '4_3'},
      {
        'url': 'https://s1.ticketm.net/wide.jpg',
        'width': 640,
        'ratio': '16_9',
      },
      {
        'url': 'https://s1.ticketm.net/huge_square.jpg',
        'width': 2000,
        'ratio': '1_1',
      },
    ]);
    expect(url, 'https://s1.ticketm.net/wide.jpg');
  });

  test('maps a Discovery API event to Event with official image', () {
    final event = eventFromTicketmaster({
      'id': 'G5vYZ9abc',
      'name': 'El Paso Chihuahuas vs. Albuquerque Isotopes',
      'url': 'https://www.ticketmaster.com/event/G5vYZ9abc',
      'info': 'Gates open one hour before first pitch.',
      'images': [
        {
          'url': 'https://s1.ticketm.net/dam/chihuahuas.jpg',
          'width': 1024,
          'ratio': '16_9',
        },
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
    expect(
      eventFromTicketmaster({'id': 'x', 'name': 'No Date'}),
      isNull,
    );
  });

  test('unconfigured client does not hit the network', () async {
    final tm = TicketmasterService(apiKey: '');
    expect(tm.isConfigured, isFalse);
    final events = await tm.search(city: 'El Paso', stateCode: 'TX');
    expect(events, isEmpty);
  });
}
