import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:in_app_review/in_app_review.dart';

import '../config/app_config.dart';
import '../models/event_review.dart';

/// Event reviews and the Play rating prompt.
///
/// Reviews live in a server-only Firestore collection, so every read and
/// write goes through callables (no Firestore rules change). Reads are
/// cached briefly and refreshed after this device submits or replies.
class EventReviewService {
  EventReviewService({
    FirebaseFunctions? functions,
    InAppReview? inAppReview,
  })  : _functionsOverride = functions,
        _inAppReviewOverride = inAppReview;

  final FirebaseFunctions? _functionsOverride;
  final InAppReview? _inAppReviewOverride;

  FirebaseFunctions get _functions => _functionsOverride ?? FirebaseFunctions.instance;
  InAppReview get _inAppReview => _inAppReviewOverride ?? InAppReview.instance;

  static const Duration _cacheTtl = Duration(seconds: 60);
  static final Map<String, _CachedListing> _cache = {};
  static final StreamController<void> _changes = StreamController<void>.broadcast();

  Future<Map<String, dynamic>> _call(String url, Map<String, dynamic> data) async {
    try {
      final callable = _functions.httpsCallableFromUrl(url);
      final result = await callable.call(data);
      final payload = result.data;
      if (payload is Map) return Map<String, dynamic>.from(payload);
      return {'ok': true};
    } on FirebaseFunctionsException catch (e) {
      debugPrint('event review callable failed (${e.code}): ${e.message}');
      rethrow;
    }
  }

  Future<ReviewListing> _load(ReviewScope scope, String id, {bool force = false}) {
    final key = '${scope.name}:$id';
    final hit = _cache[key];
    if (!force && hit != null && DateTime.now().difference(hit.at) < _cacheTtl) {
      return hit.listing;
    }
    final future = _call(AppConfig.listEventReviewsFunctionUrl, {
      'scope': scope.name,
      'id': id,
      'limit': 50,
    }).then(ReviewListing.fromMap).catchError((Object e) {
      _cache.remove(key);
      debugPrint('reviews unavailable for $key: $e');
      return const ReviewListing();
    });
    _cache[key] = _CachedListing(future, DateTime.now());
    return future;
  }

  /// Emits the listing now and again whenever a review changes on this device.
  Stream<ReviewListing> watchListing(ReviewScope scope, String id) async* {
    if (id.isEmpty) {
      yield const ReviewListing();
      return;
    }
    yield await _load(scope, id);
    await for (final _ in _changes.stream) {
      yield await _load(scope, id, force: true);
    }
  }

  void _invalidate() {
    _cache.clear();
    _changes.add(null);
  }

  Stream<List<EventReview>> watchEventReviews(String eventId) =>
      watchListing(ReviewScope.event, eventId).map((l) => l.reviews);

  Stream<List<EventReview>> watchGemEventReviews(String gemId) =>
      watchListing(ReviewScope.gem, gemId).map((l) => l.reviews);

  Stream<List<EventReview>> watchHostReviews(String hostId) =>
      watchListing(ReviewScope.host, hostId).map((l) => l.reviews);

  Stream<ReviewStats> watchEventStats(String eventId) =>
      watchListing(ReviewScope.event, eventId).map((l) => l.stats);

  Stream<ReviewStats> watchHostStats(String hostId) =>
      watchListing(ReviewScope.host, hostId).map((l) => l.stats);

  Stream<ReviewStats> watchBusinessStats(String hostId) =>
      watchListing(ReviewScope.business, hostId).map((l) => l.stats);

  Stream<ReviewStats> watchGemStats(String gemId) =>
      watchListing(ReviewScope.gem, gemId).map((l) => l.stats);

  Future<void> submitReview({
    required String eventId,
    required int stars,
    required String authorName,
    String note = '',
  }) async {
    await _call(AppConfig.submitEventReviewFunctionUrl, {
      'eventId': eventId,
      'stars': stars,
      'note': note,
      'authorName': authorName,
    });
    _invalidate();
  }

  Future<void> replyToReview({
    required String eventId,
    required String reviewerId,
    required String reply,
  }) async {
    await _call(AppConfig.replyToEventReviewFunctionUrl, {
      'eventId': eventId,
      'reviewerId': reviewerId,
      'reply': reply,
    });
    _invalidate();
  }

  /// Records that this user RSVP'd to an event that has now ended.
  ///
  /// A "second event" for the Play Store rating prompt means the server has
  /// recorded at least two ended events this user RSVP'd to.
  Future<void> maybeRequestPlayReview({required String eventId}) async {
    try {
      final out = await _call(AppConfig.recordEndedRsvpFunctionUrl, {
        'eventId': eventId,
      });
      final count = (out['count'] as num?)?.toInt() ?? 0;
      final already = out['alreadyPrompted'] == true;
      if (!shouldRequestPlayReview(count: count, alreadyPrompted: already)) return;
      if (!await _inAppReview.isAvailable()) return;
      // Call once, then record the attempt so Play's quota is respected
      // and we never prompt again. No incentives and no sentiment gating.
      await _inAppReview.requestReview();
      await _call(AppConfig.markPlayReviewPromptedFunctionUrl, {});
    } on FirebaseFunctionsException catch (e) {
      debugPrint('play review prompt skipped (${e.code}): ${e.message}');
    } catch (e) {
      debugPrint('play review prompt skipped: $e');
    }
  }
}

/// Prompt once, after the user's second ended event they RSVP'd to.
bool shouldRequestPlayReview({required int count, required bool alreadyPrompted}) =>
    !alreadyPrompted && count >= 2;

class _CachedListing {
  final Future<ReviewListing> listing;
  final DateTime at;
  const _CachedListing(this.listing, this.at);
}
