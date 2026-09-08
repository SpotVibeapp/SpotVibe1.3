/// Launch-time feature flags for SpotVibe.
///
/// Social sign-in buttons are hidden until each provider is fully configured
/// end-to-end (Firebase console + native project files + OAuth credentials).
/// Shipping a button that fails at runtime is a common store-rejection
/// trigger, so these default to `false`. Flip a flag to `true` once that
/// provider has been set up for the platforms you ship.
class AppConfig {
  AppConfig._();

  /// Enable only after Google Sign-In is fully configured:
  ///  - Firebase Authentication → Sign-in method → Google enabled
  ///  - Android: google-services.json with the web client ID + SHA-1/SHA-256
  ///  - iOS: GoogleService-Info.plist + reversed client ID URL scheme
  static const bool enableGoogleSignIn = false;

  /// Enable only after Facebook Login is fully configured:
  ///  - Firebase Authentication → Sign-in method → Facebook enabled
  ///  - Facebook app id, Android key hashes, iOS FacebookAppID +
  ///    CFBundleURLSchemes in Info.plist
  static const bool enableFacebookSignIn = false;

  /// Enable only after Sign in with Apple is configured:
  ///  - iOS "Sign in with Apple" capability + entitlements file
  ///  - Firebase Authentication → Sign-in method → Apple enabled
  static const bool enableAppleSignIn = false;

  /// Direct URL for the Gen 2 callable AI endpoint.
  ///
  /// This is public routing information, not a secret. SpotVibe's Google
  /// Workspace Domain Restricted Sharing policy prevents an `allUsers` IAM
  /// invoker binding on the backing Cloud Run service. The service therefore
  /// has the Cloud Run invoker IAM check disabled and the callable itself still
  /// requires a valid Firebase Authentication token before it can generate an
  /// image. Override this when recreating the service with:
  /// `--dart-define=AI_PROMO_FUNCTION_URL=https://...a.run.app`.
  static const String aiPromoFunctionUrl = String.fromEnvironment(
    'AI_PROMO_FUNCTION_URL',
    defaultValue: 'https://generatepromoimage-kfzltbt5ja-uc.a.run.app',
  );

  /// Direct URL for the authenticated Gen 2 Ask SpotVibe endpoint.
  ///
  /// Like [aiPromoFunctionUrl], this routes directly to the backing Cloud Run
  /// service because the Workspace Domain Restricted Sharing policy blocks the
  /// `allUsers` invoker binding; the callable still requires a valid Firebase
  /// Auth token. Override when recreating the service with:
  /// `--dart-define=AI_EVENT_SEARCH_FUNCTION_URL=https://...a.run.app`.
  static const String aiEventSearchFunctionUrl = String.fromEnvironment(
    'AI_EVENT_SEARCH_FUNCTION_URL',
    defaultValue: 'https://searcheventassistant-kfzltbt5ja-uc.a.run.app',
  );
}
