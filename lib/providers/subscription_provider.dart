import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../services/revenue_cat_service.dart';

enum PurchaseStatus { idle, loading, success, error, cancelled }

class SubscriptionProvider extends ChangeNotifier {
  final RevenueCatService _service;

  SubscriptionProvider({required RevenueCatService service}) : _service = service;

  // ── State ────────────────────────────────────────────────────────────────────

  bool _isSubscribed = false;
  bool get isSubscribed => _isSubscribed;

  Offerings? _offerings;
  Offerings? get offerings => _offerings;

  /// The offering currently being shown to the user (RevenueCat "current" offering).
  Offering? get currentOffering => _offerings?.current;

  PurchaseStatus _status = PurchaseStatus.idle;
  PurchaseStatus get status => _status;
  bool get isPurchasing => _status == PurchaseStatus.loading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  /// Which plan toggle is selected: 0 = monthly, 1 = annual.
  int _selectedPlanIndex = 1; // default to annual (best value)
  int get selectedPlanIndex => _selectedPlanIndex;

  void selectPlan(int index) {
    _selectedPlanIndex = index;
    notifyListeners();
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  /// Convenience: returns the monthly package from the current offering, if any.
  Package? get monthlyPackage => currentOffering?.monthly;

  /// Convenience: returns the annual package from the current offering, if any.
  Package? get annualPackage => currentOffering?.annual;

  /// Returns the package corresponding to [selectedPlanIndex].
  Package? get selectedPackage =>
      _selectedPlanIndex == 0 ? monthlyPackage : annualPackage;

  // ── Initialisation ───────────────────────────────────────────────────────────

  Future<void> initialize() async {
    _status = PurchaseStatus.loading;
    notifyListeners();
    await _loadEntitlement();
    await _loadOfferings();
    _status = PurchaseStatus.idle;
    notifyListeners();
  }

  Future<void> _loadEntitlement() async {
    _isSubscribed = await _service.checkProEntitlement();
  }

  Future<void> _loadOfferings() async {
    _offerings = await _service.fetchOfferings();
  }

  // ── Actions ──────────────────────────────────────────────────────────────────

  Future<bool> purchaseSelected() async {
    final package = selectedPackage;
    if (package == null) {
      _errorMessage = 'No package available. Please try again.';
      _status = PurchaseStatus.error;
      notifyListeners();
      return false;
    }
    _status = PurchaseStatus.loading;
    _errorMessage = null;
    notifyListeners();
    try {
      final info = await _service.purchasePackage(package);
      if (info == null) {
        // User cancelled — silent
        _status = PurchaseStatus.cancelled;
        notifyListeners();
        return false;
      }
      _isSubscribed = info.entitlements.active.containsKey(kProEntitlementId);
      _status = _isSubscribed ? PurchaseStatus.success : PurchaseStatus.error;
      if (!_isSubscribed) _errorMessage = 'Purchase completed but entitlement not found.';
      notifyListeners();
      return _isSubscribed;
    } catch (e) {
      _errorMessage = 'Purchase failed. Please try again.';
      _status = PurchaseStatus.error;
      notifyListeners();
      return false;
    }
  }

  Future<bool> restorePurchases() async {
    _status = PurchaseStatus.loading;
    _errorMessage = null;
    notifyListeners();
    try {
      _isSubscribed = await _service.restorePurchases();
      _status = PurchaseStatus.idle;
      if (!_isSubscribed) _errorMessage = 'No active subscription found to restore.';
      notifyListeners();
      return _isSubscribed;
    } catch (_) {
      _errorMessage = 'Restore failed. Please try again.';
      _status = PurchaseStatus.error;
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    if (_status == PurchaseStatus.error || _status == PurchaseStatus.cancelled) {
      _status = PurchaseStatus.idle;
    }
    notifyListeners();
  }
}
