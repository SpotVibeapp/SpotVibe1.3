import 'package:flutter/foundation.dart';

import '../data/pricing.dart';
import 'purchases_facade.dart';
import 'web_billing.dart';

/// RevenueCat public SDK keys are supplied at build/run time and are never
/// committed to the repo:
///   flutter run --dart-define=REVENUECAT_ANDROID_KEY=goog_xxx \
///               --dart-define=REVENUECAT_APPLE_KEY=appl_xxx
///
/// Web Billing (off unless ENABLE_WEB_BILLING=true) uses a separate public
/// key from the same RevenueCat project:
///   --dart-define=ENABLE_WEB_BILLING=true \
///   --dart-define=REVENUECAT_WEB_API_KEY=rcb_xxx
///
/// Get them from https://app.revenuecat.com → Project → API Keys.
const String _kRevenueCatAndroidKey =
    String.fromEnvironment('REVENUECAT_ANDROID_KEY');
const String _kRevenueCatAppleKey =
    String.fromEnvironment('REVENUECAT_APPLE_KEY');

/// Entitlement identifier created in the RevenueCat dashboard.
const kProEntitlementId = 'pro';

class RevenueCatService {
  bool _initialized = false;

  /// Call once at app startup before any purchases are made.
  Future<void> initialize() async {
    if (_initialized) return;
    if (kIsWeb) {
      _initialized = await WebBillingController.instance.initialize();
      return;
    }
    final apiKey = defaultTargetPlatform == TargetPlatform.android
        ? _kRevenueCatAndroidKey
        : _kRevenueCatAppleKey;
    if (apiKey.isEmpty) return; // Debug/profile can use a local UI trial; release fails closed.
    _initialized = await PurchasesBinding.configure(apiKey);
  }

  /// Log in a known user so their purchases are associated with their account.
  Future<void> logIn(String userId) async {
    if (kIsWeb) {
      await WebBillingController.instance.logIn(userId);
      _initialized = WebBillingController.instance.isReady;
      return;
    }
    if (!_initialized) return;
    await PurchasesBinding.logIn(userId);
  }

  /// Log out — reverts to anonymous purchasing.
  Future<void> logOut() async {
    if (kIsWeb) {
      await WebBillingController.instance.logOut();
      _initialized = false;
      return;
    }
    if (!_initialized) return;
    await PurchasesBinding.logOut();
  }

  /// Returns true when the user has an active "pro" entitlement.
  Future<bool> checkProEntitlement() async {
    if (kIsWeb) return WebBillingController.instance.hasPro();
    if (!_initialized) return false;
    final info = await PurchasesBinding.customerInfo();
    if (info == null) return false;
    return info.entitlements.active.containsKey(kProEntitlementId);
  }

  /// Returns the current RevenueCat offerings (packages available for purchase).
  /// Web Billing does not surface store packages; the paywall uses the
  /// product ids in [pricing.dart] and the JS SDK.
  Future<Offerings?> fetchOfferings() async {
    if (kIsWeb || !_initialized) return null;
    return PurchasesBinding.offerings();
  }

  /// Every package across every offering (default + founding).
  Future<List<Package>> allPackages() async {
    final offerings = await fetchOfferings();
    if (offerings == null) return const [];
    final seen = <String>{};
    final packs = <Package>[];
    void addAll(Iterable<Package> source) {
      for (final pack in source) {
        final id = pack.storeProduct.identifier;
        if (seen.add(id)) packs.add(pack);
      }
    }

    if (offerings.current != null) {
      addAll(offerings.current!.availablePackages);
    }
    for (final offering in offerings.all.values) {
      addAll(offering.availablePackages);
    }
    return packs;
  }

  Package? packageForProduct(Iterable<Package> packages, String productId) {
    for (final pack in packages) {
      if (pack.storeProduct.identifier == productId) return pack;
    }
    return null;
  }

  /// True when this Apple/Google account already owns the founding SKU.
  Future<bool> hasFoundingStorePurchase() async {
    if (kIsWeb || !_initialized) return false;
    final info = await PurchasesBinding.customerInfo();
    if (info == null) return false;
    final ids = <String>{
      ...info.activeSubscriptions,
      ...info.allPurchasedProductIdentifiers,
    };
    return ids.any(isFoundingStoreProduct);
  }

  /// Purchase a package. Returns updated [CustomerInfo] on success, null on failure/cancellation.
  Future<CustomerInfo?> purchasePackage(Package package) async {
    if (kIsWeb || !_initialized) return null;
    return PurchasesBinding.purchase(package);
  }

  /// Web Billing purchase for a RevenueCat product identifier. No-op on mobile
  /// and when web billing is not configured.
  Future<bool> purchaseWebProduct(String productId) async {
    if (!kIsWeb) return false;
    return WebBillingController.instance.purchase(productId);
  }

  /// Restore previous purchases. Returns true when the pro entitlement is restored.
  Future<bool> restorePurchases() async {
    if (kIsWeb) return WebBillingController.instance.restore();
    if (!_initialized) return false;
    final info = await PurchasesBinding.restore();
    if (info == null) return false;
    return info.entitlements.active.containsKey(kProEntitlementId);
  }
}
