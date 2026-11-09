import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

export 'package:purchases_flutter/purchases_flutter.dart'
    show CustomerInfo, Offering, Offerings, Package, StoreProduct;

/// Mobile RevenueCat SDK. The web build never imports this library.
class PurchasesBinding {
  static Future<bool> configure(String apiKey) async {
    try {
      await Purchases.setLogLevel(LogLevel.error);
      await Purchases.configure(PurchasesConfiguration(apiKey));
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('[purchases] configure failed: $e');
      return false;
    }
  }

  static Future<void> logIn(String userId) async {
    try {
      await Purchases.logIn(userId);
    } catch (_) {}
  }

  static Future<void> logOut() async {
    try {
      await Purchases.logOut();
    } catch (_) {}
  }

  static Future<CustomerInfo?> customerInfo() async {
    try {
      return await Purchases.getCustomerInfo();
    } catch (_) {
      return null;
    }
  }

  static Future<Offerings?> offerings() async {
    try {
      return await Purchases.getOfferings();
    } catch (_) {
      return null;
    }
  }

  static Future<CustomerInfo?> purchase(Package package) async {
    try {
      final result = await Purchases.purchase(
        PurchaseParams.package(package),
      );
      return result.customerInfo;
    } on PurchasesErrorCode catch (e) {
      if (e == PurchasesErrorCode.purchaseCancelledError) return null;
      rethrow;
    } catch (_) {
      return null;
    }
  }

  static Future<CustomerInfo?> restore() async {
    try {
      return await Purchases.restorePurchases();
    } catch (_) {
      return null;
    }
  }
}
