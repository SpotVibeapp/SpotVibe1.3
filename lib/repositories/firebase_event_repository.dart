import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../data/el_paso_events.dart';
import '../data/event_codec.dart';
import '../models/event.dart';
import 'event_repository.dart';

/// Firestore-backed [EventRepository].
///
/// Collections:
///   `events/{eventId}`              curated + user-created feed docs
///   `users/{uid}/saved_events/{id}` per-user bookmark / interested flags
///   `meta/event_seed`               seed version so we only upsert once
///
/// Falls back to [MockEventRepository] (curated El Paso only) if Firestore
/// is unreachable or rules haven't been published yet.
class FirebaseEventRepository implements EventRepository {
  FirebaseEventRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    EventRepository? fallback,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _fallback = fallback ?? MockEventRepository();

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;
  final EventRepository _fallback;

  bool _seedAttempted = false;
  bool _useFallback = false;

  CollectionReference<Map<String, dynamic>> get _events =>
      _db.collection('events');

  String? get _uid => _auth.currentUser?.uid;

  Future<T> _guard<T>(Future<T> Function() action, Future<T> Function() orElse) async {
    if (_useFallback) return orElse();
    try {
      return await action();
    } catch (e) {
      debugPrint('Firestore events unavailable ($e) — using mock events.');
      _useFallback = true;
      return orElse();
    }
  }

  /// Idempotent: writes curated El Paso events if the seed doc is missing
  /// or older than [kElPasoSeedVersion].
  Future<void> ensureSeeded() async {
    if (_seedAttempted || _useFallback) return;
    _seedAttempted = true;
    try {
      final meta = _db.collection('meta').doc('event_seed');
      final snap = await meta.get();
      final current = (snap.data()?['version'] as num?)?.toInt() ?? 0;
      if (current >= kElPasoSeedVersion) return;

      final midnight = DateTime(
        DateTime.now().year,
        DateTime.now().month,
        DateTime.now().day,
      );
      final batch = _db.batch();
      for (final event in buildElPasoSeedEvents(midnight)) {
        batch.set(
          _events.doc(event.id),
          {
            ...eventToMap(event),
            'dateTime': Timestamp.fromDate(event.dateTime),
            'seeded': true,
          },
          SetOptions(merge: true),
        );
      }
      batch.set(meta, {
        'version': kElPasoSeedVersion,
        'city': kElPasoCity,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      await batch.commit();
      debugPrint('Seeded El Paso events v$kElPasoSeedVersion to Firestore.');
    } catch (e) {
      debugPrint('Event seed failed ($e) — mock feed will be used if reads fail.');
    }
  }

  @override
  Future<List<Event>> getUpcomingEvents() {
    return _guard(() async {
      await ensureSeeded();
      final snap = await _events.limit(400).get();
      var events = snap.docs
          .map((doc) => eventFromMap(doc.id, doc.data()))
          .toList();
      if (events.isEmpty) {
        return _fallback.getUpcomingEvents();
      }
      events = await _overlaySaves(events);
      return events;
    }, _fallback.getUpcomingEvents);
  }

  @override
  Future<Event?> getEventById(String id) {
    return _guard(() async {
      await ensureSeeded();
      final doc = await _events.doc(id).get();
      if (!doc.exists || doc.data() == null) {
        return _fallback.getEventById(id);
      }
      final overlaid = await _overlaySaves([eventFromMap(doc.id, doc.data()!)]);
      return overlaid.first;
    }, () => _fallback.getEventById(id));
  }

  @override
  Future<List<Event>> getEventsForLocation({
    required String city,
    required String state,
    required String zip,
  }) {
    return _guard(() async {
      await ensureSeeded();
      final key = city.toLowerCase().trim();
      QuerySnapshot<Map<String, dynamic>> snap;
      try {
        snap = await _events.where('cityKey', isEqualTo: key).limit(200).get();
      } catch (_) {
        // cityKey index may be missing — filter client-side.
        snap = await _events.limit(400).get();
      }
      var events = snap.docs
          .map((doc) => eventFromMap(doc.id, doc.data()))
          .where((e) => e.city.toLowerCase() == key)
          .toList();
      if (events.isEmpty) {
        return _fallback.getEventsForLocation(
          city: city,
          state: state,
          zip: zip,
        );
      }
      return _overlaySaves(events);
    }, () => _fallback.getEventsForLocation(city: city, state: state, zip: zip));
  }

  @override
  Future<void> toggleBookmark(String eventId) {
    return _guard(() async {
      await _toggleSave(eventId, field: 'bookmarked');
    }, () => _fallback.toggleBookmark(eventId));
  }

  @override
  Future<void> toggleInterested(String eventId) {
    return _guard(() async {
      await _toggleSave(eventId, field: 'interested');
    }, () => _fallback.toggleInterested(eventId));
  }

  Future<void> _toggleSave(String eventId, {required String field}) async {
    final uid = _uid;
    if (uid == null) {
      // Guests: persist only for this process via the mock.
      if (field == 'bookmarked') {
        await _fallback.toggleBookmark(eventId);
      } else {
        await _fallback.toggleInterested(eventId);
      }
      return;
    }
    final saveRef =
        _db.collection('users').doc(uid).collection('saved_events').doc(eventId);
    final eventRef = _events.doc(eventId);
    await _db.runTransaction((tx) async {
      final saveSnap = await tx.get(saveRef);
      final eventSnap = await tx.get(eventRef);
      final currently = saveSnap.data()?[field] == true;
      final next = !currently;
      tx.set(saveRef, {
        field: next,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      if (eventSnap.exists) {
        final countField =
            field == 'bookmarked' ? 'bookmarkedCount' : 'interestedCount';
        tx.update(eventRef, {
          countField: FieldValue.increment(next ? 1 : -1),
        });
      }
    });
  }

  Future<List<Event>> _overlaySaves(List<Event> events) async {
    final uid = _uid;
    if (uid == null || events.isEmpty) return events;
    try {
      final saves = await _db
          .collection('users')
          .doc(uid)
          .collection('saved_events')
          .get();
      final byId = {for (final d in saves.docs) d.id: d.data()};
      return events
          .map((e) {
            final save = byId[e.id];
            if (save == null) return e;
            return e.copyWith(
              isBookmarked: save['bookmarked'] == true,
              isInterested: save['interested'] == true,
            );
          })
          .toList();
    } catch (_) {
      return events;
    }
  }
}
