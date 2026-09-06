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
  });

  final String eventId;
  final bool bookmarked;
  final bool interested;

  /// Wall-clock milliseconds since epoch of the last local change.
  final int updatedAtMs;

  EventSave copyWith({bool? bookmarked, bool? interested, int? updatedAtMs}) {
    return EventSave(
      eventId: eventId,
      bookmarked: bookmarked ?? this.bookmarked,
      interested: interested ?? this.interested,
      updatedAtMs: updatedAtMs ?? this.updatedAtMs,
    );
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
