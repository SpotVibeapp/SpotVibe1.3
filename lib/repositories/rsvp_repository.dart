import 'package:uuid/uuid.dart';
import '../models/rsvp.dart';

/// RSVP + comment store for a single event.
///
/// - [FirebaseRsvpRepository] — Firestore subcollections
/// - [MockRsvpRepository] — in-memory, seeded fake attendees
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
}

class MockRsvpRepository implements RsvpRepository {
  final _uuid = const Uuid();

  // In-memory stores keyed by eventId — simulates a backend per session.
  final Map<String, List<EventComment>> _comments = {};
  final Map<String, List<RsvpEntry>> _rsvps = {};

  // ─── Comments ──────────────────────────────────────────────────────────────

  Future<List<EventComment>> getComments(String eventId) async {
    await Future.delayed(const Duration(milliseconds: 350));
    if (!_comments.containsKey(eventId)) {
      _comments[eventId] = _seedComments(eventId);
    }
    return List.unmodifiable(_comments[eventId]!);
  }

  Future<EventComment> addComment({
    required String eventId,
    required String text,
    required String authorId,
    required String authorName,
    required String authorAvatar,
  }) async {
    await Future.delayed(const Duration(milliseconds: 150));
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

  // ─── RSVPs ─────────────────────────────────────────────────────────────────

  Future<List<RsvpEntry>> getRsvps(String eventId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (!_rsvps.containsKey(eventId)) {
      _rsvps[eventId] = _seedRsvps(eventId);
    }
    return List.unmodifiable(_rsvps[eventId]!);
  }

  Future<RsvpEntry> addRsvp({
    required String eventId,
    required String userId,
    required String userName,
    required String avatarUrl,
    required bool isPrivate,
  }) async {
    await Future.delayed(const Duration(milliseconds: 150));
    _rsvps.putIfAbsent(eventId, () => _seedRsvps(eventId));
    // Remove any existing RSVP from this user first.
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

  Future<void> removeRsvp({required String eventId, required String userId}) async {
    await Future.delayed(const Duration(milliseconds: 150));
    _rsvps[eventId]?.removeWhere((r) => r.userId == userId);
  }

  // ─── Seed helpers ──────────────────────────────────────────────────────────

  List<EventComment> _seedComments(String eventId) {
    final now = DateTime.now();
    // Use a deterministic offset based on eventId to vary seed data per event.
    final base = eventId.hashCode.abs() % 3;
    final seeds = [
      EventComment(
        id: _uuid.v4(),
        authorId: 'user_2',
        authorName: 'Alex Rivera',
        authorAvatarUrl: 'https://ui-avatars.com/api/?name=Alex+Rivera&background=00B894&color=fff',
        text: 'So excited for this! Anyone else going? 🙌',
        createdAt: now.subtract(const Duration(hours: 5)),
      ),
      EventComment(
        id: _uuid.v4(),
        authorId: 'user_3',
        authorName: 'Jordan Lee',
        authorAvatarUrl: 'https://ui-avatars.com/api/?name=Jordan+Lee&background=E17055&color=fff',
        text: 'I\'ve been to this before — totally worth it. Bring a jacket, it gets chilly!',
        createdAt: now.subtract(const Duration(hours: 3)),
      ),
      EventComment(
        id: _uuid.v4(),
        authorId: 'user_4',
        authorName: 'Sam Chen',
        authorAvatarUrl: 'https://ui-avatars.com/api/?name=Sam+Chen&background=FDAA3D&color=fff',
        text: 'Is there parking nearby? Planning to drive.',
        createdAt: now.subtract(const Duration(hours: 1)),
      ),
    ];
    return seeds.sublist(0, base + 1);
  }

  List<RsvpEntry> _seedRsvps(String eventId) {
    final now = DateTime.now();
    final base = eventId.hashCode.abs() % 4;
    final all = [
      RsvpEntry(
        userId: 'user_2',
        userName: 'Alex Rivera',
        avatarUrl: 'https://ui-avatars.com/api/?name=Alex+Rivera&background=00B894&color=fff',
        rsvpAt: now.subtract(const Duration(days: 2)),
      ),
      RsvpEntry(
        userId: 'user_3',
        userName: 'Jordan Lee',
        avatarUrl: 'https://ui-avatars.com/api/?name=Jordan+Lee&background=E17055&color=fff',
        rsvpAt: now.subtract(const Duration(days: 1)),
      ),
      RsvpEntry(
        userId: 'user_4',
        userName: 'Sam Chen',
        avatarUrl: 'https://ui-avatars.com/api/?name=Sam+Chen&background=FDAA3D&color=fff',
        isPrivate: true,
        rsvpAt: now.subtract(const Duration(hours: 12)),
      ),
      RsvpEntry(
        userId: 'user_5',
        userName: 'Mia Torres',
        avatarUrl: 'https://ui-avatars.com/api/?name=Mia+Torres&background=6C5CE7&color=fff',
        rsvpAt: now.subtract(const Duration(hours: 6)),
      ),
    ];
    return all.sublist(0, base + 1);
  }
}
