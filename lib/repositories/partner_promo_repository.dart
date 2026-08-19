import 'package:cloud_firestore/cloud_firestore.dart';

import '../data/event_codec.dart';
import '../models/partner_promo_code.dart';

/// Admin-only inventory of App Store / Google Play-issued partner codes.
///
/// The repository intentionally does not create a code itself. Store-issued
/// codes are the only compliant way to give a partner Premium access on iOS or
/// Android; this inventory prevents an administrator from issuing a one-time
/// code twice.
abstract class PartnerPromoRepository {
  Future<List<PartnerPromoCode>> getCodes();

  Future<PartnerPromoCode> stockStoreCode({
    required String code,
    required PartnerPromoPlatform platform,
    required String offerLabel,
    required String durationLabel,
    required String adminUid,
  });

  Future<PartnerPromoCode> issueCode({
    required String codeId,
    required String partnerName,
    required String partnerEmail,
    required String adminUid,
  });

  Future<void> revokeCode({
    required String codeId,
    required String adminUid,
  });
}

class MockPartnerPromoRepository implements PartnerPromoRepository {
  final Map<String, PartnerPromoCode> _byId = {};
  var _nextId = 1;

  @override
  Future<List<PartnerPromoCode>> getCodes() async {
    final codes = _byId.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return List.unmodifiable(codes);
  }

  @override
  Future<PartnerPromoCode> stockStoreCode({
    required String code,
    required PartnerPromoPlatform platform,
    required String offerLabel,
    required String durationLabel,
    required String adminUid,
  }) async {
    final normalized = _normalize(code);
    _validate(
      normalized: normalized,
      offerLabel: offerLabel,
      durationLabel: durationLabel,
    );
    if (_byId.values.any((item) => item.code == normalized)) {
      throw StateError('That store code is already in the partner-code inventory.');
    }
    final item = PartnerPromoCode(
      id: 'partner_code_${_nextId++}',
      code: normalized,
      platform: platform,
      offerLabel: offerLabel.trim(),
      durationLabel: durationLabel.trim(),
      status: PartnerPromoStatus.available,
      createdBy: adminUid,
      createdAt: DateTime.now(),
    );
    _byId[item.id] = item;
    return item;
  }

  @override
  Future<PartnerPromoCode> issueCode({
    required String codeId,
    required String partnerName,
    required String partnerEmail,
    required String adminUid,
  }) async {
    final code = _byId[codeId];
    if (code == null) throw StateError('Partner code not found.');
    if (!code.isAvailable) throw StateError('This partner code has already been issued.');
    if (partnerName.trim().isEmpty) throw ArgumentError('Partner name is required.');
    final issued = code.copyWith(
      status: PartnerPromoStatus.issued,
      partnerName: partnerName.trim(),
      partnerEmail: partnerEmail.trim(),
      issuedBy: adminUid,
      issuedAt: DateTime.now(),
    );
    _byId[codeId] = issued;
    return issued;
  }

  @override
  Future<void> revokeCode({
    required String codeId,
    required String adminUid,
  }) async {
    final code = _byId[codeId];
    if (code == null) throw StateError('Partner code not found.');
    _byId[codeId] = code.copyWith(
      status: PartnerPromoStatus.revoked,
      revokedBy: adminUid,
      revokedAt: DateTime.now(),
    );
  }
}

class FirebasePartnerPromoRepository implements PartnerPromoRepository {
  FirebasePartnerPromoRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _codes =>
      _db.collection('partner_promo_codes');

  @override
  Future<List<PartnerPromoCode>> getCodes() async {
    final snap = await _codes.orderBy('createdAtMs', descending: true).limit(200).get();
    return List.unmodifiable(
      snap.docs.map((doc) => _fromMap(doc.id, doc.data())).toList(),
    );
  }

  @override
  Future<PartnerPromoCode> stockStoreCode({
    required String code,
    required PartnerPromoPlatform platform,
    required String offerLabel,
    required String durationLabel,
    required String adminUid,
  }) async {
    final normalized = _normalize(code);
    _validate(
      normalized: normalized,
      offerLabel: offerLabel,
      durationLabel: durationLabel,
    );

    final duplicate = await _codes.where('code', isEqualTo: normalized).limit(1).get();
    if (duplicate.docs.isNotEmpty) {
      throw StateError('That store code is already in the partner-code inventory.');
    }

    final now = DateTime.now();
    final ref = _codes.doc();
    final item = PartnerPromoCode(
      id: ref.id,
      code: normalized,
      platform: platform,
      offerLabel: offerLabel.trim(),
      durationLabel: durationLabel.trim(),
      status: PartnerPromoStatus.available,
      createdBy: adminUid,
      createdAt: now,
    );
    await ref.set(_toMap(item, includeServerTimestamps: true));
    return item;
  }

