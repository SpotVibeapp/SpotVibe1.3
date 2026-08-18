import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../data/event_codec.dart';
import '../models/event.dart';
import '../models/user_report.dart';
import '../services/ban_service.dart';

/// Admin / moderation data source.
///
/// - [FirebaseModerationRepository] — reads `user_reports` + the events feed
///   and performs admin deletes and bans (security rules gate these to admins).
/// - [MockModerationRepository] — empty in-memory fallback for dev/tests.
abstract class ModerationRepository {
  Future<List<UserReport>> getReports();
  Future<void> resolveReport(String reportId);
  Future<List<Event>> getEvents();
  Future<void> deleteEvent(String eventId);
  Future<void> deleteComment({required String eventId, required String commentId});

  Future<List<String>> getBannedUserIds();
  Future<void> banUser(String userId);
  Future<void> unbanUser(String userId);
}

class MockModerationRepository implements ModerationRepository {
  final Set<String> _banned = {};

  @override
  Future<List<UserReport>> getReports() async => const [];

  @override
  Future<void> resolveReport(String reportId) async {}

  @override
  Future<List<Event>> getEvents() async => const [];

  @override
  Future<void> deleteEvent(String eventId) async {}

  @override
  Future<void> deleteComment({
    required String eventId,
    required String commentId,
  }) async {}

  @override
  Future<List<String>> getBannedUserIds() async => _banned.toList();

  @override
  Future<void> banUser(String userId) async => _banned.add(userId);

  @override
  Future<void> unbanUser(String userId) async => _banned.remove(userId);
}

class FirebaseModerationRepository implements ModerationRepository {
  FirebaseModerationRepository({
    FirebaseFirestore? firestore,
    ModerationRepository? fallback,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _fallback = fallback ?? MockModerationRepository();

  final FirebaseFirestore _db;
  final ModerationRepository _fallback;
  bool _useFallback = false;

  Future<T> _guard<T>(
    Future<T> Function() action,
    Future<T> Function() orElse,
  ) async {
    if (_useFallback) return orElse();
    try {
      return await action();
    } catch (e) {
      debugPrint('Moderation unavailable ($e) — using fallback.');
      _useFallback = true;
      return orElse();
    }
  }

  @override
  Future<List<UserReport>> getReports() {
    return _guard(() async {
      final snap = await _db
          .collection('user_reports')
          .orderBy('createdAt', descending: true)
          .limit(100)
          .get();
      return snap.docs.map((d) {
        final data = d.data();
        final ms = (data['createdAt'] as Timestamp?)?.millisecondsSinceEpoch;
        return UserReport(
          id: d.id,
          reportedUserId: data['reportedUserId'] as String? ?? '',
          reportedById: data['reportedById'] as String? ?? '',
          reason: data['reason'] as String? ?? '',
          createdAt: ms != null
              ? DateTime.fromMillisecondsSinceEpoch(ms)
              : DateTime.now(),
        );
      }).toList();
    }, () => _fallback.getReports());
  }

  @override
  Future<void> resolveReport(String reportId) {
    return _guard(() async {
      await _db.collection('user_reports').doc(reportId).delete();
    }, () => _fallback.resolveReport(reportId));
  }

  @override
  Future<List<Event>> getEvents() {
    return _guard(() async {
      final snap = await _db.collection('events').limit(200).get();
      return snap.docs
          .map((d) => eventFromMap(d.id, d.data()))
          .toList()
        ..sort((a, b) => b.dateTime.compareTo(a.dateTime));
    }, () => _fallback.getEvents());
  }

  @override
  Future<void> deleteEvent(String eventId) {
    return _guard(() async {
      final batch = _db.batch();
      batch.delete(_db.collection('events').doc(eventId));
      batch.delete(_db.collection('user_events').doc(eventId));
      await batch.commit();
    }, () => _fallback.deleteEvent(eventId));
  }

  @override
  Future<void> deleteComment({
    required String eventId,
    required String commentId,
  }) {
    return _guard(() async {
      await _db
          .collection('events')
          .doc(eventId)
          .collection('comments')
          .doc(commentId)
          .delete();
    }, () => _fallback.deleteComment(eventId: eventId, commentId: commentId));
  }

  @override
  Future<List<String>> getBannedUserIds() {
    return _guard(() async {
      final snap = await _db.collection('bans').get();
      return snap.docs.map((d) => d.id).toList()..sort();
    }, () => _fallback.getBannedUserIds());
  }

  @override
  Future<void> banUser(String userId) {
    return _guard(() async {
      await _db.collection('bans').doc(userId).set({
        'bannedAt': FieldValue.serverTimestamp(),
      });
      BanService.invalidate();
    }, () => _fallback.banUser(userId));
  }

  @override
  Future<void> unbanUser(String userId) {
    return _guard(() async {
      await _db.collection('bans').doc(userId).delete();
      BanService.invalidate();
    }, () => _fallback.unbanUser(userId));
  }
}
