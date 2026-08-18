import 'package:cloud_firestore/cloud_firestore.dart';

/// Reads the `bans/{uid}` collection (doc ids = banned user UIDs) with a short
/// in-memory cache. Used by the feed + RSVP repositories to hide content from
/// banned users without hitting Firestore on every read.
class BanService {
  BanService._();

  static Set<String>? _cache;
  static DateTime? _fetchedAt;
  static const _ttl = Duration(seconds: 30);

  static Future<Set<String>> bannedIds(FirebaseFirestore db) async {
    if (_cache != null &&
        _fetchedAt != null &&
        DateTime.now().difference(_fetchedAt!) < _ttl) {
      return _cache!;
    }
    try {
      final snap = await db.collection('bans').get();
      _cache = snap.docs.map((d) => d.id).toSet();
      _fetchedAt = DateTime.now();
      return _cache!;
    } catch (_) {
      // Fail open with whatever we had; banning is a moderation aid, not a
      // hard guarantee when the DB is unreachable.
      return _cache ?? const <String>{};
    }
  }

  static void invalidate() {
    _cache = null;
    _fetchedAt = null;
  }
}
