/// What we actually know about a user after a Sign in with Apple exchange.
///
/// Apple only sends `email` and the name parts on the **first** authorization
/// for this app, and the user may choose "Hide My Email", in which case the
/// email is a real `@privaterelay.appleid.com` relay address that Apple
/// generated. On every later sign-in both are null.
///
/// This class never invents data: a missing email stays `null` and a missing
/// name stays `null`. The account is keyed by the Firebase UID (and Apple's
/// stable [userIdentifier]), never by email.
class AppleSignInProfile {
  const AppleSignInProfile({
    required this.email,
    required this.fullName,
    required this.userIdentifier,
  });

  /// Builds a profile from the raw fields of an Apple ID credential
  /// (`AuthorizationCredentialAppleID`). Blank strings are treated as absent.
  factory AppleSignInProfile.fromCredentialFields({
    String? email,
    String? givenName,
    String? familyName,
    String? userIdentifier,
  }) {
    final trimmedEmail = email?.trim();
    final name = [givenName, familyName]
        .map((part) => part?.trim() ?? '')
        .where((part) => part.isNotEmpty)
        .join(' ');
    final trimmedId = userIdentifier?.trim();
    return AppleSignInProfile(
      email: (trimmedEmail == null || trimmedEmail.isEmpty)
          ? null
          : trimmedEmail,
      fullName: name.isEmpty ? null : name,
      userIdentifier:
          (trimmedId == null || trimmedId.isEmpty) ? null : trimmedId,
    );
  }

  /// The email Apple returned (possibly a private relay address), or null.
  final String? email;

  /// "Given Family" as Apple returned it, or null when Apple sent no name
  /// (always the case after the first sign-in).
  final String? fullName;

  /// Apple's stable, app-scoped user id. Not shown in the UI.
  final String? userIdentifier;

  bool get hasEmail => email != null;
  bool get hasName => fullName != null;

  /// True for Apple "Hide My Email" relay addresses. These are real,
  /// deliverable addresses and must be kept as-is.
  bool get isPrivateRelayEmail => isPrivateRelay(email);

  static bool isPrivateRelay(String? email) =>
      email != null &&
      email.trim().toLowerCase().endsWith('@privaterelay.appleid.com');
}
