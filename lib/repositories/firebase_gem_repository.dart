import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../config/app_config.dart';
import '../data/gem_codec.dart';
import '../data/geo_cells.dart';
import '../models/gem.dart';
import 'gem_repository.dart';

/// Persists community gems to `gems/{id}` with `gems/{id}/comments/{id}` and
/// `gems/{id}/likes/{uid}` subcollections. Falls back to the in-memory store
/// when Firestore is unavailable (mirrors [FirebaseUserEventRepository]).
class FirebaseGemRepository extends GemRepository {
  FirebaseGemRepository({
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFirestore _db;
  final FirebaseFunctions _functions;
  bool _callableSaveUnavailable = false;
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
  Future<GemQueryPage> queryGems({
    double? lat,
    double? lng,
    double radiusMiles = 60,
    int limit = 40,
    Object? startAfter,
  }) {
    return _guard(() async {
      try {
        return await _queryByGeo(
          lat: lat,
          lng: lng,
          radiusMiles: radiusMiles,
          limit: limit,
          startAfter: startAfter,
        );
      } catch (e) {
        debugPrint('Gem geo query failed ($e) — falling back to newest-first scan.');
        return _legacyQuery(
          lat: lat,
          lng: lng,
          radiusMiles: radiusMiles,
          limit: limit,
        );
      }
    }, () => super.queryGems(
          lat: lat,
          lng: lng,
          radiusMiles: radiusMiles,
          limit: limit,
          startAfter: startAfter,
        ));
  }

  Future<GemQueryPage> _queryByGeo({
    double? lat,
    double? lng,
    required double radiusMiles,
    required int limit,
    Object? startAfter,
  }) async {
    final cover = (lat != null && lng != null)
        ? coverGeoCells(lat, lng, radiusMiles)
        : null;
    Query<Map<String, dynamic>> query = _gems.where('hidden', isEqualTo: false);
    if (cover != null && cover.cells.isNotEmpty) {
      query = query.where('geoCells', arrayContainsAny: cover.cells);
    }
    query = query.orderBy('createdAtMs', descending: true).limit(limit);
    if (startAfter is DocumentSnapshot<Map<String, dynamic>>) {
      query = query.startAfterDocument(startAfter);
    }
    final snap = await query.get();
    var gems = snap.docs.map((d) => gemFromMap(d.id, d.data())).toList();
    if (lat != null && lng != null) {
      gems = gems
          .where((g) =>
              GemRepository.distanceMiles(lat, lng, g.latitude, g.longitude) <=
              radiusMiles)
          .toList();
    }
    return GemQueryPage(
      gems: gems,
      cursor: snap.docs.isEmpty ? null : snap.docs.last,
      hasMore: snap.docs.length >= limit,
    );
  }

  Future<GemQueryPage> _legacyQuery({
    double? lat,
    double? lng,
    required double radiusMiles,
    required int limit,
  }) async {
    final list = await getGems(lat: lat, lng: lng, radiusMiles: radiusMiles, limit: 200);
    return GemQueryPage(gems: list.take(limit).toList(), hasMore: list.length > limit);
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
      final stored = gem.id.isNotEmpty ? gem : _withId(gem, id);
      return _saveGem(stored, isCreate: true);
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
        likedByMe: gem.likedByMe,
        hidden: gem.hidden,
        createdAt: gem.createdAt,
        approvedAt: gem.approvedAt,
        visibleToFreeAt: gem.visibleToFreeAt,
        listingKind: gem.listingKind,
        richUntil: gem.richUntil,
        richActivatedAt: gem.richActivatedAt,
        contactPhone: gem.contactPhone,
        contactWebsite: gem.contactWebsite,
        socialLinks: gem.socialLinks,
        promoTitle: gem.promoTitle,
        promoDetails: gem.promoDetails,
        promoStartsAt: gem.promoStartsAt,
        promoEndsAt: gem.promoEndsAt,
      );

  /// Client-side basic card used only when [saveGem] is not deployed yet.
  /// Never writes promotional fields, contact, photos or a client richUntil.
  @visibleForTesting
  static Map<String, dynamic> basicShapedFallback(Map<String, dynamic> raw) {
    final out = Map<String, dynamic>.of(raw);
    out['listingKind'] = 'community';
    out['description'] = '';
    out['imageUrls'] = <String>[];
    for (final key in [
      'richUntilMs',
      'richActivatedAtMs',
      'contactPhone',
      'contactWebsite',
      'contactSocial',
      'socialLinks',
      'promoTitle',
      'promoDetails',
      'promoStartsAtMs',
      'promoEndsAtMs',
      'archivedRich',
    ]) {
      out.remove(key);
    }
    return out;
  }

  Future<Gem> _saveGem(Gem gem, {required bool isCreate}) async {
    if (!_callableSaveUnavailable) {
      try {
        return await _saveThroughCallable(gem, isCreate: isCreate);
      } on FirebaseFunctionsException catch (e) {
        if (e.code == 'failed-precondition' ||
            e.code == 'unauthenticated' ||
            e.code == 'permission-denied' ||
            e.code == 'invalid-argument') {
          rethrow;
        }
        debugPrint('saveGem callable failed (${e.code}): $e');
        if (e.code != 'not-found' &&
            e.code != 'unavailable' &&
            e.code != 'unimplemented' &&
            e.code != 'internal') {
          rethrow;
        }
        _callableSaveUnavailable = true;
      } catch (e) {
        debugPrint('saveGem callable failed: $e');
        _callableSaveUnavailable = true;
      }
    }
    final payload = basicShapedFallback(gemToMap(gem));
    if (isCreate) {
      await _gems.doc(gem.id).set(payload);
    } else {
      // Merge only basic fields so a downed callable cannot wipe a live
      // promotional listing.
      payload.remove('likeCount');
      payload.remove('commentCount');
      payload.remove('createdAtMs');
      await _gems.doc(gem.id).set(payload, SetOptions(merge: true));
    }
    return gemFromMap(gem.id, payload);
  }

  Future<Gem> _saveThroughCallable(Gem gem, {required bool isCreate}) async {
    final callable =
        _functions.httpsCallableFromUrl(AppConfig.saveGemFunctionUrl);
    final payload = Map<String, dynamic>.of(gemToMap(gem));
    payload['id'] = gem.id;
    payload.remove('createdAt');
    payload.remove('updatedAt');
    final result = await callable.call<Map<String, dynamic>>({
      'isCreate': isCreate,
      'activateRich': gem.listingKind == GemListingKind.business,
      'gem': payload,
    });
    final data = Map<String, dynamic>.from(result.data);
    final saved = data['gem'] is Map
        ? Map<String, dynamic>.from(data['gem'] as Map)
        : payload;
    return gemFromMap(gem.id, saved);
  }

  @override
  Future<Gem> updateGem(Gem gem) {
    return _guard(() async {
      return _saveGem(gem, isCreate: false);
    }, () => super.updateGem(gem));
  }

  @override
  Future<Gem> renewGemRich(
    String gemId, {
    required String requestingUserId,
    bool isAdmin = false,
  }) {
    return _guard(() async {
      final callable =
          _functions.httpsCallableFromUrl(AppConfig.renewGemRichFunctionUrl);
      final result = await callable.call<Map<String, dynamic>>({
        'gemId': gemId,
      });
      final data = Map<String, dynamic>.from(result.data);
      final latest = await _gems.doc(gemId).get();
      if (latest.exists) {
        return gemFromMap(gemId, latest.data()!);
      }
      // Callable succeeded but the read missed; synthesize from the response.
      final existing = await getGemById(gemId);
      if (existing == null) {
        throw StateError('This gem no longer exists.');
      }
      final untilMs = data['richUntilMs'];
      return existing.copyWith(
        listingKind: GemListingKind.business,
        richUntil: untilMs is num
            ? DateTime.fromMillisecondsSinceEpoch(untilMs.toInt())
            : DateTime.now().add(const Duration(days: 30)),
        richActivatedAt: DateTime.now(),
      );
    }, () => super.renewGemRich(
          gemId,
          requestingUserId: requestingUserId,
          isAdmin: isAdmin,
        ));
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
