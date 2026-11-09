/// Phone builds bill through the App Store and Play. This binding is a no-op.
class WebBillingController {
  WebBillingController._();

  static final WebBillingController instance = WebBillingController._();

  bool get isReady => false;

  Future<bool> initialize() async => false;

  Future<void> logIn(String userId) async {}

  Future<void> logOut() async {}

  Future<bool> hasPro() async => false;

  Future<bool> purchase(String productId) async => false;

  Future<bool> restore() async => false;
}
