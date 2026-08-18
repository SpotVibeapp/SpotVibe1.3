import 'package:uuid/uuid.dart';
import '../models/rsvp.dart';

/// RSVP + comment store for a single event.
///
/// - [FirebaseRsvpRepository] — Firestore subcollections
/// - [MockRsvpRepository] — in-memory, starts empty (no invented people)
abstract class RsvpRepository {
  Future<List<EventComment>> getComments(String eventId);
  Future<EventComment> addComment({
    required String eventId,
    required String text,
    required String authorId,
    required String authorName,
    required String authorAvatar,
  });
  Future<List<RsvpEntry>> getRsvps(String eventId);
  Future<RsvpEntry> addRsvp({
    required String eventId,
    required String userId,
    required String userName,
    required String avatarUrl,
    required bool isPrivate,
  });
  Future<void> removeRsvp({required String eventId, required String userId});

  /// Removes a comment (admins/moderators, and comment authors).
  Future<void> deleteComment({
    required String eventId,
    required String commentId,
  });
}

class MockRsvpRepository implements RsvpRepository {
  final _uuid = const Uuid();

  final Map<String, List<EventComment>> _comments = {};
  final Map<String, List<RsvpEntry>> _rsvps = {};

  @override
  Future<List<EventComment>> getComments(String eventId) async {
    return List.unmodifiable(_comments[eventId] ?? const []);
  }

  @override
  Future<EventComment> addComment({
    required String eventId,
    required String text,
    required String authorId,
    required String authorName,
    required String authorAvatar,
  }) async {
    final comment = EventComment(
      id: _uuid.v4(),
      authorId: authorId,
      authorName: authorName,
      authorAvatarUrl: authorAvatar,
      text: text,
      createdAt: DateTime.now(),
    );
    _comments.putIfAbsent(eventId, () => []);
    _comments[eventId]!.add(comment);
    return comment;
  }

  @override
  Future<List<RsvpEntry>> getRsvps(String eventId) async {
    return List.unmodifiable(_rsvps[eventId] ?? const []);
  }

  @override
  Future<RsvpEntry> addRsvp({
    required String eventId,
    required String userId,
    required String userName,
    required String avatarUrl,
    required bool isPrivate,
  }) async {
    _rsvps.putIfAbsent(eventId, () => []);
    _rsvps[eventId]!.removeWhere((r) => r.userId == userId);
    final entry = RsvpEntry(
      userId: userId,
      userName: userName,
      avatarUrl: avatarUrl,
      isPrivate: isPrivate,
      rsvpAt: DateTime.now(),
    );
    _rsvps[eventId]!.add(entry);
    return entry;
  }

  @override
  Future<void> removeRsvp({required String eventId, required String userId}) async {
    _rsvps[eventId]?.removeWhere((r) => r.userId == userId);
  }

  @override
  Future<void> deleteComment({
    required String eventId,
    required String commentId,
  }) async {
    _comments[eventId]?.removeWhere((c) => c.id == commentId);
  }
}
