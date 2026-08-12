import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../data/event_codec.dart';
import '../models/rsvp.dart';
import 'rsvp_repository.dart';

/// Firestore RSVPs + comments.
///
///   `events/{eventId}/rsvps/{userId}`
///   `events/{eventId}/comments/{commentId}`
///
/// Unlike the mock, we do **not** invent fake attendees. An event with no
/// RSVPs shows an empty list until someone actually goes.
class FirebaseRsvpRepository implements RsvpRepository {
  FirebaseRsvpRepository({
    FirebaseFirestore? firestore,
    RsvpRepository? fallback,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _fallback = fallback ?? MockRsvpRepository();

  final FirebaseFirestore _db;
  final RsvpRepository _fallback;
  final _uuid = const Uuid();
  bool _useFallback = false;

  CollectionReference<Map<String, dynamic>> _rsvps(String eventId) =>
      _db.collection('events').doc(eventId).collection('rsvps');

  CollectionReference<Map<String, dynamic>> _comments(String eventId) =>
      _db.collection('events').doc(eventId).collection('comments');

  Future<T> _guard<T>(Future<T> Function() action, Future<T> Function() orElse) async {
    if (_useFallback) return orElse();
    try {
      return await action();
    } catch (e) {
      debugPrint('Firestore RSVPs unavailable ($e) — using in-memory RSVPs.');
      _useFallback = true;
      return orElse();
    }
  }

  @override
  Future<List<EventComment>> getComments(String eventId) {
    return _guard(() async {
      final snap =
          await _comments(eventId).orderBy('createdAtMs').limit(200).get();
      return snap.docs
          .map((doc) => commentFromMap(doc.id, doc.data()))
          .toList();
    }, () => _fallback.getComments(eventId));
  }

  @override
  Future<EventComment> addComment({
    required String eventId,
    required String text,
    required String authorId,
    required String authorName,
    required String authorAvatar,
  }) {
    return _guard(() async {
      final comment = EventComment(
        id: _uuid.v4(),
        authorId: authorId,
        authorName: authorName,
        authorAvatarUrl: authorAvatar,
        text: text,
        createdAt: DateTime.now(),
      );
      await _comments(eventId).doc(comment.id).set({
        ...commentToMap(comment),
        'createdAt': FieldValue.serverTimestamp(),
      });
      return comment;
    }, () => _fallback.addComment(
          eventId: eventId,
          text: text,
          authorId: authorId,
          authorName: authorName,
          authorAvatar: authorAvatar,
        ));
  }

  @override
  Future<List<RsvpEntry>> getRsvps(String eventId) {
    return _guard(() async {
      final snap = await _rsvps(eventId).get();
      return snap.docs.map((doc) => rsvpFromMap(doc.data())).toList()
        ..sort((a, b) => a.rsvpAt.compareTo(b.rsvpAt));
    }, () => _fallback.getRsvps(eventId));
  }

  @override
  Future<RsvpEntry> addRsvp({
    required String eventId,
    required String userId,
    required String userName,
    required String avatarUrl,
    required bool isPrivate,
  }) {
    return _guard(() async {
      final entry = RsvpEntry(
        userId: userId,
        userName: userName,
        avatarUrl: avatarUrl,
        isPrivate: isPrivate,
        rsvpAt: DateTime.now(),
      );
      await _rsvps(eventId).doc(userId).set({
        ...rsvpToMap(entry),
        'rsvpAt': FieldValue.serverTimestamp(),
      });
      return entry;
    }, () => _fallback.addRsvp(
          eventId: eventId,
          userId: userId,
          userName: userName,
          avatarUrl: avatarUrl,
          isPrivate: isPrivate,
        ));
  }

  @override
  Future<void> removeRsvp({required String eventId, required String userId}) {
    return _guard(() async {
      await _rsvps(eventId).doc(userId).delete();
    }, () => _fallback.removeRsvp(eventId: eventId, userId: userId));
  }
}
