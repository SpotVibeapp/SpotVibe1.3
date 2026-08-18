/// Launch-time feature flags for SpotVibe.
///
/// Social sign-in buttons are hidden until each provider is fully configured
/// end-to-end (Firebase console + native project files + OAuth credentials).
/// Shipping a button that fails at runtime is a common store-rejection
/// trigger, so these default to `false`. Flip a flag to `true` once that
/// provider has been set up for the platforms you ship.
class AppConfig {
  AppConfig._();

  /// Google Sign-In is fully configured:
  ///  - Firebase Authentication → Sign-in method → Google enabled
  ///  - Android: google-services.json with the web client ID + SHA-1/SHA-256
  ///  - iOS: GoogleService-Info.plist + reversed client ID URL scheme
  static const bool enableGoogleSignIn = false;

  /// Facebook Login is fully configured:
  ///  - Firebase Authentication → Sign-in method → Facebook enabled
  ///  - Facebook app id, Android key hashes, iOS FacebookAppID +
  ///    CFBundleURLSchemes in Info.plist
  static const bool enableFacebookSignIn = true;

  /// Sign in with Apple is enabled:
  ///  - iOS "Sign in with Apple" capability + entitlements file
  ///  - Firebase Authentication → Sign-in method → Apple enabled
  static const bool enableAppleSignIn = true;
}
