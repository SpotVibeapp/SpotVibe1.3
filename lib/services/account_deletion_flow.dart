import 'package:flutter/foundation.dart';

/// A fresh Sign in with Apple authorization, obtained right before deleting an
/// account. [authorizationCode] is single-use and valid for about 5 minutes.
class AppleDeletionAuthorization {
  const AppleDeletionAuthorization({
    required this.authorizationCode,
    required this.identityToken,
    required this.rawNonce,
  });

  final String authorizationCode;

  /// May be null if Apple did not return one; reauthentication is skipped.
  final String? identityToken;
  final String rawNonce;
}

/// The user backed out of a confirmation step (e.g. closed the Apple sheet).
/// Nothing has been deleted when this is thrown.
class AccountDeletionCancelled implements Exception {
  const AccountDeletionCancelled([
    this.message =
        'Account deletion cancelled. To delete an account that uses Sign in '
            'with Apple, confirm with Apple when asked.',
  ]);

  final String message;

  @override
  String toString() => 'Exception: $message';
}

/// What happened during a deletion, for logging and tests.
class AccountDeletionResult {
  const AccountDeletionResult({
    required this.isAppleAccount,
    required this.appleTokenRevoked,
    this.revocationError,
  });

  final bool isAppleAccount;
  final bool appleTokenRevoked;

  /// Why revocation was skipped/failed, when it was attempted or needed.
  final Object? revocationError;
}

/// Runs the account-deletion steps in a fixed order, with every side effect
/// injected so the sequence can be unit-tested without Firebase.
///
/// Order (nothing is destroyed until all confirmation steps succeed):
///  1. Email/password re-authentication (when a password was entered).
///  2. Apple accounts only (App Review Guideline 5.1.1(v)):
///     a. ask the user to Sign in with Apple again for a fresh authorization
///        code (cancel → [AccountDeletionCancelled], nothing deleted);
///     b. re-authenticate with that Apple credential (so step 5 doesn't fail
///        with `requires-recent-login`);
///     c. revoke the Apple token via Firebase. If revocation fails (network,
///        or the Firebase Apple provider is missing its Services ID / key),
///        it is logged and deletion continues: the user's right to delete
///        their data must not depend on Apple's token endpoint.
///  3. Purge the user's Firestore data (best-effort; the `deleteUser` Cloud
///     Function does authoritative cleanup).
///  4. Delete the Firebase Auth user.
class AccountDeletionFlow {
  AccountDeletionFlow({
    required this.providerIds,
    required this.appleAuthorizationSupported,
    required this.requestAppleAuthorization,
    required this.reauthenticateWithApple,
    required this.revokeAppleToken,
    required this.purgeUserData,
    required this.deleteAuthUser,
    this.reauthenticateWithPassword,
  });

  static const appleProviderId = 'apple.com';

  /// Provider ids linked to the user (e.g. `password`, `google.com`,
  /// `apple.com`).
  final List<String> providerIds;

  /// Whether this platform can show the native Apple sheet (iOS/macOS).
  final bool appleAuthorizationSupported;

  final Future<AppleDeletionAuthorization> Function() requestAppleAuthorization;
  final Future<void> Function(AppleDeletionAuthorization auth)
      reauthenticateWithApple;
  final Future<void> Function(String authorizationCode) revokeAppleToken;
  final Future<void> Function() purgeUserData;
  final Future<void> Function() deleteAuthUser;

  /// Set only when the user entered a password.
  final Future<void> Function()? reauthenticateWithPassword;

  bool get isAppleAccount => providerIds.contains(appleProviderId);

  Future<AccountDeletionResult> run() async {
    // 1. Password re-auth (errors propagate; nothing deleted yet).
    final passwordReauth = reauthenticateWithPassword;
    if (passwordReauth != null) await passwordReauth();

    // 2. Apple: fresh authorization → re-auth → revoke.
    var revoked = false;
    Object? revocationError;
    if (isAppleAccount) {
      if (!appleAuthorizationSupported) {
        revocationError = UnsupportedError(
          'Sign in with Apple is not available on this platform.',
        );
        debugPrint('Apple token not revoked: $revocationError');
      } else {
        // Cancellation / failure here aborts before anything is deleted.
        final auth = await requestAppleAuthorization();
        if (auth.identityToken != null) {
          await reauthenticateWithApple(auth);
        }
        try {
          await revokeAppleToken(auth.authorizationCode);
          revoked = true;
        } catch (e) {
          revocationError = e;
          debugPrint('Apple token revocation failed; continuing deletion: $e');
        }
      }
    }

    // 3. Firestore data (best-effort).
    try {
      await purgeUserData();
    } catch (e) {
      debugPrint('Client-side purge incomplete ($e). '
          'The deleteUser Cloud Function performs authoritative cleanup.');
    }

    // 4. Auth user (errors propagate to the UI).
    await deleteAuthUser();

    return AccountDeletionResult(
      isAppleAccount: isAppleAccount,
      appleTokenRevoked: revoked,
      revocationError: revocationError,
    );
  }
}