  @override
  Future<PartnerPromoCode> issueCode({
    required String codeId,
    required String partnerName,
    required String partnerEmail,
    required String adminUid,
  }) async {
    if (partnerName.trim().isEmpty) throw ArgumentError('Partner name is required.');
    final ref = _codes.doc(codeId);
    return _db.runTransaction((transaction) async {
      final snap = await transaction.get(ref);
      if (!snap.exists || snap.data() == null) {
        throw StateError('Partner code not found.');
      }
      final current = _fromMap(snap.id, snap.data()!);
      if (!current.isAvailable) {
        throw StateError('This partner code has already been issued.');
      }
      final now = DateTime.now();
      final issued = current.copyWith(
        status: PartnerPromoStatus.issued,
        partnerName: partnerName.trim(),
        partnerEmail: partnerEmail.trim(),
        issuedBy: adminUid,
        issuedAt: now,
      );
      transaction.update(ref, {
        'status': issued.status.name,
        'partnerName': issued.partnerName,
        'partnerEmail': issued.partnerEmail,
        'issuedBy': issued.issuedBy,
        'issuedAtMs': now.millisecondsSinceEpoch,
        'issuedAt': FieldValue.serverTimestamp(),
      });
      return issued;
    });
  }

  @override
  Future<void> revokeCode({
    required String codeId,
    required String adminUid,
  }) async {
    final now = DateTime.now();
    await _codes.doc(codeId).update({
      'status': PartnerPromoStatus.revoked.name,
      'revokedBy': adminUid,
      'revokedAtMs': now.millisecondsSinceEpoch,
      'revokedAt': FieldValue.serverTimestamp(),
    });
  }

  Map<String, dynamic> _toMap(
    PartnerPromoCode item, {
    required bool includeServerTimestamps,
  }) =>
      {
        'code': item.code,
        'platform': item.platform.name,
        'offerLabel': item.offerLabel,
        'durationLabel': item.durationLabel,
        'status': item.status.name,
        'createdBy': item.createdBy,
        'createdAtMs': item.createdAt.millisecondsSinceEpoch,
        if (includeServerTimestamps) 'createdAt': FieldValue.serverTimestamp(),
      };

  PartnerPromoCode _fromMap(String id, Map<String, dynamic> data) =>
      PartnerPromoCode(
        id: id,
        code: data['code'] as String? ?? '',
        platform: partnerPromoPlatformFromName(data['platform'] as String?),
        offerLabel: data['offerLabel'] as String? ?? '',
        durationLabel: data['durationLabel'] as String? ?? '',
        status: partnerPromoStatusFromName(data['status'] as String?),
        createdBy: data['createdBy'] as String? ?? '',
        createdAt: parseStoreDate(data['createdAt'] ?? data['createdAtMs']),
        partnerName: data['partnerName'] as String?,
        partnerEmail: data['partnerEmail'] as String?,
        issuedBy: data['issuedBy'] as String?,
        issuedAt: _optionalDate(data['issuedAt'] ?? data['issuedAtMs']),
        revokedBy: data['revokedBy'] as String?,
        revokedAt: _optionalDate(data['revokedAt'] ?? data['revokedAtMs']),
      );
}

DateTime? _optionalDate(dynamic value) => value == null ? null : parseStoreDate(value);

String _normalize(String value) => value.trim().toUpperCase();

void _validate({
  required String normalized,
  required String offerLabel,
  required String durationLabel,
}) {
  if (normalized.isEmpty) throw ArgumentError('Paste a store-issued code first.');
  if (normalized.length > 128) throw ArgumentError('That promo code is too long.');
  if (offerLabel.trim().isEmpty) throw ArgumentError('Offer label is required.');
  if (durationLabel.trim().isEmpty) throw ArgumentError('Offer duration is required.');
}
