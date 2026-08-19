import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ui' show Locale;

import '../data/pricing.dart';
import '../l10n/app_localizations.dart';
import '../repositories/founding_member_repository.dart';
import '../services/revenue_cat_service.dart';

enum PurchaseStatus { idle, loading, success, error, cancelled }

const _kLocalPremiumUntil = 'sv_local_premium_until_ms';
const _kLocalFounding = 'sv_local_founding_member';
const _kLocalTrialStarted = 'sv_local_trial_started';

class SubscriptionProvider extends ChangeNotifier {
  final RevenueCatService _service;
  final FoundingMemberRepository _founding;
  final String? Function()? _currentUserId;

  SubscriptionProvider({
    required RevenueCatService service,
    FoundingMemberRepository? founding,
    String? Function()? currentUserId,
  })  : _service = service,
        _founding = founding ?? MockFoundingMemberRepository(),
        _currentUserId = currentUserId;

  bool _isSubscribed = false;
  bool get isSubscribed => _isSubscribed;

  bool _isInTrial = false;
  bool get isInTrial => _isInTrial;

  DateTime? _trialEndsAt;
  DateTime? get trialEndsAt => _trialEndsAt;

  bool _isFoundingMember = false;
  bool get isFoundingMember => _isFoundingMember;

  int _foundingClaimed = 0;
  int get foundingSlotsRemaining => foundingSlotsLeft(_foundingClaimed);
  bool get offerFoundingPrice =>
      _isFoundingMember || foundingSlotsRemain(_foundingClaimed);

  Offerings? _offerings;
  Offerings? get offerings => _offerings;

  Offering? get currentOffering => _offerings?.current;

  PurchaseStatus _status = PurchaseStatus.idle;
  PurchaseStatus get status => _status;
  bool get isPurchasing => _status == PurchaseStatus.loading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  /// Current display locale; drives localized labels. Update via [setLocale]
  /// (wired to the LocaleProvider in main.dart).
  Locale _locale = const Locale('en');
  Locale get locale => _locale;
  void setLocale(Locale locale) {
    if (_locale == locale) return;
    _locale = locale;
    notifyListeners();
  }

  AppLocalizations get _l10n => lookupAppLocalizations(_locale);

  int get selectedPlanIndex => 0;

  void selectPlan(int index) {}

  List<Package> _allPackages = const [];

  Package? get monthlyPackage =>
      _packageById(kPremiumMonthlyProductId) ?? currentOffering?.monthly;

  Package? get foundingPackage => _packageById(kFoundingMonthlyProductId) ??
      _firstWhere(isFoundingStoreProduct);

  Package? get annualPackage => currentOffering?.annual;

  /// The SKU Apple/Google will actually charge.
  /// Founding members and open founding slots buy [kFoundingMonthlyProductId]
  /// ($9.99). Everyone else buys [kPremiumMonthlyProductId] ($12.99 + 7-day intro).
  Package? get selectedPackage {
    if (offerFoundingPrice) {
      final founding = foundingPackage;
      if (founding != null) return founding;
      // Do not silently charge $12.99 when we promised $9.99.
      return null;
    }
    final monthly = monthlyPackage ?? _firstWhere(isPremiumMonthlyStoreProduct);
    if (monthly != null) return monthly;
    final packs = currentOffering?.availablePackages;
    if (packs != null && packs.isNotEmpty) return packs.first;
    return null;
  }

  bool get willBillThroughStore => selectedPackage != null;

  String? get selectedStoreProductId =>
      selectedPackage?.storeProduct.identifier;

  Package? _packageById(String productId) {
    for (final pack in _allPackages) {
      if (pack.storeProduct.identifier == productId) return pack;
    }
    return null;
  }

  Package? _firstWhere(bool Function(String id) test) {
    for (final pack in _allPackages) {
      if (test(pack.storeProduct.identifier)) return pack;
    }
    return null;
  }

  bool get storeHasIntroOffer {
    final product = selectedPackage?.storeProduct;
    if (product == null) return false;
    try {
      final intro = (product as dynamic).introductoryPrice;
      return intro != null;
    } catch (_) {
      return false;
    }
  }

  String get displayPriceLabel {
    final amount = '\$${priceAmount(founding: offerFoundingPrice).toStringAsFixed(2)}';
    return _l10n.perMonth(amount);
  }

  double get displayPriceAmount => priceAmount(founding: offerFoundingPrice);

  String get subscribeCtaLabel {
    if (_isSubscribed) return _l10n.youAreOnPremium;
    return _l10n.startFreeTrial;
  }

  String get billingFinePrint {
    final l = _l10n;
    final after = displayPriceLabel;
    if (offerFoundingPrice && !_isFoundingMember) {
      return l.billingFoundingOpen(
        l.trialLabel,
        after,
        foundingSlotsRemaining,
        kFoundingMemberLimit,
      );
    }
    if (_isFoundingMember) {
      return l.billingFoundingLocked(after);
    }
    return l.billingStandard(l.trialLabel, after);
  }

