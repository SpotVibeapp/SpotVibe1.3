import 'package:flutter_test/flutter_test.dart';
import 'package:spotvibe_app/models/event.dart';
import 'package:spotvibe_app/models/event_save.dart';

Event _event({bool bookmarked = false, int bookmarkedCount = 0}) {
  return Event(
    id: 'evt_1',
    title: 'Show',
    description: 'd',
    dateTime: DateTime(2026, 12, 31, 19),
    location: 'Plaza Theatre',
    address: '',
    city: 'El Paso',
    state: 'TX',
    imageUrl: '',
    category: 'Arts',
    organizerName: 'Org',
    organizerAvatarUrl: '',
    isBookmarked: bookmarked,
    bookmarkedCount: bookmarkedCount,
  );
}

void main() {
  group('EventSave.applyTo displayed-count consistency', () {
    test('local-only save bumps the displayed count (guest / Ticketmaster)',
        () {
      final save = EventSave(
        eventId: 'evt_1',
        bookmarked: true,
        interested: false,
        updatedAtMs: 1,
        // countedRemotely defaults to false — no Firestore counter includes
        // this user's action.
      );
      final e = save.applyTo(_event(bookmarkedCount: 0));
      expect(e.isBookmarked, isTrue);
      expect(e.bookmarkedCount, 1); // matches the optimistic toggle UI
    });

    test('remotely-counted save does not double-count', () {
      final save = EventSave(
        eventId: 'evt_1',
        bookmarked: true,
        interested: false,
        updatedAtMs: 1,
        countedRemotely: true, // Firestore counter already includes the user
      );
      final e = save.applyTo(_event(bookmarkedCount: 3));
      expect(e.isBookmarked, isTrue);
      expect(e.bookmarkedCount, 3);
    });

    test('applying twice never doubles the bump (idempotent)', () {
      final save = EventSave(
        eventId: 'evt_1',
        bookmarked: true,
        interested: false,
        updatedAtMs: 1,
      );
      final once = save.applyTo(_event(bookmarkedCount: 0));
      final twice = save.applyTo(once);
      expect(twice.bookmarkedCount, 1);
    });

    test('unbookmarked save leaves the count alone', () {
      final save = EventSave(
        eventId: 'evt_1',
        bookmarked: false,
        interested: false,
        updatedAtMs: 1,
      );
      final e = save.applyTo(_event(bookmarked: true, bookmarkedCount: 1));
      expect(e.isBookmarked, isFalse);
      expect(e.bookmarkedCount, 1);
    });
  });
}
