/// RevenueCat Web Billing bridge.
///
/// The Flutter web app calls `window.spotvibeWebBilling`. The npm SDK is
/// imported only when configure() runs, so a build with web billing turned
/// off never contacts RevenueCat and never charges anyone.
(function () {
  var purchases = null;

  function findPackage(offerings, productId) {
    if (!offerings) return null;
    var lists = [];
    if (offerings.current && offerings.current.availablePackages) {
      lists = lists.concat(offerings.current.availablePackages);
    }
    var all = offerings.all || {};
    Object.keys(all).forEach(function (key) {
      var offering = all[key];
      if (offering && offering.availablePackages) {
        lists = lists.concat(offering.availablePackages);
      }
    });
    for (var i = 0; i < lists.length; i++) {
      var pkg = lists[i];
      var product =
        (pkg.webBillingProduct && pkg.webBillingProduct.identifier) ||
        (pkg.rcBillingProduct && pkg.rcBillingProduct.identifier) ||
        (pkg.product && pkg.product.identifier) ||
        '';
      if (pkg.identifier === productId || product === productId) return pkg;
    }
    return null;
  }

  function hasProEntitlement(info) {
    return !!(
      info &&
      info.entitlements &&
      info.entitlements.active &&
      info.entitlements.active.pro
    );
  }

  window.spotvibeWebBilling = {
    configure: async function (apiKey, appUserId) {
      var mod = await import('https://esm.sh/@revenuecat/purchases-js@1.14.0');
      var Purchases = mod.Purchases;
      var userId = appUserId && appUserId.length ? appUserId : Purchases.generateAppUserId();
      purchases = Purchases.configure({ apiKey: apiKey, appUserId: userId });
      return true;
    },
    hasPro: async function () {
      if (!purchases) return false;
      var info = await purchases.getCustomerInfo();
      return hasProEntitlement(info);
    },
    purchaseProduct: async function (productId) {
      if (!purchases) return false;
      var offerings = await purchases.getOfferings();
      var pkg = findPackage(offerings, productId);
      if (!pkg) {
        throw new Error('No Web Billing package for ' + productId);
      }
      var result = await purchases.purchase({ rcPackage: pkg });
      return hasProEntitlement(result && result.customerInfo);
    },
    restore: async function () {
      if (!purchases) return false;
      var info = await purchases.getCustomerInfo();
      return hasProEntitlement(info);
    },
    logOut: function () {
      purchases = null;
    },
  };
})();
