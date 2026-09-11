import 'dart:math' as math;

import 'package:uuid/uuid.dart';

import '../models/gem.dart';

/// Abstract gem store with an in-memory implementation used as a fallback when
/// Firestore is unavailable (mirrors [UserEventRepository]). The Firebase
/// implementation overrides every method.
class GemRepository {
  final List<Gem> _memory = [];
  final Map<String, List<GemComment>> _comments = {};
  final Map<String, Set<String>> _likes = {}; // gemId -> set of uids
  final _uuid = const Uuid();

  /// All non-hidden gems, nearest to [lat]/[lng] first when provided.
  Future<List<Gem>> getGems({
    double? lat,
    double? lng,
    double radiusMiles = 60,
    int limit = 200,
  }) async {
    var list = _memory.where((g) => !g.hidden).toList();
    if (lat != null && lng != null) {
      list = list
          .where((g) =>
              distanceMiles(lat, lng, g.latitude, g.longitude) <= radiusMiles)
          .toList()
        ..sort((a, b) => distanceMiles(lat, lng, a.latitude, a.longitude)
            .compareTo(distanceMiles(lat, lng, b.latitude, b.longitude)));
    } else {
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
    return list.take(limit).toList();
  }

  Future<List<Gem>> getGemsForUser(String creatorId) async {
    return _memory.where((g) => g.creatorId == creatorId).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<Gem?> getGemById(String id, {String? viewerId}) async {
    for (final g in _memory) {
      if (g.id == id) {
        final liked = viewerId != null && (_likes[id]?.contains(viewerId) ?? false);
        return g.copyWith(likedByMe: liked);
      }
    }
    return null;
  }

  Future<Gem> createGem(Gem gem) async {
    final stored = gem.id.isNotEmpty ? gem : _withId(gem, _uuid.v4());
    _memory.add(stored);
    return stored;
  }

  /// Overwrites the editable fields of an existing gem, preserving its id,
  /// creator, counters and creation time.
  Future<Gem> updateGem(Gem gem) async {
    final idx = _memory.indexWhere((g) => g.id == gem.id);
    if (idx < 0) return gem;
    _memory[idx] = gem;
    return gem;
  }

  /// Admin moderation: hide or unhide a gem without deleting it.
  Future<void> setHidden(String gemId, bool hidden) async {
    final idx = _memory.indexWhere((g) => g.id == gemId);
    if (idx >= 0) {
      _memory[idx] = _memory[idx].copyWith(hidden: hidden);
    }
  }

  /// Returns every gem regardless of hidden state — for admin moderation.
  Future<List<Gem>> getAllForModeration({int limit = 300}) async {
    final list = List<Gem>.from(_memory)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list.take(limit).toList();
  }

  Gem _withId(Gem gem, String id) => Gem(
        id: id,
        creatorId: gem.creatorId,
        creatorName: gem.creatorName,
        name: gem.name,
        category: gem.category,
        summary: gem.summary,
        description: gem.description,
        latitude: gem.latitude,
        longitude: gem.longitude,
        address: gem.address,
        city: gem.city,
        state: gem.state,
        imageUrls: gem.imageUrls,
        likeCount: gem.likeCount,
        commentCount: gem.commentCount,
        likedByMe: gem.likedByMe,
        hidden: gem.hidden,
        createdAt: gem.createdAt,
      );

  GemComment _commentWithId(GemComment c, String id) => GemComment(
        id: id,
        authorId: c.authorId,
        authorName: c.authorName,
        authorAvatarUrl: c.authorAvatarUrl,
        text: c.text,
        hidden: c.hidden,
        createdAt: c.createdAt,
      );

  Future<void> deleteGem(String id) async {
    _memory.removeWhere((g) => g.id == id);
    _comments.remove(id);
    _likes.remove(id);
  }

  /// Toggle a like; returns the new like state (true = liked).
  Future<bool> toggleLike(String gemId, String uid) async {
    final set = _likes.putIfAbsent(gemId, () => <String>{});
    final liked = !set.contains(uid);
    if (liked) {
      set.add(uid);
    } else {
      set.remove(uid);
    }
    final idx = _memory.indexWhere((g) => g.id == gemId);
    if (idx >= 0) {
      _memory[idx] = _memory[idx].copyWith(likeCount: set.length);
    }
    return liked;
  }

  Future<List<GemComment>> getComments(String gemId) async {
    final list = List<GemComment>.from(_comments[gemId] ?? const [])
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list.where((c) => !c.hidden).toList();
  }

  Future<GemComment> addComment(String gemId, GemComment comment) async {
    final stored =
        comment.id.isNotEmpty ? comment : _commentWithId(comment, _uuid.v4());
    final list = _comments.putIfAbsent(gemId, () => []);
    list.add(stored);
    final idx = _memory.indexWhere((g) => g.id == gemId);
    if (idx >= 0) {
      _memory[idx] =
          _memory[idx].copyWith(commentCount: list.where((c) => !c.hidden).length);
    }
    return stored;
  }

  Future<void> deleteComment(String gemId, String commentId) async {
    _comments[gemId]?.removeWhere((c) => c.id == commentId);
    final idx = _memory.indexWhere((g) => g.id == gemId);
    if (idx >= 0) {
      _memory[idx] = _memory[idx].copyWith(
          commentCount: (_comments[gemId] ?? const []).where((c) => !c.hidden).length);
    }
  }

  static double distanceMiles(
      double lat1, double lng1, double lat2, double lng2) {
    const earthMiles = 3958.8;
    double toRad(double d) => d * math.pi / 180.0;
    final dLat = toRad(lat2 - lat1);
    final dLng = toRad(lng2 - lng1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(toRad(lat1)) *
            math.cos(toRad(lat2)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    return earthMiles * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }
}
