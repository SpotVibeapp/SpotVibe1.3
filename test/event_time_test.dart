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

  test('keeps an event visible while its explicit end time is still ahead', () {
    final start = DateTime(2026, 8, 12, 9, 0);
    final end = DateTime(2026, 8, 12, 13, 0);
    final during = DateTime(2026, 8, 12, 10, 0);
    final after = DateTime(2026, 8, 12, 13, 0);

    expect(hasValidEventWindow(start, end), isTrue);
    expect(hasValidEventWindow(start, null), isFalse);
    expect(hasValidEventWindow(start, start), isFalse);
    expect(isEventHappeningNow(start, end, now: during), isTrue);
    expect(isEventVisibleInFeed(start, end, now: during), isTrue);
    expect(isEventVisibleInFeed(start, end, now: after), isFalse);
  });

  test('does not guess that a legacy started event is still live', () {
    final start = DateTime(2026, 8, 12, 9, 0);
    final now = DateTime(2026, 8, 12, 10, 0);

    expect(isEventHappeningNow(start, null, now: now), isFalse);
    expect(isEventVisibleInFeed(start, null, now: now), isFalse);
  });

  test('formats a same-day start and end time range', () {
    expect(
      formatEventTimeRange(
        DateTime(2026, 8, 12, 18, 0),
        DateTime(2026, 8, 12, 21, 30),
      ),
      'Wednesday, August 12, 2026 · 6:00 PM – 9:30 PM',
    );
  });

  test('next calendar day is Tomorrow', () {
    expect(
      formatEventWhen(DateTime(2026, 8, 13, 18, 0), now: now),
      'Tomorrow · 6:00 PM',
    );
    expect(formatEventDayChip(DateTime(2026, 8, 13, 18, 0), now: now), 'Tomorrow');
  });

  test('an event is ended after its end time, or after start when it has no end', () {
    final start = DateTime(2026, 8, 12, 9, 0);
    final end = DateTime(2026, 8, 12, 13, 0);
    expect(isEventEnded(start, end, now: DateTime(2026, 8, 12, 12, 59)), isFalse);
    expect(isEventEnded(start, end, now: DateTime(2026, 8, 12, 13, 0)), isTrue);
    expect(isEventEnded(start, null, now: DateTime(2026, 8, 12, 8, 59)), isFalse);
    expect(isEventEnded(start, null, now: DateTime(2026, 8, 12, 9, 0)), isTrue);
  });

  test('later this week uses weekday', () {
    expect(
      formatEventWhen(DateTime(2026, 8, 15, 18, 0), now: now),
      'Sat, Aug 15 · 6:00 PM',
    );
    expect(formatEventDayChip(DateTime(2026, 8, 15, 18, 0), now: now), 'Sat');
  });
}
