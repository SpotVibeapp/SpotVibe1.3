import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../data/pricing.dart';
import '../models/event_claim.dart';

abstract class EventClaimRepository {
  Future<EventClaim> submit(
    EventClaim claim, {
    required bool isPremium,
  });
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
  Future<EventClaim> submit(EventClaim claim, {required bool isPremium}) async {
    final prior = await countUnlockedForUser(claim.userId);
    final firstFree = claimUnlocksWithoutPay(
      priorUnlockedClaims: prior,
      isPremium: isPremium,
    );
    final workEmail = isValidEmail(claim.email) && !isPersonalEmail(claim.email);
    final approved = workEmail;
    final unlocked = approved && (firstFree || isPremium);
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
      status: approved ? ClaimStatus.approved : ClaimStatus.pending,
      createdAt: claim.createdAt,
      firstClaimFree: firstFree,
      unlocked: unlocked,
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
    var count = 0;
    for (final entry in _byId.entries.toList()) {
      final claim = entry.value;
      if (claim.userId != userId) continue;
      if (claim.status != ClaimStatus.approved || claim.unlocked) continue;
      _byId[entry.key] = claim.copyWith(unlocked: true);
      count++;
    }
    return count;
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
  Future<EventClaim> submit(EventClaim claim, {required bool isPremium}) {
    return _guard(() async {
      final prior = await countUnlockedForUser(claim.userId);
      final firstFree = claimUnlocksWithoutPay(
        priorUnlockedClaims: prior,
        isPremium: isPremium,
      );
      final workEmail = isValidEmail(claim.email) && !isPersonalEmail(claim.email);
      final approved = workEmail;
      final unlocked = approved && (firstFree || isPremium);
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
        status: approved ? ClaimStatus.approved : ClaimStatus.pending,
        createdAt: claim.createdAt,
        firstClaimFree: firstFree,
        unlocked: unlocked,
      );
      await _claims.doc(id).set(_toMap(stored));
      return stored;
    }, () => _fallback.submit(claim, isPremium: isPremium));
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
  Future<int> unlockEligibleForUser(String userId) {
    return _guard(() async {
      final snap = await _claims.where('userId', isEqualTo: userId).limit(50).get();
      var count = 0;
      final batch = _db.batch();
      for (final doc in snap.docs) {
        final data = doc.data();
        if (data['status'] != ClaimStatus.approved.name) continue;
        if (data['unlocked'] == true) continue;
        batch.update(doc.reference, {'unlocked': true});
        count++;
      }
      if (count > 0) await batch.commit();
      return count;
    }, () => _fallback.unlockEligibleForUser(userId));
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
  Future<void> updateClaimStatus(String claimId, {required bool approve}) {
    return _guard(() async {
      await _claims.doc(claimId).update({
        'status': approve ? ClaimStatus.approved.name : ClaimStatus.rejected.name,
        'unlocked': approve,
      });
    }, () => _fallback.updateClaimStatus(claimId, approve: approve));
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
