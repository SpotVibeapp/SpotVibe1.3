import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../data/el_paso_events.dart';
import '../data/event_codec.dart';
import '../data/geo_cells.dart';
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
    @visibleForTesting String? Function()? currentUid,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _authOverride = auth,
        _currentUid = currentUid,
        _fallback = fallback ?? MockEventRepository();

  final FirebaseFirestore _db;
  final FirebaseAuth? _authOverride;
  final String? Function()? _currentUid;
  final EventRepository _fallback;
  final LocalSavesStore _localSaves = LocalSavesStore();

  bool _seedAttempted = false;
  bool _useFallback = false;

  CollectionReference<Map<String, dynamic>> get _events =>
      _db.collection('events');

  String? get _uid {
    final override = _currentUid;
    if (override != null) return override();
    return (_authOverride ?? FirebaseAuth.instance).currentUser?.uid;
  }

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

  /// Reads one feed page per source query, all bounded by
  /// `visibleUntilMs >= now` ordered by `visibleUntilMs` (so ended events are
  /// never read) and by [kFeedPageSize]. With an [area] the reads are also
  /// bounded by geohash cells (see geo_cells.dart); first-party listings,
  /// which usually have no coordinates, come from a `kind == 'user'` query.
  ///
  /// Pass the returned [FeedPage.cursor] back as [after] for the next page.
  Future<FeedPage> getFeedPage({
    FeedArea? area,
    String? cityKey,
    FeedCursor? after,
    int pageSize = kFeedPageSize,
    DateTime? now,
  }) async {
    final nowMs = (now ?? DateTime.now()).millisecondsSinceEpoch;
    final plan = after?.plan ?? FeedQueryPlan.forArea(area, cityKey: cityKey);
    final cursor = after ?? FeedCursor._(plan);
    final docs = <String, DocumentSnapshot<Map<String, dynamic>>>{};
    final next = <String, DocumentSnapshot<Map<String, dynamic>>?>{};
    final exhausted = <String>{...cursor._exhausted};

    for (final entry in plan.queries.entries) {
      if (exhausted.contains(entry.key)) continue;
      var query = entry.value(_events)
          .where('visibleUntilMs', isGreaterThanOrEqualTo: nowMs)
          .orderBy('visibleUntilMs');
      final last = cursor._last[entry.key];
      if (last != null) query = query.startAfterDocument(last);
      final snap = await query.limit(pageSize).get();
      for (final doc in snap.docs) {
        docs[doc.id] = doc;
      }
      next[entry.key] = snap.docs.isEmpty ? last : snap.docs.last;
      if (snap.docs.length < pageSize) exhausted.add(entry.key);
    }

    final banned = await BanService.bannedIds(_db);
    final events = docs.values
        .where((d) {
          final cid = d.data()?['creatorId'] as String?;
          return cid == null || !banned.contains(cid);
        })
        .map((d) => eventFromMap(d.id, d.data()!))
        .toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
    return FeedPage(
      events: events,
      cursor: FeedCursor._(
        plan,
        last: {...cursor._last, ...next},
        exhausted: exhausted,
      ),
    );
  }

  /// Up to [kFeedMaxPages] pages, stopping early once [kFeedTargetEvents]
  /// are loaded or every query is exhausted, so one refresh is bounded at
  /// `pages × queries × kFeedPageSize` reads.
  Future<List<Event>> _readFeed({FeedArea? area, String? cityKey}) async {
    final byId = <String, Event>{};
    FeedCursor? cursor;
    for (var page = 0; page < kFeedMaxPages; page++) {
      final result = await getFeedPage(area: area, cityKey: cityKey, after: cursor);
      for (final e in result.events) {
        byId[e.id] = e;
      }
      cursor = result.cursor;
      if (!result.hasMore || byId.length >= kFeedTargetEvents) break;
    }
    return byId.values.toList()..sort((a, b) => a.dateTime.compareTo(b.dateTime));
  }

  /// Pre-release fallback while the composite indexes are building or the
  /// backfill has not run: the old bounded scan, filtered client-side.
  Future<List<Event>> _legacyScan({String? cityKey}) async {
    QuerySnapshot<Map<String, dynamic>> snap;
    if (cityKey != null) {
      try {
        snap = await _events.where('cityKey', isEqualTo: cityKey).limit(200).get();
      } catch (_) {
        snap = await _events.limit(400).get();
      }
    } else {
      snap = await _events.limit(400).get();
    }
    final banned = await BanService.bannedIds(_db);
    return snap.docs
        .where((d) {
          final cid = d.data()['creatorId'] as String?;
          return cid == null || !banned.contains(cid);
        })
        .map((doc) => eventFromMap(doc.id, doc.data()))
        .where((e) => e.isVisibleAt())
        .where((e) => cityKey == null || e.city.toLowerCase() == cityKey)
        .toList();
  }

  Future<List<Event>> _feedOrLegacy({FeedArea? area, String? cityKey}) async {
    try {
      return await _readFeed(area: area, cityKey: cityKey);
    } on FirebaseException catch (e) {
      if (e.code != 'failed-precondition') rethrow;
      debugPrint('Feed index not ready (${e.code}); using the legacy scan.');
      return _legacyScan(cityKey: cityKey);
    }
  }

  @override
  Future<List<Event>> getUpcomingEvents({FeedArea? area}) {
    return _guard(() async {
      await ensureSeeded();
      final events = await _feedOrLegacy(area: area);
      if (events.isEmpty) {
        return _fallback.getUpcomingEvents(area: area);
      }
      return _overlaySaves(events);
    }, () => _fallback.getUpcomingEvents(area: area));
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
    FeedArea? area,
  }) {
    return _guard(() async {
      await ensureSeeded();
      final key = city.toLowerCase().trim();
      final events = await _feedOrLegacy(area: area, cityKey: key);
      if (events.isEmpty) {
        return _fallback.getEventsForLocation(
          city: city,
          state: state,
          zip: zip,
          area: area,
        );
      }
      return _overlaySaves(events);
    },
        () => _fallback.getEventsForLocation(
              city: city,
              state: state,
              zip: zip,
              area: area,
            ));
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

/// Docs per source query per page.
const int kFeedPageSize = 100;

/// Pages read per feed refresh, at most.
const int kFeedMaxPages = 3;

/// A refresh stops paging once this many events are loaded.
const int kFeedTargetEvents = 150;

typedef _QueryBuilder = Query<Map<String, dynamic>> Function(
  CollectionReference<Map<String, dynamic>> events,
);

/// Which bounded queries make up one feed read. Every query is further
/// constrained by `visibleUntilMs >= now`, ordered by `visibleUntilMs` and
/// limited — see firestore.indexes.json for the matching composite indexes:
///   geoCells (CONTAINS) + visibleUntilMs
///   kind + visibleUntilMs
///   cityKey + visibleUntilMs
class FeedQueryPlan {
  FeedQueryPlan._(this.queries, {this.geoCells});

  /// Keyed by a stable name so a [FeedCursor] can resume each query.
  final Map<String, _QueryBuilder> queries;

  /// The geohash cover used, for tests and logging.
  final List<String>? geoCells;

  factory FeedQueryPlan.forArea(FeedArea? area, {String? cityKey}) {
    final queries = <String, _QueryBuilder>{};
    GeoCover? cover;
    if (area != null && !area.isAnyDistance) {
      cover = coverGeoCells(area.lat, area.lng, area.radiusMiles);
    }
    if (cityKey != null && cityKey.isNotEmpty) {
      queries['city'] = (c) => c.where('cityKey', isEqualTo: cityKey);
    }
    if (cover != null) {
      final cells = cover.cells;
      queries['geo'] = (c) => c.where('geoCells', arrayContainsAny: cells);
    }
    if (queries.isEmpty) {
      // "Any distance" (or no usable centre): time-bounded only.
      queries['all'] = (c) => c;
    } else if (!queries.containsKey('city')) {
      // First-party listings rarely carry coordinates; they must never be
      // missed by the geo bound (the app's radius filter keeps rows without
      // coordinates, exactly as before). A city search already reaches them
      // through cityKey.
      queries['firstParty'] = (c) => c.where('kind', isEqualTo: 'user');
    }
    return FeedQueryPlan._(queries, geoCells: cover?.cells);
  }
}

/// Resume point for [FirebaseEventRepository.getFeedPage].
class FeedCursor {
  FeedCursor._(
    this.plan, {
    Map<String, DocumentSnapshot<Map<String, dynamic>>?> last = const {},
    Set<String> exhausted = const {},
  })  : _last = last,
        _exhausted = exhausted;

  final FeedQueryPlan plan;
  final Map<String, DocumentSnapshot<Map<String, dynamic>>?> _last;
  final Set<String> _exhausted;

  bool get hasMore => plan.queries.keys.any((k) => !_exhausted.contains(k));
}

class FeedPage {
  const FeedPage({required this.events, required this.cursor});
  final List<Event> events;
  final FeedCursor cursor;
  bool get hasMore => cursor.hasMore;
}
