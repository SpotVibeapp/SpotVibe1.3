import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

import '../config/app_config.dart';
import '../data/pricing.dart';

class FoundingMemberSnapshot {
  final int claimedCount;
  final bool userIsMember;

  const FoundingMemberSnapshot({
    required this.claimedCount,
    required this.userIsMember,
  });

  int get remaining => foundingSlotsLeft(claimedCount);
  bool get slotsOpen => foundingSlotsRemain(claimedCount);
}

abstract class FoundingMemberRepository {
  Future<FoundingMemberSnapshot> load({String? userId});

  /// Reserves a founding slot for [userId] when one is left.
  /// Idempotent if they already hold a slot.
  Future<FoundingMemberSnapshot> claimSlot(String userId);
}

class MockFoundingMemberRepository implements FoundingMemberRepository {
  final List<String> memberIds;

  MockFoundingMemberRepository({List<String>? seedIds})
      : memberIds = List<String>.from(seedIds ?? const []);

  @override
  Future<FoundingMemberSnapshot> load({String? userId}) async {
    return FoundingMemberSnapshot(
      claimedCount: memberIds.length,
      userIsMember: userId != null && memberIds.contains(userId),
    );
  }

  @override
  Future<FoundingMemberSnapshot> claimSlot(String userId) async {
    if (!memberIds.contains(userId) && foundingSlotsRemain(memberIds.length)) {
      memberIds.add(userId);
    }
    return load(userId: userId);
  }
}

/// Reads the founding roster from `meta/founding` (public, read-only) and
/// claims slots through the `claimFoundingSlot` Cloud Function, which
/// verifies the RevenueCat founding purchase and updates the roster in a
/// transaction. Clients can no longer write `meta/founding`.
class FirebaseFoundingMemberRepository implements FoundingMemberRepository {
  FirebaseFoundingMemberRepository({
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
    FoundingMemberRepository? fallback,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _functionsOverride = functions,
        _fallback = fallback ?? MockFoundingMemberRepository();

  final FirebaseFirestore _db;
  final FirebaseFunctions? _functionsOverride;
  FirebaseFunctions get _functions =>
      _functionsOverride ?? FirebaseFunctions.instance;
  final FoundingMemberRepository _fallback;
  bool _useFallback = false;

  DocumentReference<Map<String, dynamic>> get _doc =>
      _db.collection('meta').doc('founding');

  Future<T> _guard<T>(
    Future<T> Function() action,
    Future<T> Function() orElse,
  ) async {
    if (_useFallback) return orElse();
    try {
      return await action();
    } catch (e) {
      debugPrint('Founding roster unavailable ($e) — using in-memory store.');
      _useFallback = true;
      return orElse();
    }
  }

  FoundingMemberSnapshot _from(Map<String, dynamic>? data, String? userId) {
    final ids = List<String>.from(data?['memberIds'] as List? ?? const []);
    return FoundingMemberSnapshot(
      claimedCount: (data?['count'] as num?)?.toInt() ?? ids.length,
      userIsMember: userId != null && ids.contains(userId),
    );
  }

  @override
  Future<FoundingMemberSnapshot> load({String? userId}) {
    return _guard(() async {
      final snap = await _doc.get();
      return _from(snap.data(), userId);
    }, () => _fallback.load(userId: userId));
  }

  @override
  Future<FoundingMemberSnapshot> claimSlot(String userId) async {
    if (_useFallback) return _fallback.claimSlot(userId);
    try {
      final callable = _functions
          .httpsCallableFromUrl(AppConfig.claimFoundingSlotFunctionUrl);
      final result = await callable.call<Map<String, dynamic>>({});
      return foundingSnapshotFromCallable(
        Map<String, dynamic>.from(result.data),
      );
    } catch (e) {
      // Never grant a slot locally when the server could not confirm it;
      // report the roster as it stands.
      debugPrint('Founding slot claim failed ($e).');
      return load(userId: userId);
    }
  }
}

/// Parses the `claimFoundingSlot` callable result.
@visibleForTesting
FoundingMemberSnapshot foundingSnapshotFromCallable(Map<String, dynamic> data) {
  return FoundingMemberSnapshot(
    claimedCount: (data['claimedCount'] as num?)?.toInt() ?? 0,
    userIsMember: data['userIsMember'] == true,
  );
}
