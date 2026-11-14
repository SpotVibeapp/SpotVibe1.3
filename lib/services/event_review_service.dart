import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:in_app_review/in_app_review.dart';

import '../config/app_config.dart';
import '../models/event_review.dart';

class EventReviewService {
  EventReviewService({
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
    InAppReview? inAppReview,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _functions = functions ?? FirebaseFunctions.instance,
        _inAppReview = inAppReview ?? InAppReview.instance;

  final FirebaseFirestore _db;
  final FirebaseFunctions _functions;
  final InAppReview _inAppReview;

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

  Stream<List<EventReview>> watchEventReviews(String eventId) {
    return _db
        .collection('events')
        .doc(eventId)
        .collection('reviews')
        .orderBy('createdAtMs', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => EventReview.fromMap(d.id, d.data()))
            .where((r) => !r.hidden)
            .toList());
  }

  Stream<List<EventReview>> watchGemEventReviews(String gemId) {
    return _db
        .collection('gems')
        .doc(gemId)
        .collection('event_reviews')
        .orderBy('createdAtMs', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => EventReview.fromMap(d.id, d.data()))
            .where((r) => !r.hidden)
            .toList());
  }

  Stream<ReviewStats> watchStats({
    required String collection,
    required String id,
    String subcollection = 'review_stats',
  }) {
    return _db
        .collection(collection)
        .doc(id)
        .collection(subcollection)
        .doc('aggregate')
        .snapshots()
        .map((snap) => ReviewStats.fromMap(snap.data()));
  }

  Stream<ReviewStats> watchHostStats(String hostId) =>
      watchStats(collection: 'users', id: hostId);

  Stream<List<EventReview>> watchHostReviews(String hostId) {
    return _db
        .collectionGroup('reviews')
        .where('hostId', isEqualTo: hostId)
        .limit(40)
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map((d) => EventReview.fromMap(d.id, d.data()))
          .where((r) => !r.hidden)
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Stream<ReviewStats> watchBusinessStats(String hostId) =>
      watchStats(collection: 'users', id: hostId, subcollection: 'business_review_stats');

  Stream<ReviewStats> watchEventStats(String eventId) =>
      watchStats(collection: 'events', id: eventId);

  Stream<ReviewStats> watchGemStats(String gemId) =>
      watchStats(collection: 'gems', id: gemId);

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
  }

  /// Records that this user RSVP'd to an event that has now ended.
  ///
  /// A "second event" for the Play Store rating prompt means the user has
  /// at least two documents in `ended_rsvps` — each one is an event they
  /// RSVP'd to whose end time (or legacy start time) has already passed.
  Future<void> maybeRequestPlayReview({required String eventId}) async {
    try {
      final out = await _call(AppConfig.recordEndedRsvpFunctionUrl, {
        'eventId': eventId,
      });
      final count = (out['count'] as num?)?.toInt() ?? 0;
      final already = out['alreadyPrompted'] == true;
      if (already || count < 2) return;
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
