import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import 'account_deletion_flow.dart';

/// Cryptographically secure random nonce for Sign in with Apple.
String generateAppleNonce([int length = 32]) {
  const charset =
      '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
  final random = Random.secure();
  return List.generate(
    length,
    (_) => charset[random.nextInt(charset.length)],
  ).join();
}

/// SHA-256 hex digest of [rawNonce], the form Apple expects.
String sha256OfNonce(String rawNonce) =>
    sha256.convert(utf8.encode(rawNonce)).toString();

/// Shows the native Sign in with Apple sheet to get a fresh authorization
/// code before account deletion. Throws [AccountDeletionCancelled] when the
/// user closes the sheet, and a plain [Exception] for other Apple failures.
Future<AppleDeletionAuthorization> requestAppleAuthorizationForDeletion() async {
  final rawNonce = generateAppleNonce();
  final AuthorizationCredentialAppleID credential;
  try {
    credential = await SignInWithApple.getAppleIDCredential(
      scopes: const [], // no name/email needed — we only need the code
      nonce: sha256OfNonce(rawNonce),
    );
  } on SignInWithAppleAuthorizationException catch (e) {
    throw appleAuthorizationError(e.code);
  }
  return AppleDeletionAuthorization(
    authorizationCode: credential.authorizationCode,
    identityToken: credential.identityToken,
    rawNonce: rawNonce,
  );
}

/// Maps an Apple authorization error to the exception shown to the user.
/// Pure so it can be unit-tested.
Exception appleAuthorizationError(AuthorizationErrorCode code) {
  if (code == AuthorizationErrorCode.canceled) {
    return const AccountDeletionCancelled();
  }
  return Exception(
    'Could not confirm with Apple, so your account was not deleted. '
    'Please try again.',
  );
}
