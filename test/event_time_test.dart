import 'package:flutter_test/flutter_test.dart';
import 'package:spotvibe_app/data/event_time.dart';

void main() {
  final now = DateTime(2026, 8, 12, 10, 0); // Wednesday morning

  test('today before evening is Today', () {
    expect(
      formatEventWhen(DateTime(2026, 8, 12, 14, 0), now: now),
      'Today · 2:00 PM',
    );
    expect(formatEventDayChip(DateTime(2026, 8, 12, 14, 0), now: now), 'Today');
  });

  test('today after 5 PM is Tonight', () {
    expect(
      formatEventWhen(DateTime(2026, 8, 12, 19, 30), now: now),
      'Tonight · 7:30 PM',
    );
    expect(formatEventDayChip(DateTime(2026, 8, 12, 19, 30), now: now), 'Tonight');
  });

  test('next calendar day is Tomorrow', () {
    expect(
      formatEventWhen(DateTime(2026, 8, 13, 18, 0), now: now),
      'Tomorrow · 6:00 PM',
    );
    expect(formatEventDayChip(DateTime(2026, 8, 13, 18, 0), now: now), 'Tomorrow');
  });

  test('later this week uses weekday', () {
    expect(
      formatEventWhen(DateTime(2026, 8, 15, 18, 0), now: now),
      'Sat, Aug 15 · 6:00 PM',
    );
    expect(formatEventDayChip(DateTime(2026, 8, 15, 18, 0), now: now), 'Sat');
  });
}
