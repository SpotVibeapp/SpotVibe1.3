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
}

class MockEventClaimRepository implements EventClaimRepository {
  final _byKey = <String, EventClaim>{};

  String _key(String eventId, String userId) => '$eventId|$userId';

  @override
  Future<EventClaim> submit(EventClaim claim) async {
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
    );
    _byKey[_key(stored.eventId, stored.userId)] = stored;
    return stored;
  }

  @override
  Future<EventClaim?> latestFor({
    required String eventId,
    required String userId,
  }) async {
    return _byKey[_key(eventId, userId)];
  }

  @override
  Future<bool> isApprovedPromoter({
    required String eventId,
    required String userId,
  }) async {
    return _byKey[_key(eventId, userId)]?.status == ClaimStatus.approved;
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

  @override
  Future<EventClaim> submit(EventClaim claim) {
    return _guard(() async {
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
      );
      await _claims.doc(id).set({
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
      });
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
    return claim?.status == ClaimStatus.approved;
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
    );
  }
}
