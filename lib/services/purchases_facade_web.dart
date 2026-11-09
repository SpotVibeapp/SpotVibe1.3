/// Stand-ins for the RevenueCat mobile types so the paywall compiles on web.
///
/// Web purchases go through [WebBillingController], not these objects. They
/// stay empty unless a test constructs them.
class StoreProduct {
  StoreProduct({
    required this.identifier,
    this.priceString = '',
    this.introductoryPrice,
  });

  final String identifier;
  final String priceString;
  final Object? introductoryPrice;
}

class Package {
  Package(this.storeProduct);

  final StoreProduct storeProduct;
}

class Offering {
  Offering({
    this.availablePackages = const [],
    this.monthly,
    this.annual,
  });

  final List<Package> availablePackages;
  final Package? monthly;
  final Package? annual;
}

class Offerings {
  Offerings({this.current, this.all = const {}});

  final Offering? current;
  final Map<String, Offering> all;
}

class EntitlementInfos {
  EntitlementInfos({this.active = const {}});

  final Map<String, Object> active;
}

class CustomerInfo {
  CustomerInfo({
    EntitlementInfos? entitlements,
    this.activeSubscriptions = const [],
    this.allPurchasedProductIdentifiers = const [],
  }) : entitlements = entitlements ?? EntitlementInfos();

  final EntitlementInfos entitlements;
  final List<String> activeSubscriptions;
  final List<String> allPurchasedProductIdentifiers;
}

class PurchasesBinding {
  static Future<bool> configure(String apiKey) async => false;

  static Future<void> logIn(String userId) async {}

  static Future<void> logOut() async {}

  static Future<CustomerInfo?> customerInfo() async => null;

  static Future<Offerings?> offerings() async => null;

  static Future<CustomerInfo?> purchase(Package package) async => null;

  static Future<CustomerInfo?> restore() async => null;
}
