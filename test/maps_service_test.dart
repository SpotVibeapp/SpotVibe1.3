import 'package:flutter_test/flutter_test.dart';
import 'package:spotvibe_app/models/event.dart';
import 'package:spotvibe_app/services/maps_service.dart';

Event _event({
  double lat = 0,
  double lng = 0,
  String address = '',
  String location = 'Plaza Theatre',
  String city = 'El Paso',
  String state = 'TX',
}) {
  return Event(
    id: 't',
    title: 'Show',
    description: 'd',
    dateTime: DateTime(2026, 8, 16, 19),
    location: location,
    address: address,
    city: city,
    state: state,
    imageUrl: '',
    category: 'Arts',
    organizerName: 'Org',
    organizerAvatarUrl: '',
    latitude: lat,
    longitude: lng,
  );
}

void main() {
  test('prefers coordinates when present', () {
    final event = _event(lat: 31.7588, lng: -106.4875);
    expect(MapsService.destinationQuery(event), '31.7588,-106.4875');
    expect(
      MapsService.googleDirectionsUri(event).toString(),
      contains('destination=31.7588%2C-106.4875'),
    );
  });

  test('falls back to address when coords are missing', () {
    final event = _event(address: '125 Pioneer Plaza');
    expect(MapsService.destinationQuery(event), contains('Pioneer Plaza'));
    expect(MapsService.destinationQuery(event), contains('El Paso'));
  });

  test('Apple Maps uses daddr', () {
    final event = _event(lat: 31.76, lng: -106.49);
    expect(
      MapsService.appleDirectionsUri(event).toString(),
      startsWith('https://maps.apple.com/?daddr='),
    );
  });
}
