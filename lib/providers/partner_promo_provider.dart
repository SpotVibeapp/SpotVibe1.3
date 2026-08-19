import 'package:flutter/foundation.dart';

import '../models/partner_promo_code.dart';
import '../repositories/partner_promo_repository.dart';

class PartnerPromoProvider extends ChangeNotifier {
  PartnerPromoProvider({required PartnerPromoRepository repository})
      : _repository = repository;

  final PartnerPromoRepository _repository;

  List<PartnerPromoCode> _codes = const [];
  List<PartnerPromoCode> get codes => _codes;
  List<PartnerPromoCode> get availableCodes =>
      _codes.where((code) => code.isAvailable).toList();
  List<PartnerPromoCode> get issuedCodes =>
      _codes.where((code) => code.isIssued).toList();

  bool _loading = false;
  bool get loading => _loading;

  bool _busy = false;
  bool get busy => _busy;

  String? _error;
  String? get error => _error;

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _codes = await _repository.getCodes();
    } catch (error) {
      _error = _message(error);
    }
    _loading = false;
    notifyListeners();
  }

  Future<PartnerPromoCode?> stockStoreCode({
    required String code,
    required PartnerPromoPlatform platform,
    required String offerLabel,
    required String durationLabel,
    required String adminUid,
  }) async {
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      final created = await _repository.stockStoreCode(
        code: code,
        platform: platform,
        offerLabel: offerLabel,
        durationLabel: durationLabel,
        adminUid: adminUid,
      );
      _codes = [created, ..._codes];
      return created;
    } catch (error) {
      _error = _message(error);
      return null;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<PartnerPromoCode?> issueCode({
    required String codeId,
    required String partnerName,
    required String partnerEmail,
    required String adminUid,
  }) async {
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      final issued = await _repository.issueCode(
        codeId: codeId,
        partnerName: partnerName,
        partnerEmail: partnerEmail,
        adminUid: adminUid,
      );
      _replace(issued);
      return issued;
    } catch (error) {
      _error = _message(error);
      return null;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<bool> revokeCode({
    required String codeId,
    required String adminUid,
  }) async {
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      await _repository.revokeCode(codeId: codeId, adminUid: adminUid);
      PartnerPromoCode? current;
      for (final code in _codes) {
        if (code.id == codeId) {
          current = code;
          break;
        }
      }
      if (current != null) {
        _replace(current.copyWith(
          status: PartnerPromoStatus.revoked,
          revokedBy: adminUid,
          revokedAt: DateTime.now(),
        ));
      }
      return true;
    } catch (error) {
      _error = _message(error);
      return false;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void _replace(PartnerPromoCode updated) {
    _codes = _codes.map((code) => code.id == updated.id ? updated : code).toList();
  }

  String _message(Object error) =>
      error.toString().replaceFirst('Exception: ', '').replaceFirst('StateError: ', '');
}
