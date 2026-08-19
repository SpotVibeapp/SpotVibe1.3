import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../data/pricing.dart';

/// RevenueCat public SDK keys are supplied at build/run time and are never
/// committed to the repo:
///   flutter run --dart-define=REVENUECAT_ANDROID_KEY=goog_xxx \
///               --dart-define=REVENUECAT_APPLE_KEY=appl_xxx
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
    if (kIsWeb) return; // RevenueCat SDK is mobile-only
    if (_initialized) return;
    final apiKey = defaultTargetPlatform == TargetPlatform.android
        ? _kRevenueCatAndroidKey
        : _kRevenueCatAppleKey;
    if (apiKey.isEmpty) return; // Debug/profile can use a local UI trial; release fails closed.
    try {
      await Purchases.setLogLevel(LogLevel.error);
      final configuration = PurchasesConfiguration(apiKey);
      await Purchases.configure(configuration);
      _initialized = true;
    } catch (_) {}
  }

  /// Log in a known user so their purchases are associated with their account.
  Future<void> logIn(String userId) async {
    if (kIsWeb || !_initialized) return;
    try {
      await Purchases.logIn(userId);
    } catch (_) {}
  }

  /// Log out — reverts to anonymous purchasing.
  Future<void> logOut() async {
    if (kIsWeb || !_initialized) return;
    try {
      await Purchases.logOut();
    } catch (_) {}
  }

  /// Returns true when the user has an active "pro" entitlement.
  Future<bool> checkProEntitlement() async {
    if (kIsWeb || !_initialized) return false;
    try {
      final info = await Purchases.getCustomerInfo();
      return info.entitlements.active.containsKey(kProEntitlementId);
    } catch (_) {
      return false;
    }
  }

  /// Returns the current RevenueCat offerings (packages available for purchase).
  Future<Offerings?> fetchOfferings() async {
    if (kIsWeb || !_initialized) return null;
    try {
      return await Purchases.getOfferings();
    } catch (_) {
      return null;
    }
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
    try {
      final info = await Purchases.getCustomerInfo();
      final ids = <String>{
        ...info.activeSubscriptions,
        ...info.allPurchasedProductIdentifiers,
      };
      return ids.any(isFoundingStoreProduct);
    } catch (_) {
      return false;
    }
  }

  /// Purchase a package. Returns updated [CustomerInfo] on success, null on failure/cancellation.
  Future<CustomerInfo?> purchasePackage(Package package) async {
    if (kIsWeb || !_initialized) return null;
    try {
      final result = await Purchases.purchasePackage(package);
      return result.customerInfo;
    } on PurchasesErrorCode catch (e) {
      if (e == PurchasesErrorCode.purchaseCancelledError) return null;
      rethrow;
    } catch (_) {
      return null;
    }
  }

  /// Restore previous purchases. Returns true when the pro entitlement is restored.
  Future<bool> restorePurchases() async {
    if (kIsWeb || !_initialized) return false;
    try {
      final info = await Purchases.restorePurchases();
      return info.entitlements.active.containsKey(kProEntitlementId);
    } catch (_) {
      return false;
    }
  }
}
