import 'event.dart';

/// Per-user save state for a single event (bookmark / interested flags).
///
/// Persisted locally via [LocalSavesStore] (guests + offline queue) and
/// mirrored to Firestore `users/{uid}/saved_events/{eventId}` for signed-in
/// users. `updatedAtMs` lets the two stores be merged by recency.
class EventSave {
  const EventSave({
    required this.eventId,
    required this.bookmarked,
    required this.interested,
    required this.updatedAtMs,
    this.countedRemotely = false,
  });

  final String eventId;
  final bool bookmarked;
  final bool interested;

  /// Wall-clock milliseconds since epoch of the last local change.
  final int updatedAtMs;

  /// Whether the event's public `bookmarkedCount` / `interestedCount` in
  /// Firestore already includes this user's save. True only for signed-in
  /// saves on events that have a Firestore doc (curated / user-created).
  /// Ticketmaster events have no doc and guests never write counters, so
  /// their saves stay `false` and the displayed count is adjusted locally
  /// instead — otherwise every feed refresh reset the counter the user just
  /// bumped.
  final bool countedRemotely;

  EventSave copyWith({bool? bookmarked, bool? interested, int? updatedAtMs}) {
    return EventSave(
      eventId: eventId,
      bookmarked: bookmarked ?? this.bookmarked,
      interested: interested ?? this.interested,
      updatedAtMs: updatedAtMs ?? this.updatedAtMs,
      countedRemotely: countedRemotely,
    );
  }

  /// Applies this save onto an event for display: sets the flag state, and
  /// when the server-side counter cannot include the user's own action
  /// (guests / Ticketmaster events — [countedRemotely] false) bumps the
  /// displayed count by their own action so it matches what the optimistic
  /// toggle showed and no longer "resets" on the next feed refresh.
  Event applyTo(Event event) {
    var e = event.copyWith(
      isBookmarked: bookmarked,
      isInterested: interested,
    );
    if (!countedRemotely) {
      if (bookmarked && !event.isBookmarked) {
        e = e.copyWith(bookmarkedCount: e.bookmarkedCount + 1);
      }
      if (interested && !event.isInterested) {
        e = e.copyWith(interestedCount: e.interestedCount + 1);
      }
    }
    return e;
  }

  factory EventSave.fromJson(String eventId, Map<String, dynamic> json) {
    return EventSave(
      eventId: eventId,
      bookmarked: json['b'] == true,
      interested: json['i'] == true,
      updatedAtMs: (json['t'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {'b': bookmarked, 'i': interested, 't': updatedAtMs};
}
