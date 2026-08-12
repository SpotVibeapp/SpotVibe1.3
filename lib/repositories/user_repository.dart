import '../models/user.dart';

/// Data-source contract for user accounts & authentication.
///
/// Two implementations exist:
///  - [FirebaseUserRepository] — real auth via Firebase Auth + Firestore
///    profile documents (used in production).
///  - [MockUserRepository] — in-memory fake used for offline development,
///    demos, and unit tests.
///
/// The rest of the app (AuthService, AuthProvider, screens) depends only on
/// this interface, so the backend can be swapped at startup.
abstract class UserRepository {
  /// Returns the currently signed-in user, or null when signed out.
  /// Implementations with persistent sessions (Firebase) restore the session
  /// automatically.
  Future<AppUser?> getCurrentUser();

  /// Signs in with an OAuth/social credential.
  ///
  /// [provider] is one of: `google`, `facebook`, `apple`.
  /// Mock implementations ignore the tokens; Firebase builds a real
  /// [AuthCredential] from them.
  Future<AppUser> loginWithSocial({
    required String provider,
    required String name,
    required String email,
    String? avatarUrl,
    String? idToken,
    String? accessToken,

    /// Only used by Apple Sign-In (the raw nonce whose SHA-256 was sent to
    /// Apple).
    String? rawNonce,
  });

  /// Email + password sign-in. Throws on invalid credentials.
  Future<AppUser> login(String email, String password);

  /// Creates a new account. Throws when the email is already registered.
  Future<AppUser> register(String name, String email, String password);

  Future<void> logout();

  // ── Social graph (still mocked everywhere; not yet in Firestore) ────────
  Future<void> addFriend(String userId);
  Future<void> blockUser(String userId);
  Future<void> reportUser(String userId, String reason);
}
