import '../models/auth_failure.dart';
import 'app_localizations.dart';

/// Maps a Firebase / [AuthFailure] code to a localized, user-safe string.
String localizeAuthError(AppLocalizations l10n, Object? error) {
  final code = _codeOf(error);
  switch (code) {
    case 'invalid-email':
      return l10n.authInvalidEmail;
    case 'user-not-found':
    case 'wrong-password':
    case 'invalid-credential':
      return l10n.authWrongCredentials;
    case 'email-already-in-use':
      return l10n.authEmailInUse;
    case 'weak-password':
      return l10n.authWeakPassword;
    case 'too-many-requests':
      return l10n.authTooManyRequests;
    case 'network-request-failed':
      return l10n.authNetworkError;
    case 'operation-not-allowed':
      return l10n.authMethodDisabled;
    case 'account-exists-with-different-credential':
      return l10n.authDifferentCredential;
    case 'popup-closed-by-user':
    case 'canceled':
    case 'cancelled':
      return l10n.authCancelled;
    case 'login-failed':
      return l10n.authLoginFailed;
    case 'register-failed':
      return l10n.authRegisterFailed;
    case 'no-account-to-delete':
      return l10n.authNoAccountToDelete;
    case 'no-email-to-verify':
      return l10n.authNoEmailToVerify;
    case 'requires-recent-login':
      return l10n.authRequiresRecentLogin;
    case 'facebook-missing-token':
      return l10n.authFacebookMissingToken;
    case 'apple-missing-token':
      return l10n.authAppleMissingToken;
    default:
      if (error is AuthFailure && error.message.isNotEmpty) {
        return error.message;
      }
      return l10n.authFailed;
  }
}

bool isAuthCancellation(Object? error) {
  final code = _codeOf(error);
  return code == 'popup-closed-by-user' ||
      code == 'canceled' ||
      code == 'cancelled' ||
      code.contains('cancel');
}

String _codeOf(Object? error) {
  if (error is AuthFailure) return error.code;
  if (error is String) return error;
  return error?.toString().replaceFirst('Exception: ', '') ?? '';
}
