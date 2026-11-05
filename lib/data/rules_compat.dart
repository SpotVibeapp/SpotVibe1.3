/// Client write shapes that stay valid against both the rules currently in
/// this repo and the rules the live v14 beta was built for.
///
/// This does not change `firestore.rules`. A rules deploy can still reject
/// the already-shipped v14 binary (see RULES_DEPLOY_GUARD.md). What this
/// does is let *this* build succeed whichever of those two shapes the
/// deployed rules still accept: try the strict shape first, and only if
/// that write is permission-denied try the legacy shape.
///
/// Turn the legacy retry off with `--dart-define=RULES_COMPAT_RETRIES=false`
/// once every tester is on this build and the strict rules are live.

/// Public-profile creates, strictest first.
///
/// 1. `email: ''` — accepted by the rules in this repo and by the pre-release
///    rules that required the key to exist.
/// 2. The same doc with no email key — for a ruleset that rejects the key
///    entirely.
/// 3. The real email on the public doc — only when [allowLegacyPublicEmail]
///    is set, and only after the two stricter shapes were denied. That is
///    the v14 sign-up shape. The current rules deny it, so it never runs
///    while those rules are what is deployed.
List<Map<String, dynamic>> profileCreateAttempts({
  required Map<String, Object> publicFields,
  required String email,
  bool allowLegacyPublicEmail = true,
}) {
  final base = Map<String, dynamic>.from(publicFields);
  for (final key in ['email', 'phone', 'phoneNumber']) {
    base.remove(key);
  }
  final blankEmail = Map<String, dynamic>.from(base)..['email'] = '';
  final attempts = <Map<String, dynamic>>[
    blankEmail,
    Map<String, dynamic>.from(base),
  ];
  final trimmed = email.trim();
  if (allowLegacyPublicEmail && trimmed.isNotEmpty) {
    attempts.add({...base, 'email': trimmed});
  }
  return attempts;
}

/// Runs [write] with each body until one is accepted.
///
/// Only a permission denial advances to the next shape. Any other error
/// (offline, invalid argument) is rethrown immediately so a transient
/// failure cannot be retried into a looser payload.
Future<void> writeFirstAllowed(
  List<Map<String, dynamic>> attempts,
  Future<void> Function(Map<String, dynamic> body) write, {
  bool Function(Object error) isDenied = isPermissionDenied,
}) async {
  Object? last;
  for (var i = 0; i < attempts.length; i++) {
    try {
      await write(attempts[i]);
      return;
    } catch (error) {
      last = error;
      final hasNext = i < attempts.length - 1;
      if (!hasNext || !isDenied(error)) rethrow;
    }
  }
  if (last != null) {
    throw last;
  }
}

/// True for a Firestore `permission-denied` error without importing the
/// Firebase SDK (unit tests throw a stand-in with the same `code`).
bool isPermissionDenied(Object error) {
  try {
    final code = (error as dynamic).code;
    return code == 'permission-denied';
  } catch (_) {
    return false;
  }
}
