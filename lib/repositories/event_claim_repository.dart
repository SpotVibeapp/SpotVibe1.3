import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/event_claim.dart';

abstract class EventClaimRepository {
  Future<EventClaim> submit(EventClaim claim);
  Future<EventClaim?> latestFor({
    required String eventId,
    required String userId,
  });
  Future<bool> isApprovedPromoter({
    required String eventId,
    required String userId,
  });
  Future<int> countUnlockedForUser(String userId);
  Future<int> unlockEligibleForUser(String userId);

  /// All claims, newest first (admin moderation).
  Future<List<EventClaim>> getClaims();

  /// Approve (unlock for editing) or reject a claim (admin moderation).
  Future<void> updateClaimStatus(String claimId, {required bool approve});
}

class MockEventClaimRepository implements EventClaimRepository {
  final _byId = <String, EventClaim>{};

  EventClaim? _latest(String eventId, String userId) {
    EventClaim? match;
    for (final claim in _byId.values) {
      if (claim.eventId == eventId && claim.userId == userId) {
        if (match == null || claim.createdAt.isAfter(match.createdAt)) {
          match = claim;
        }
      }
    }
    return match;
  }

  @override
  Future<EventClaim> submit(EventClaim claim) async {
    // Claims must be approved by an admin. Client-side email and plan checks
    // are not an authorization boundary and must never auto-grant edit access.
    final stored = EventClaim(
      id: claim.id.isEmpty ? const Uuid().v4() : claim.id,
      eventId: claim.eventId,
      eventTitle: claim.eventTitle,
      venueName: claim.venueName,
      userId: claim.userId,
      fullName: claim.fullName,
      email: claim.email,
      phone: claim.phone,
      organization: claim.organization,
      role: claim.role,
      proofMethod: claim.proofMethod,
      proofUrl: claim.proofUrl,
      statement: claim.statement,
      status: ClaimStatus.pending,
      createdAt: claim.createdAt,
      firstClaimFree: false,
      unlocked: false,
    );
    _byId[stored.id] = stored;
    return stored;
  }

  @override
  Future<EventClaim?> latestFor({
    required String eventId,
    required String userId,
  }) async {
    return _latest(eventId, userId);
  }

  @override
  Future<bool> isApprovedPromoter({
    required String eventId,
    required String userId,
  }) async {
    return _latest(eventId, userId)?.canEditListing == true;
  }

  @override
  Future<int> countUnlockedForUser(String userId) async {
    return _byId.values.where((c) => c.userId == userId && c.unlocked).length;
  }

  @override
  Future<int> unlockEligibleForUser(String userId) async {
    // Only an admin approval can grant listing ownership. A client-side
    // purchase result must never flip an arbitrary claim to editable.
    return 0;
  }

