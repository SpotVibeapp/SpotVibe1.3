import 'package:flutter_test/flutter_test.dart';
import 'package:spotvibe_app/data/repeated_event_imagery.dart';
import 'package:spotvibe_app/models/event.dart';

Event _event({
  required String id,
  required String title,
  required DateTime dateTime,
  String location = 'Southwest University Park',
  String imageUrl = '',
  String description = 'Game',
}) {
  return Event(
    id: id,
    title: title,
    description: description,
    dateTime: dateTime,
    location: location,
    address: '1 Ballpark',
    imageUrl: imageUrl,
    category: 'Sports',
    organizerName: 'Chihuahuas',
    organizerAvatarUrl: '',
  );
}

void main() {
  final friday = DateTime(2026, 11, 20, 19, 5);
  final saturday = DateTime(2026, 11, 21, 18, 5);

  test('generic Ticketmaster stock is grouped by series, not the stock URL', () {
    const stock =
        'https://s1.ticketm.net/dam/c/aaa/baseball-glove_16_9.jpg';
    final a = _event(
      id: 'a',
      title: 'El Paso Chihuahuas vs. Round Rock Express',
      dateTime: friday,
      imageUrl: stock,
    );
    final b = _event(
      id: 'b',
      title: 'El Paso Chihuahuas vs. Round Rock Express',
      dateTime: saturday,
      imageUrl: stock,
    );
    expect(repeatedImageryKey(a), startsWith('series:'));
    expect(repeatedImageryKey(a), repeatedImageryKey(b));
    final badge = repeatedEventBadgeFor(a, [a, b], locale: 'en_US');
    expect(badge, isNotNull);
    expect(badge!.dateLabel.toUpperCase(), contains('NOV'));
    expect(badge.dateLabel.toUpperCase(), contains('20'));
  });

  test('unique photos that are shared still get a date badge', () {
    const art = 'https://s1.ticketm.net/dam/a/abc/chihuahuas-team.jpg';
    final a = _event(id: 'a', title: 'Chihuahuas', dateTime: friday, imageUrl: art);
    final b = _event(id: 'b', title: 'Chihuahuas', dateTime: saturday, imageUrl: art);
    expect(repeatedImageryKey(a), startsWith('img:'));
    expect(repeatedEventBadgeFor(a, [a, b], locale: 'en_US'), isNotNull);
    expect(repeatedEventBadgeFor(a, [a], locale: 'en_US'), isNull);
  });

  test('parses an opponent and a game number from the title', () {
    expect(
      parseOpponent('El Paso Chihuahuas vs. Albuquerque Isotopes'),
      'Albuquerque Isotopes',
    );
    expect(parseGameNumber('Chihuahuas Game 3 of 5'), (3, 5));
  });
}
