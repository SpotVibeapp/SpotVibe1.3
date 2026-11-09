import 'dart:js_interop';

import 'package:flutter/foundation.dart';

import '../config/app_config.dart';

/// RevenueCat Web Billing (`@revenuecat/purchases-js`), loaded by
/// `web/revenuecat_billing.js`. Nothing is configured, and nothing is charged,
/// unless [AppConfig.enableWebBilling] is true and a public web API key was
/// passed at build time.
class WebBillingController {
  WebBillingController._();

  static final WebBillingController instance = WebBillingController._();

  bool _ready = false;
  String? _userId;

  bool get isReady => _ready;

  Future<bool> initialize() async {
    if (!AppConfig.enableWebBilling || AppConfig.revenueCatWebApiKey.isEmpty) {
      return false;
    }
    return _configure(AppConfig.revenueCatWebApiKey, _userId ?? '');
  }

  Future<void> logIn(String userId) async {
    _userId = userId;
    if (!AppConfig.enableWebBilling || AppConfig.revenueCatWebApiKey.isEmpty) {
      return;
    }
    _ready = await _configure(AppConfig.revenueCatWebApiKey, userId);
  }

  Future<void> logOut() async {
    _userId = null;
    _ready = false;
    try {
      _api?.logOut();
    } catch (e) {
      if (kDebugMode) debugPrint('[web-billing] logOut failed: $e');
    }
  }

  Future<bool> hasPro() async {
    if (!_ready) return false;
    try {
      final result = await _api?.hasPro().toDart;
      return result?.toDart ?? false;
    } catch (e) {
      if (kDebugMode) debugPrint('[web-billing] hasPro failed: $e');
      return false;
    }
  }

  Future<bool> purchase(String productId) async {
    if (!_ready) return false;
    try {
      final result = await _api?.purchaseProduct(productId.toJS).toDart;
      return result?.toDart ?? false;
    } catch (e) {
      if (kDebugMode) debugPrint('[web-billing] purchase failed: $e');
      return false;
    }
  }

  Future<bool> restore() async {
    if (!_ready) return false;
    try {
      final result = await _api?.restore().toDart;
      return result?.toDart ?? false;
    } catch (e) {
      if (kDebugMode) debugPrint('[web-billing] restore failed: $e');
      return false;
    }
  }

  Future<bool> _configure(String apiKey, String userId) async {
    final api = _api;
    if (api == null) {
      if (kDebugMode) {
        debugPrint('[web-billing] revenuecat_billing.js is not loaded');
      }
      return false;
    }
    try {
      final ok = await api.configure(apiKey.toJS, userId.toJS).toDart;
      _ready = ok.toDart;
      return _ready;
    } catch (e) {
      _ready = false;
      if (kDebugMode) debugPrint('[web-billing] configure failed: $e');
      return false;
    }
  }
}

@JS('spotvibeWebBilling')
extension type _SpotvibeWebBilling._(JSObject _) implements JSObject {
  external JSPromise<JSBoolean> configure(JSString apiKey, JSString appUserId);
  external JSPromise<JSBoolean> hasPro();
  external JSPromise<JSBoolean> purchaseProduct(JSString productId);
  external JSPromise<JSBoolean> restore();
  external void logOut();
}

@JS('spotvibeWebBilling')
external _SpotvibeWebBilling? get _api;
