import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

import '../config/app_config.dart';
import '../models/event_message.dart';

class EventMessagingService {
  EventMessagingService({
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _functionsOverride = functions;

  final FirebaseFirestore _db;
  final FirebaseFunctions? _functionsOverride;

  // Resolved lazily so tests can use a fake Firestore without a Firebase app.
  FirebaseFunctions get _functions => _functionsOverride ?? FirebaseFunctions.instance;

  CollectionReference<Map<String, dynamic>> _messages(String eventId) =>
      _db.collection('events').doc(eventId).collection('thread_messages');

  Stream<List<EventMessage>> watchThread(String eventId) {
    return _messages(eventId)
        .orderBy('createdAtMs')
        .limitToLast(200)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => EventMessage.fromMap(d.id, d.data()))
            .where((m) => !m.hidden)
            .toList());
  }

  Stream<int> watchUnreadCount({
    required String eventId,
    required String uid,
  }) {
    final readRef = _db.collection('users').doc(uid).collection('thread_reads').doc(eventId);
    return readRef.snapshots().asyncExpand((readSnap) {
      final last = (readSnap.data()?['lastReadAtMs'] as num?)?.toInt() ?? 0;
      return _messages(eventId)
          .where('createdAtMs', isGreaterThan: last)
          .limit(50)
          .snapshots()
          .map((s) => s.docs.where((d) => d.data()['authorId'] != uid && d.data()['hidden'] != true).length);
    });
  }

  Future<Map<String, dynamic>> _call(String url, Map<String, dynamic> data) async {
    try {
      final callable = _functions.httpsCallableFromUrl(url);
      final result = await callable.call(data);
      final payload = result.data;
      if (payload is Map) {
        return Map<String, dynamic>.from(payload);
      }
      return {'ok': true};
    } on FirebaseFunctionsException catch (e) {
      debugPrint('event messaging callable failed (${e.code}): ${e.message}');
      rethrow;
    }
  }

  Future<String> sendThreadMessage({
    required String eventId,
    required String text,
    required String authorName,
  }) async {
    final out = await _call(AppConfig.sendEventThreadMessageFunctionUrl, {
      'eventId': eventId,
      'text': text,
      'authorName': authorName,
    });
    return out['text'] as String? ?? text;
  }

  Future<void> removeMessage({
    required String eventId,
    required String messageId,
  }) async {
    await _call(AppConfig.removeEventThreadMessageFunctionUrl, {
      'eventId': eventId,
      'messageId': messageId,
    });
  }

  Future<void> setMute({
    required String eventId,
    required bool muted,
    bool? optOutDms,
  }) async {
    await _call(AppConfig.setEventThreadMuteFunctionUrl, {
      'eventId': eventId,
      'muted': muted,
      'optOutDms': optOutDms,
    });
  }

  Future<void> markRead({
    required String eventId,
    String? messageId,
  }) async {
    await _call(AppConfig.markEventThreadReadFunctionUrl, {
      'eventId': eventId,
      'messageId': messageId,
    });
  }

  /// Sends a message in the 1:1 conversation between the event host and
  /// [attendeeId]. An attendee starting a conversation with the host passes
  /// their own uid as [attendeeId]. Returns the conversation id.
  Future<String> sendDirectMessage({
    required String eventId,
    required String attendeeId,
    required String text,
  }) async {
    final out = await _call(AppConfig.sendEventDirectMessageFunctionUrl, {
      'eventId': eventId,
      'attendeeId': attendeeId,
      'text': text,
    });
    return out['threadId'] as String? ?? '';
  }

  /// Clears the caller's unread count on a conversation.
  Future<void> markDirectRead(String threadId) async {
    await _call(AppConfig.markEventDirectReadFunctionUrl, {'threadId': threadId});
  }

  /// The caller's conversations, newest first (the Messages inbox).
  Stream<List<EventDirectThread>> watchInbox(String uid) {
    if (uid.isEmpty) return Stream.value(const []);
    return _db
        .collection('event_dms')
        .where('participants', arrayContains: uid)
        .orderBy('lastMessageAtMs', descending: true)
        .limit(100)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => EventDirectThread.fromMap(d.id, d.data()))
            .toList());
  }

  /// Total unread messages across the caller's conversations.
  Stream<int> watchTotalUnread(String uid) =>
      watchInbox(uid).map((threads) => DirectMessagePolicy.totalUnread(threads, uid));

  /// People the caller has blocked (their conversations are hidden).
  Stream<Set<String>> watchBlockedIds(String uid) {
    if (uid.isEmpty) return Stream.value(const <String>{});
    return _db
        .collection('blocks')
        .doc(uid)
        .collection('blocked')
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.id).toSet());
  }

  String directThreadId({
    required String eventId,
    required String hostId,
    required String attendeeId,
  }) =>
      '${eventId}_${hostId}_${attendeeId}';

  Stream<EventDirectThread?> watchDirectThreadMeta(String threadId) {
    return _db.collection('event_dms').doc(threadId).snapshots().map((snap) {
      final data = snap.data();
      if (!snap.exists || data == null) return null;
      return EventDirectThread.fromMap(snap.id, data);
    });
  }

  Stream<List<EventMessage>> watchDirectMessages(String threadId) {
    return _db
        .collection('event_dms')
        .doc(threadId)
        .collection('dm_messages')
        .orderBy('createdAtMs')
        .limitToLast(200)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => EventMessage.fromMap(d.id, d.data()))
            .where((m) => !m.hidden)
            .toList());
  }

  Future<Map<String, dynamic>?> getMute(String eventId, String uid) async {
    final snap = await _db
        .collection('events')
        .doc(eventId)
        .collection('thread_mutes')
        .doc(uid)
        .get();
    return snap.data();
  }

  Stream<Map<String, int>> watchReceipts(String eventId) {
    return _db
        .collection('events')
        .doc(eventId)
        .collection('thread_receipts')
        .snapshots()
        .map((snap) {
      final out = <String, int>{};
      for (final d in snap.docs) {
        out[d.id] = (d.data()['lastReadAtMs'] as num?)?.toInt() ?? 0;
      }
      return out;
    });
  }
}
