import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../data/el_paso_events.dart';
import '../data/event_codec.dart';
import '../models/event.dart';
import '../models/event_save.dart';
import '../services/ban_service.dart';
import 'event_repository.dart';
import 'local_saves_store.dart';

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
  final LocalSavesStore _localSaves = LocalSavesStore();

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
      final banned = await BanService.bannedIds(_db);
      var events = snap.docs
          .where((d) {
            final cid = d.data()['creatorId'] as String?;
            return cid == null || !banned.contains(cid);
          })
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
      final banned = await BanService.bannedIds(_db);
      final creatorId = doc.data()!['creatorId'] as String?;
      if (creatorId != null && banned.contains(creatorId)) {
        return null; // hidden from banned users' content
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
      final banned = await BanService.bannedIds(_db);
      var events = snap.docs
          .where((d) {
            final cid = d.data()['creatorId'] as String?;
            return cid == null || !banned.contains(cid);
          })
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
  Future<Map<String, EventSave>> getSaves() async {
    // Deliberately NOT routed through [_guard]: a failed saves read (e.g.
    // transient rules/offline hiccup) must not latch the whole feed into
    // mock-fallback mode — it only degrades the save overlay.
    if (_useFallback) return _localSaves.load();
    try {
      final uid = _uid;
      // Guests: the device-local store is the only store.
      if (uid == null) return await _localSaves.load();

      final snap = await _db
          .collection('users')
          .doc(uid)
          .collection('saved_events')
          .get();
      final saves = <String, EventSave>{};
      for (final d in snap.docs) {
        final data = d.data();
        saves[d.id] = EventSave(
          eventId: d.id,
          bookmarked: data['bookmarked'] == true,
          interested: data['interested'] == true,
          updatedAtMs: (data['updatedAt'] as Timestamp?)?.millisecondsSinceEpoch ?? 0,
          // True when the mirror transaction also updated the event doc's
          // counters — only possible for events with a Firestore doc.
          countedRemotely: data['countedRemotely'] == true,
        );
      }
      // Device-local entries are optimistic writes that may not have synced
      // yet (offline / failed write). The most recent change wins.
      final local = await _localSaves.load();
      local.forEach((id, l) {
        final remote = saves[id];
        if (remote == null || l.updatedAtMs > remote.updatedAtMs) {
          saves[id] = l;
        }
      });
      return saves;
    } catch (e) {
      debugPrint('Saved-events read failed ($e) — using device-local saves.');
      return _localSaves.load();
    }
  }

  @override
  Future<void> setSave(
    String eventId, {
    required bool bookmarked,
    required bool interested,
  }) async {
    // Optimistic device-local write FIRST — a failed or slow network write
    // must never silently discard the user's action.
    if (bookmarked || interested) {
      await _localSaves.set(eventId, bookmarked: bookmarked, interested: interested);
    } else {
      await _localSaves.remove(eventId);
    }

    final uid = _uid;
    if (uid == null) return; // guest — local store is authoritative

    final synced = await _guardWrite(
      () => _mirrorSave(uid, eventId,
          bookmarked: bookmarked, interested: interested),
    );
    if (synced) {
      // Synced successfully — drop the local override so Firestore stays the
      // single source of truth for signed-in users.
      await _localSaves.remove(eventId);
    } else {
      // Keep the local entry; it wins the merge in [getSaves] until the
      // write succeeds, and re-syncs on the next toggle.
    }
  }

  /// Mirrors one save to Firestore. Must only be called for a signed-in
  /// user (guests would be rejected by the security rules).
  Future<void> _mirrorSave(
    String uid,
    String eventId, {
    required bool bookmarked,
    required bool interested,
  }) async {
    final saveRef =
        _db.collection('users').doc(uid).collection('saved_events').doc(eventId);
    final eventRef = _events.doc(eventId);
    await _db.runTransaction((tx) async {
      final saveSnap = await tx.get(saveRef);
      final eventSnap = await tx.get(eventRef);
      final prevBookmarked = saveSnap.data()?['bookmarked'] == true;
      final prevInterested = saveSnap.data()?['interested'] == true;

      if (!bookmarked && !interested) {
        // Fully unsaved — remove the doc so the collection stays tidy.
        if (saveSnap.exists) await tx.delete(saveRef);
      } else {
        await tx.set(saveRef, {
          'bookmarked': bookmarked,
          'interested': interested,
          // Whether the event doc's public counters include this save.
          // Ticketmaster listings have no doc, so their saves can never be
          // counted remotely — the UI adjusts the displayed count locally.
          'countedRemotely': eventSnap.exists,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      if (eventSnap.exists) {
        // Ticketmaster listings have no Firestore doc — only counters on
        // docs that exist are updated.
        final updates = <String, FieldValue>{};
        if (prevBookmarked != bookmarked) {
          updates['bookmarkedCount'] = FieldValue.increment(bookmarked ? 1 : -1);
        }
        if (prevInterested != interested) {
          updates['interestedCount'] = FieldValue.increment(interested ? 1 : -1);
        }
        if (updates.isNotEmpty) await tx.update(eventRef, updates);
      }
    });
  }

  /// Like [_guard] for user-triggered writes, but never latches the mock
  /// fallback: a failed save must not downgrade the whole live feed.
  /// Returns whether the write reached Firestore.
  Future<bool> _guardWrite(Future<void> Function() action) async {
    if (_useFallback) return false;
    try {
      await action();
      return true;
    } catch (e) {
      debugPrint('Firestore write failed ($e).');
      return false;
    }
  }

  Future<List<Event>> _overlaySaves(List<Event> events) async {
    if (events.isEmpty) return events;
    try {
      final saves = await getSaves();
      if (saves.isEmpty) return events;
      return events
          .map((e) {
            final s = saves[e.id];
            if (s == null) return e;
            return e.copyWith(
              isBookmarked: s.bookmarked,
              isInterested: s.interested,
            );
          })
          .toList();
    } catch (_) {
      return events;
    }
  }
}
