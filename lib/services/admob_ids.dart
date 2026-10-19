/// Validation for AdMob ids, shared by the runtime guard in `AdsService` and
/// mirrored by the Gradle `verifyReleaseAdMobIds` task
/// (android/app/build.gradle.kts) and the iOS "Check iOS App IDs" build phase.
///
/// Google's official sample ids all use this publisher. They are perfect for
/// debug builds, but a store build carrying one earns nothing and AdMob flags
/// apps that serve test ads to real users.
const String kGoogleTestAdMobPublisher = 'ca-app-pub-3940256099942544';

enum AdMobIdKind {
  /// The `ca-app-pub-<publisher>~<app>` application id (manifest / Info.plist).
  app,

  /// The `ca-app-pub-<publisher>/<unit>` ad unit id used by a banner.
  adUnit,
}

final RegExp _appIdPattern = RegExp(r'^ca-app-pub-\d{10,20}~\d{6,20}$');
final RegExp _adUnitPattern = RegExp(r'^ca-app-pub-\d{10,20}/\d{6,20}$');

/// Why [id] must not ship in a release build, or null when it looks like a
/// real production id. Catches blanks, Google's sample publisher, template
/// placeholders (`XXXX`, `REPLACE-ME`, `YYYY`) and app/unit id mix-ups.
String? admobReleaseIdProblem(String id, AdMobIdKind kind) {
  final value = id.trim();
  if (value.isEmpty) return 'is empty';
  if (value.startsWith(kGoogleTestAdMobPublisher)) {
    return "is one of Google's sample/test ids";
  }
  final pattern = kind == AdMobIdKind.app ? _appIdPattern : _adUnitPattern;
  if (!pattern.hasMatch(value)) {
    return kind == AdMobIdKind.app
        ? 'is not a ca-app-pub-<digits>~<digits> app id (placeholder?)'
        : 'is not a ca-app-pub-<digits>/<digits> ad unit id (placeholder?)';
  }
  return null;
}
