import 'package:flutter_test/flutter_test.dart';
import 'package:spotvibe_app/data/pricing.dart';
import 'package:spotvibe_app/models/user_event.dart';

void main() {
  test('next weekly occurrence advances 7 days and skips into the future', () {
    final previous = DateTime(2026, 11, 5, 18);
    final now = DateTime(2026, 11, 16, 12);
    final next = nextSeriesOccurrence(previous, RecurringType.weekly, now: now);
    expect(next, DateTime(2026, 11, 19, 18));
  });

  test('next monthly occurrence advances a calendar month', () {
    final previous = DateTime(2026, 10, 15, 19);
    final now = DateTime(2026, 11, 1, 12);
    final next = nextSeriesOccurrence(previous, RecurringType.monthly, now: now);
    expect(next, DateTime(2026, 11, 15, 19));
  });

  test('a one-off continued as a series still advances weekly', () {
    final previous = DateTime(2026, 11, 12, 19);
    final now = DateTime(2026, 11, 16, 12);
    final next = nextSeriesOccurrence(previous, RecurringType.none, now: now);
    expect(next, DateTime(2026, 11, 19, 19));
  });

  test('quotaKey falls back to the event id', () {
    final withSeries = UserCreatedEvent(
      id: 'evt-2',
      creatorId: 'u1',
      title: 'Game night',
      description: 'd',
      dateTime: DateTime(2026, 11, 19, 18),
      location: 'Library',
      address: 'x',
      category: 'Fun & Games',
      organizerName: 'Host',
      createdAt: DateTime(2026, 11, 16),
      seriesId: 'game-night',
    );
    final withoutSeries = UserCreatedEvent(
      id: 'evt-1',
      creatorId: 'u1',
      title: 'One off',
      description: 'd',
      dateTime: DateTime(2026, 11, 20, 18),
      location: 'Park',
      address: 'x',
      category: 'Community',
      organizerName: 'Host',
      createdAt: DateTime(2026, 11, 16),
    );
    expect(withSeries.quotaKey, 'game-night');
    expect(withoutSeries.quotaKey, 'evt-1');
    expect(
      countQuotaPostsInCalendarMonth([
        QuotaPost(
          id: withSeries.id,
          createdAt: withSeries.createdAt,
          seriesId: withSeries.seriesId,
        ),
        QuotaPost(
          id: 'evt-3',
          createdAt: DateTime(2026, 11, 12),
          seriesId: 'game-night',
        ),
        QuotaPost(id: withoutSeries.id, createdAt: withoutSeries.createdAt),
      ], now: DateTime(2026, 11, 16)),
      2,
    );
  });
}
