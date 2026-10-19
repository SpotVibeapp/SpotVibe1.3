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
  static const bool enableGoogleSignIn = true;

  /// Sign in with Apple. Required by App Store Review Guideline 4.8 because
  /// Google Sign-In is offered. The button is only shown on iOS/macOS.
  ///  - iOS "Sign in with Apple" capability: ios/Runner/Runner.entitlements
  ///    (com.apple.developer.applesignin) — already wired in the project.
  ///  - TODO(Blake): Firebase Authentication → Sign-in method → Apple must be
  ///    enabled, and the App ID must have the capability in the Apple
  ///    Developer portal. See IOS_RELEASE_TODO_BLAKE.md.
  static const bool enableAppleSignIn = true;

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

  // The callables below route the same way (Gen 2 Cloud Run URL, invoker IAM
  // check disabled after deploy, Firebase Auth still verified by the
  // function). The defaults follow the project's Cloud Run URL pattern
  // `https://<function-name-lowercase>-kfzltbt5ja-uc.a.run.app`; confirm them
  // after the first deploy with `gcloud run services list` and override with
  // the matching --dart-define if they differ.

  /// `claimFoundingSlot`: claims a founding-price slot after the server
  /// verifies the RevenueCat founding purchase.
  static const String claimFoundingSlotFunctionUrl = String.fromEnvironment(
    'CLAIM_FOUNDING_SLOT_FUNCTION_URL',
    defaultValue: 'https://claimfoundingslot-kfzltbt5ja-uc.a.run.app',
  );

  /// `featureEvent`: grants the weekly Premium featured slot after the server
  /// verifies the RevenueCat entitlement.
  static const String featureEventFunctionUrl = String.fromEnvironment(
    'FEATURE_EVENT_FUNCTION_URL',
    defaultValue: 'https://featureevent-kfzltbt5ja-uc.a.run.app',
  );

  /// `liveEventsProxy`: the only path to Ticketmaster / SeatGeek / JamBase.
  /// The provider keys live in Secret Manager, never in the app.
  static const String liveEventsProxyFunctionUrl = String.fromEnvironment(
    'LIVE_EVENTS_PROXY_FUNCTION_URL',
    defaultValue: 'https://liveeventsproxy-kfzltbt5ja-uc.a.run.app',
  );
}
