import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:spotvibe_app/data/calendar_ics.dart';
import 'package:spotvibe_app/platform/picked_media_cache.dart';

void main() {
  test('ics download uses UTC stamps and escapes text', () {
    final ics = buildEventIcs(
      uid: 'evt_1',
      title: 'Night, Market',
      description: 'Line one\nLine two',
      location: 'Plaza; El Paso',
      start: DateTime.utc(2026, 6, 1, 18, 30),
      end: DateTime.utc(2026, 6, 1, 20, 30),
    );
    expect(ics, contains('BEGIN:VCALENDAR'));
    expect(ics, contains('DTSTART:20260601T183000Z'));
    expect(ics, contains('DTEND:20260601T203000Z'));
    expect(ics, contains('SUMMARY:Night\\, Market'));
    expect(ics, contains('DESCRIPTION:Line one\\nLine two'));
    expect(ics, contains('LOCATION:Plaza\\; El Paso'));
    expect(ics, contains('UID:evt_1@spotvibeapp.com'));
  });

  test('picked bytes count as local media on every platform', () {
    PickedMediaCache.clear();
    expect(isLocalMediaPath('https://example.com/a.jpg'), isFalse);
    expect(isLocalMediaPath('blob:http://localhost/abc'), isTrue);
    PickedMediaCache.put('memory-key', Uint8List(4));
    expect(isLocalMediaPath('memory-key'), isTrue);
    PickedMediaCache.clear();
  });
}
