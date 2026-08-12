import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/user.dart';
import 'user_repository.dart';

/// Production [UserRepository] backed by Firebase Auth + Firestore.
///
/// - Email/password and social (Google/Facebook/Apple) sign-in use
///   [FirebaseAuth.signInWithCredential].
/// - Sessions persist across app restarts automatically (firebase_auth stores
///   the session on device).
/// - Each user gets a public profile document at `users/{uid}` in Firestore
///   (name, email, avatarUrl) so other features (attendee lists, comments)
///   can render profiles.
///
/// Errors are converted to user-friendly [Exception]s via
/// [messageForAuthException] so the UI can show them directly.
class FirebaseUserRepository implements UserRepository {
  FirebaseUserRepository({FirebaseAuth? auth, FirebaseFirestore? firestore})
      : _auth = auth ?? FirebaseAuth.instance,
        _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('users');

  // ── Session ───────────────────────────────────────────────────────────────

  @override
  Future<AppUser?> getCurrentUser() async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) return null;
    return _appUserFor(firebaseUser);
  }

  @override
  Future<void> logout() async {
    await _auth.signOut();
  }

  // ── Email / password ──────────────────────────────────────────────────────

  @override
  Future<AppUser> login(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return await _appUserFor(credential.user!, provider: 'password');
    } on FirebaseAuthException catch (e) {
      throw Exception(messageForAuthException(e));
    }
  }

  @override
  Future<AppUser> register(String name, String email, String password) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await credential.user?.updateDisplayName(name);
      return await _appUserFor(
        credential.user!,
        fallbackName: name,
        provider: 'password',
      );
    } on FirebaseAuthException catch (e) {
      throw Exception(messageForAuthException(e));
    }
  }

  // ── Social sign-in ────────────────────────────────────────────────────────

  @override
  Future<AppUser> loginWithSocial({
    required String provider,
    required String name,
    required String email,
    String? avatarUrl,
    String? idToken,
    String? accessToken,
    String? rawNonce,
  }) async {
    final AuthCredential credential;
    switch (provider) {
      case 'google':
        credential = GoogleAuthProvider.credential(
          idToken: idToken,
          accessToken: accessToken,
        );
      case 'facebook':
        if (accessToken == null) {
          throw Exception('Facebook sign-in failed: missing access token.');
        }
        credential = FacebookAuthProvider.credential(accessToken);
      case 'apple':
        if (idToken == null) {
          throw Exception('Apple sign-in failed: missing identity token.');
        }
        credential = OAuthProvider('apple.com').credential(
          idToken: idToken,
          rawNonce: rawNonce,
        );
      default:
        throw ArgumentError('Unsupported auth provider: $provider');
    }

    try {
      final result = await _auth.signInWithCredential(credential);
      return await _appUserFor(
        result.user!,
        fallbackName: name,
        fallbackAvatar: avatarUrl,
        provider: provider,
      );
    } on FirebaseAuthException catch (e) {
      throw Exception(messageForAuthException(e));
    }
  }

  // ── Social graph — not in Firestore yet (kept as no-ops) ─────────────────

  @override
  Future<void> addFriend(String userId) async {
    // TODO(backend): store friendships in Firestore (e.g. friends/{uid}).
  }

  @override
  Future<void> blockUser(String userId) async {
    // TODO(backend): store blocks in Firestore and enforce in queries.
  }

  @override
  Future<void> reportUser(String userId, String reason) async {
    try {
      await _db.collection('user_reports').add({
        'reportedUserId': userId,
        'reason': reason,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // Reporting should never crash the app.
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// Maps a Firebase [User] to an [AppUser] and ensures the Firestore
  /// profile document exists (created on first sign-in, refreshed after).
  Future<AppUser> _appUserFor(
    User user, {
    String? fallbackName,
    String? fallbackAvatar,
    String? provider,
  }) async {
    final displayName = (user.displayName?.isNotEmpty ?? false)
        ? user.displayName!
        : (fallbackName ?? user.email?.split('@').first ?? 'User');
    final avatar = (user.photoURL?.isNotEmpty ?? false)
        ? user.photoURL!
        : (fallbackAvatar?.isNotEmpty == true
            ? fallbackAvatar!
            : _generatedAvatar(displayName));
    final email = user.email ?? '';

    await _syncProfileDoc(
      uid: user.uid,
      name: displayName,
      email: email,
      avatarUrl: avatar,
      provider: provider,
    );

    return AppUser(
      id: user.uid,
      displayName: displayName,
      email: email,
      avatarUrl: avatar,
    );
  }

  /// Creates `users/{uid}` on first sign-in; refreshes it afterwards.
  /// Failures are swallowed — auth must still work if Firestore is down or
  /// rules haven't been deployed yet.
  Future<void> _syncProfileDoc({
    required String uid,
    required String name,
    required String email,
    required String avatarUrl,
    String? provider,
  }) async {
    try {
      final ref = _users.doc(uid);
      final snapshot = await ref.get();
      if (!snapshot.exists) {
        await ref.set({
          'name': name,
          'email': email,
          'avatarUrl': avatarUrl,
          if (provider != null) 'provider': provider,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        await ref.update({
          'email': email,
          'avatarUrl': avatarUrl,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (_) {
      // Non-fatal: profile sync is best-effort.
    }
  }

  static String _generatedAvatar(String name) =>
      'https://ui-avatars.com/api/?name=${Uri.encodeComponent(name)}'
      '&size=200&background=6C5CE7&color=fff';

  /// Maps a [FirebaseAuthException] to a message that is safe to show
  /// directly in the UI. Kept static & pure so it can be unit-tested.
  static String messageForAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'That email address is not valid.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'email-already-in-use':
        return 'An account with this email already exists. Try logging in instead.';
      case 'weak-password':
        return 'Please choose a stronger password (at least 6 characters).';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a moment and try again.';
      case 'network-request-failed':
        return 'Network error — check your connection and try again.';
      case 'operation-not-allowed':
        return 'This sign-in method is not enabled yet for this app.';
      case 'account-exists-with-different-credential':
        return 'An account with this email already exists using a different sign-in method.';
      case 'popup-closed-by-user':
        return 'Sign-in was cancelled.';
      default:
        return e.message ?? 'Authentication failed. Please try again.';
    }
  }
}
