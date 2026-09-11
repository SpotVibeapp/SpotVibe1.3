import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../data/gem_codec.dart';
import '../models/gem.dart';
import 'gem_repository.dart';

/// Persists community gems to `gems/{id}` with `gems/{id}/comments/{id}` and
/// `gems/{id}/likes/{uid}` subcollections. Falls back to the in-memory store
/// when Firestore is unavailable (mirrors [FirebaseUserEventRepository]).
class FirebaseGemRepository extends GemRepository {
  FirebaseGemRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;
  final _uuid = const Uuid();
  bool _useFallback = false;

  CollectionReference<Map<String, dynamic>> get _gems => _db.collection('gems');

  Future<T> _guard<T>(
      Future<T> Function() action, Future<T> Function() orElse) async {
    if (_useFallback) return orElse();
    try {
      return await action();
    } catch (e) {
      debugPrint('Firestore gems unavailable ($e) — using in-memory store.');
      _useFallback = true;
      return orElse();
    }
  }

  @override
  Future<List<Gem>> getGems({
    double? lat,
    double? lng,
    double radiusMiles = 60,
    int limit = 200,
  }) {
    return _guard(() async {
      // Firestore has no geo query out of the box; pull the newest gems and
      // filter/sort by distance client-side. Fine at community scale.
      final snap = await _gems
          .orderBy('createdAtMs', descending: true)
          .limit(500)
          .get();
      var list = snap.docs
          .map((d) => gemFromMap(d.id, d.data()))
          .where((g) => !g.hidden)
          .toList();
      if (lat != null && lng != null) {
        list = list
            .where((g) =>
                GemRepository.distanceMiles(lat, lng, g.latitude, g.longitude) <=
                radiusMiles)
            .toList()
          ..sort((a, b) => GemRepository.distanceMiles(
                  lat, lng, a.latitude, a.longitude)
              .compareTo(GemRepository.distanceMiles(
                  lat, lng, b.latitude, b.longitude)));
      }
      return list.take(limit).toList();
    }, () => super.getGems(lat: lat, lng: lng, radiusMiles: radiusMiles, limit: limit));
  }

  @override
  Future<List<Gem>> getGemsForUser(String creatorId) {
    return _guard(() async {
      final snap =
          await _gems.where('creatorId', isEqualTo: creatorId).limit(100).get();
      return snap.docs.map((d) => gemFromMap(d.id, d.data())).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }, () => super.getGemsForUser(creatorId));
  }

  @override
  Future<Gem?> getGemById(String id, {String? viewerId}) {
    return _guard(() async {
      final doc = await _gems.doc(id).get();
      if (!doc.exists) return null;
      var liked = false;
      if (viewerId != null && viewerId.isNotEmpty && viewerId != 'guest') {
        final likeDoc = await _gems.doc(id).collection('likes').doc(viewerId).get();
        liked = likeDoc.exists;
      }
      return gemFromMap(doc.id, doc.data()!, likedByMe: liked);
    }, () => super.getGemById(id, viewerId: viewerId));
  }

  @override
  Future<Gem> createGem(Gem gem) {
    return _guard(() async {
      final id = gem.id.isNotEmpty ? gem.id : _uuid.v4();
      final stored = gem.copyWith();
      await _gems.doc(id).set(gemToMap(stored));
      return gemFromMap(id, gemToMap(stored));
    }, () => super.createGem(
          gem.id.isNotEmpty ? gem : _withId(gem, _uuid.v4()),
        ));
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
        hidden: gem.hidden,
        createdAt: gem.createdAt,
      );

  @override
  Future<Gem> updateGem(Gem gem) {
    return _guard(() async {
      // Only overwrite the editable content fields, so like/comment counters
      // and createdAtMs written by other clients/functions are preserved.
      final map = gemToMap(gem);
      map.remove('likeCount');
      map.remove('commentCount');
      map.remove('createdAtMs');
      await _gems.doc(gem.id).set(map, SetOptions(merge: true));
      return gem;
    }, () => super.updateGem(gem));
  }

  @override
  Future<void> setHidden(String gemId, bool hidden) {
    return _guard(() async {
      await _gems.doc(gemId).update({'hidden': hidden});
    }, () => super.setHidden(gemId, hidden));
  }

  @override
  Future<List<Gem>> getAllForModeration({int limit = 300}) {
    return _guard(() async {
      final snap = await _gems
          .orderBy('createdAtMs', descending: true)
          .limit(limit)
          .get();
      return snap.docs.map((d) => gemFromMap(d.id, d.data())).toList();
    }, () => super.getAllForModeration(limit: limit));
  }

  @override
  Future<void> deleteGem(String id) {
    return _guard(() async {
      await _gems.doc(id).delete();
    }, () => super.deleteGem(id));
  }

  @override
  Future<bool> toggleLike(String gemId, String uid) {
    return _guard(() async {
      final likeRef = _gems.doc(gemId).collection('likes').doc(uid);
      final gemRef = _gems.doc(gemId);
      final existing = await likeRef.get();
      final liked = !existing.exists;
      final batch = _db.batch();
      if (liked) {
        batch.set(likeRef, {'createdAtMs': DateTime.now().millisecondsSinceEpoch});
        batch.update(gemRef, {'likeCount': FieldValue.increment(1)});
      } else {
        batch.delete(likeRef);
        batch.update(gemRef, {'likeCount': FieldValue.increment(-1)});
      }
      await batch.commit();
      return liked;
    }, () => super.toggleLike(gemId, uid));
  }

  @override
  Future<List<GemComment>> getComments(String gemId) {
    return _guard(() async {
      final snap = await _gems
          .doc(gemId)
          .collection('comments')
          .orderBy('createdAtMs', descending: true)
          .limit(200)
          .get();
      return snap.docs
          .map((d) => gemCommentFromMap(d.id, d.data()))
          .where((c) => !c.hidden)
          .toList();
    }, () => super.getComments(gemId));
  }

  @override
  Future<GemComment> addComment(String gemId, GemComment comment) {
    return _guard(() async {
      final id = comment.id.isNotEmpty ? comment.id : _uuid.v4();
      final ref = _gems.doc(gemId).collection('comments').doc(id);
      await ref.set(gemCommentToMap(comment));
      await _gems.doc(gemId).update({'commentCount': FieldValue.increment(1)});
      return gemCommentFromMap(id, gemCommentToMap(comment));
    }, () => super.addComment(gemId, comment));
  }

  @override
  Future<void> deleteComment(String gemId, String commentId) {
    return _guard(() async {
      await _gems.doc(gemId).collection('comments').doc(commentId).delete();
      await _gems.doc(gemId).update({'commentCount': FieldValue.increment(-1)});
    }, () => super.deleteComment(gemId, commentId));
  }
}