  @override
  Future<List<EventClaim>> getClaims() async {
    final list = _byId.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  @override
  Future<void> updateClaimStatus(String claimId, {required bool approve}) async {
    final claim = _byId[claimId];
    if (claim == null) return;
    _byId[claimId] = claim.copyWith(
      status: approve ? ClaimStatus.approved : ClaimStatus.rejected,
      unlocked: approve ? true : claim.unlocked,
    );
  }
}

class FirebaseEventClaimRepository implements EventClaimRepository {
  FirebaseEventClaimRepository({
    FirebaseFirestore? firestore,
    EventClaimRepository? fallback,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _fallback = fallback ?? MockEventClaimRepository();

  final FirebaseFirestore _db;
  final EventClaimRepository _fallback;
  bool _useFallback = false;

  CollectionReference<Map<String, dynamic>> get _claims =>
      _db.collection('event_claims');

  Future<T> _guard<T>(
    Future<T> Function() action,
    Future<T> Function() orElse,
  ) async {
    if (_useFallback) return orElse();
    try {
      return await action();
    } catch (e) {
      debugPrint('Firestore claims unavailable ($e) — using in-memory claims.');
      _useFallback = true;
      return orElse();
    }
  }

  Map<String, dynamic> _toMap(EventClaim stored) {
    return {
      'eventId': stored.eventId,
      'eventTitle': stored.eventTitle,
      'venueName': stored.venueName,
      'userId': stored.userId,
      'fullName': stored.fullName,
      'email': stored.email,
      'phone': stored.phone,
      'organization': stored.organization,
      'role': stored.role.name,
      'proofMethod': stored.proofMethod.name,
      'proofUrl': stored.proofUrl,
      'statement': stored.statement,
      'status': stored.status.name,
      'createdAtMs': stored.createdAt.millisecondsSinceEpoch,
      'firstClaimFree': stored.firstClaimFree,
      'unlocked': stored.unlocked,
    };
  }

  @override
  Future<EventClaim> submit(EventClaim claim) {
    return _guard(() async {
      // A claimant can submit proof, but only an admin can approve it and hand
      // the listing to the verified venue/promoter. Never trust client-side
      // subscription/email checks to unlock an event.
      final id = claim.id.isEmpty ? const Uuid().v4() : claim.id;
      final stored = EventClaim(
        id: id,
        eventId: claim.eventId,
        eventTitle: claim.eventTitle,
        venueName: claim.venueName,
        userId: claim.userId,
        fullName: claim.fullName,
        email: claim.email,
        phone: claim.phone,
        organization: claim.organization,
        role: claim.role,
        proofMethod: claim.proofMethod,
        proofUrl: claim.proofUrl,
        statement: claim.statement,
        status: ClaimStatus.pending,
        createdAt: claim.createdAt,
        firstClaimFree: false,
        unlocked: false,
      );
      await _claims.doc(id).set(_toMap(stored));
      return stored;
    }, () => _fallback.submit(claim));
  }

  @override
  Future<EventClaim?> latestFor({
    required String eventId,
    required String userId,
  }) {
    return _guard(() async {
      final snap = await _claims
          .where('eventId', isEqualTo: eventId)
          .where('userId', isEqualTo: userId)
          .limit(5)
          .get();
      if (snap.docs.isEmpty) return null;
      final docs = snap.docs.toList()
        ..sort((a, b) {
          final am = (a.data()['createdAtMs'] as num?)?.toInt() ?? 0;
          final bm = (b.data()['createdAtMs'] as num?)?.toInt() ?? 0;
          return bm.compareTo(am);
        });
      return _fromMap(docs.first.id, docs.first.data());
    }, () => _fallback.latestFor(eventId: eventId, userId: userId));
  }

  @override
  Future<bool> isApprovedPromoter({
    required String eventId,
    required String userId,
  }) async {
    final claim = await latestFor(eventId: eventId, userId: userId);
    return claim?.canEditListing == true;
  }

  @override
  Future<int> countUnlockedForUser(String userId) {
    return _guard(() async {
      final snap = await _claims.where('userId', isEqualTo: userId).limit(50).get();
      return snap.docs.where((d) => d.data()['unlocked'] == true).length;
    }, () => _fallback.countUnlockedForUser(userId));
  }

  @override
  Future<int> unlockEligibleForUser(String userId) async {
    // See the mock implementation: claim ownership is granted only by the
    // admin approval transaction below, never by an untrusted client update.
    return 0;
  }

  @override
  Future<List<EventClaim>> getClaims() {
    return _guard(() async {
      final snap = await _claims.limit(200).get();
      final list = snap.docs
          .map((d) => _fromMap(d.id, d.data()))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    }, () => _fallback.getClaims());
  }

  @override
  Future<void> updateClaimStatus(String claimId, {required bool approve}) async {
    // This is a privileged admin operation. Do not fall back to an in-memory
    // success if Firestore rejects it, or the dashboard could claim that a
    // venue owns a listing when no server-side handoff occurred.
    if (_useFallback) {
      await _fallback.updateClaimStatus(claimId, approve: approve);
      return;
    }

    final claimRef = _claims.doc(claimId);
    try {
      await _db.runTransaction((transaction) async {
        final claimSnap = await transaction.get(claimRef);
        if (!claimSnap.exists || claimSnap.data() == null) {
          throw StateError('Claim not found.');
        }
        final claim = _fromMap(claimSnap.id, claimSnap.data()!);

        if (!approve) {
          transaction.update(claimRef, {
            'status': ClaimStatus.rejected.name,
            'unlocked': false,
          });
          return;
        }

        // Approval is an ownership handoff. This makes a listing originally
        // posted by SpotVibe/admin claimable by the verified venue/promoter,
        // while security rules continue to give admins moderation control.
        final eventRef = _db.collection('events').doc(claim.eventId);
        final mirrorRef = _db.collection('user_events').doc(claim.eventId);
        final eventSnap = await transaction.get(eventRef);
        final mirrorSnap = await transaction.get(mirrorRef);
        if (!eventSnap.exists || eventSnap.data() == null) {
          throw StateError('The listing no longer exists.');
        }

        final now = DateTime.now();
        final ownership = <String, dynamic>{
          'creatorId': claim.userId,
          'claimedByUid': claim.userId,
          'claimedAtMs': now.millisecondsSinceEpoch,
          'claimedAt': FieldValue.serverTimestamp(),
          'kind': 'user',
        };
        final mirrorPayload = <String, dynamic>{
          ...eventSnap.data()!,
          ...ownership,
          // Curated/admin posts might not yet have a user_events mirror.
          'createdAtMs': mirrorSnap.data()?['createdAtMs'] ?? now.millisecondsSinceEpoch,
        };

        transaction.update(claimRef, {
          'status': ClaimStatus.approved.name,
          'unlocked': true,
          'firstClaimFree': true,
          'approvedAt': FieldValue.serverTimestamp(),
        });
        transaction.set(eventRef, ownership, SetOptions(merge: true));
        transaction.set(mirrorRef, mirrorPayload, SetOptions(merge: true));
      });
    } catch (error) {
      debugPrint('Claim approval failed: $error');
      rethrow;
    }
  }

  EventClaim _fromMap(String id, Map<String, dynamic> data) {
    ClaimRole role = ClaimRole.other;
    for (final value in ClaimRole.values) {
      if (value.name == data['role']) role = value;
    }
    ClaimProofMethod proof = ClaimProofMethod.officialEmail;
    for (final value in ClaimProofMethod.values) {
      if (value.name == data['proofMethod']) proof = value;
    }
    ClaimStatus status = ClaimStatus.pending;
    for (final value in ClaimStatus.values) {
      if (value.name == data['status']) status = value;
    }
    return EventClaim(
      id: id,
      eventId: data['eventId'] as String? ?? '',
      eventTitle: data['eventTitle'] as String? ?? '',
      venueName: data['venueName'] as String? ?? '',
      userId: data['userId'] as String? ?? '',
      fullName: data['fullName'] as String? ?? '',
      email: data['email'] as String? ?? '',
      phone: data['phone'] as String? ?? '',
      organization: data['organization'] as String? ?? '',
      role: role,
      proofMethod: proof,
      proofUrl: data['proofUrl'] as String? ?? '',
      statement: data['statement'] as String? ?? '',
      status: status,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        (data['createdAtMs'] as num?)?.toInt() ??
            DateTime.now().millisecondsSinceEpoch,
      ),
      firstClaimFree: data['firstClaimFree'] as bool? ?? false,
      unlocked: data['unlocked'] as bool? ?? false,
    );
  }
}