  Future<void> initialize() async {
    _status = PurchaseStatus.loading;
    notifyListeners();
    await _loadEntitlement();
    await _loadOfferings();
    await _loadFounding();
    // A local trial exists only to make debug/profile UI testing possible.
    // Store builds must receive Premium only from an active store entitlement.
    if (!kReleaseMode) await _loadLocalPremium();
    _status = PurchaseStatus.idle;
    notifyListeners();
  }

  Future<void> _loadEntitlement() async {
    _isSubscribed = await _service.checkProEntitlement();
  }

  Future<void> _loadOfferings() async {
    _offerings = await _service.fetchOfferings();
    _allPackages = await _service.allPackages();
  }

  Future<void> _loadFounding() async {
    final snap = await _founding.load(userId: _currentUserId?.call());
    _foundingClaimed = snap.claimedCount;
    _isFoundingMember = snap.userIsMember;
    if (!_isFoundingMember && !kReleaseMode) {
      final prefs = await SharedPreferences.getInstance();
      _isFoundingMember = prefs.getBool(_kLocalFounding) ?? false;
    }
    if (!_isFoundingMember && await _service.hasFoundingStorePurchase()) {
      final uid = _currentUserId?.call();
      if (uid != null && uid.isNotEmpty) {
        final locked = await _founding.claimSlot(uid);
        _foundingClaimed = locked.claimedCount;
        _isFoundingMember = locked.userIsMember;
      } else {
        _isFoundingMember = true;
      }
      if (!kReleaseMode) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_kLocalFounding, _isFoundingMember);
      }
    }
  }

  Future<void> _loadLocalPremium() async {
    if (_isSubscribed) return;
    final prefs = await SharedPreferences.getInstance();
    final untilMs = prefs.getInt(_kLocalPremiumUntil);
    if (untilMs == null) return;
    final until = DateTime.fromMillisecondsSinceEpoch(untilMs);
    if (until.isAfter(DateTime.now())) {
      _isSubscribed = true;
      _isInTrial = prefs.getBool(_kLocalTrialStarted) ?? false;
      _trialEndsAt = until;
    }
  }

  Future<bool> purchaseSelected() async {
    _status = PurchaseStatus.loading;
    _errorMessage = null;
    notifyListeners();

    final package = selectedPackage;
    if (package != null) {
      try {
        final info = await _service.purchasePackage(package);
        if (info == null) {
          _status = PurchaseStatus.cancelled;
          notifyListeners();
          return false;
        }
        _isSubscribed = info.entitlements.active.containsKey(kProEntitlementId);
        if (_isSubscribed) {
          await _lockFoundingIfOffered();
          _status = PurchaseStatus.success;
          notifyListeners();
          return true;
        }
      } catch (_) {
        // A release build must not substitute a local trial for a failed
        // store purchase. Fall through to the clear failure below instead.
      }
    }

    if (kReleaseMode) {
      // Missing RevenueCat keys, inactive products, or a store error must not
      // grant paid features. This prevents a release build from claiming a
      // purchase succeeded when Apple/Google never charged the customer.
      _errorMessage = _l10n.purchaseFailed;
      _status = PurchaseStatus.error;
      notifyListeners();
      return false;
    }

    // Debug/profile only: keep a local trial so the Premium UI can be tested
    // before store products and RevenueCat are available.
    final started = await _startLocalTrial();
    if (started) {
      await _lockFoundingIfOffered();
      _status = PurchaseStatus.success;
      notifyListeners();
      return true;
    }

    _errorMessage = _l10n.purchaseFailed;
    _status = PurchaseStatus.error;
    notifyListeners();
    return false;
  }

  Future<bool> _startLocalTrial() async {
    if (kReleaseMode) return false;
    final prefs = await SharedPreferences.getInstance();
    final until = DateTime.now().add(const Duration(days: kPremiumTrialDays));
    await prefs.setInt(_kLocalPremiumUntil, until.millisecondsSinceEpoch);
    await prefs.setBool(_kLocalTrialStarted, true);
    _isSubscribed = true;
    _isInTrial = true;
    _trialEndsAt = until;
    return true;
  }

  Future<void> _lockFoundingIfOffered() async {
    if (!offerFoundingPrice) return;
    final uid = _currentUserId?.call();
    if (uid != null && uid.isNotEmpty) {
      final snap = await _founding.claimSlot(uid);
      _foundingClaimed = snap.claimedCount;
      _isFoundingMember = snap.userIsMember;
    } else {
      _isFoundingMember = true;
    }
    if (!kReleaseMode) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kLocalFounding, _isFoundingMember);
    }
  }

  Future<bool> restorePurchases() async {
    _status = PurchaseStatus.loading;
    _errorMessage = null;
    notifyListeners();
    try {
      _isSubscribed = await _service.restorePurchases();
      if (!_isSubscribed && !kReleaseMode) await _loadLocalPremium();
      _status = PurchaseStatus.idle;
      if (!_isSubscribed) {
        _errorMessage = _l10n.noActiveSubscription;
      }
      notifyListeners();
      return _isSubscribed;
    } catch (_) {
      _errorMessage = _l10n.restoreFailed;
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
