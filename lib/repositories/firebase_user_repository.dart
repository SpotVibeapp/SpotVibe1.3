import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

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
/// - Blocks are stored at `blocks/{uid}/blocked/{targetUid}`.
/// - Account deletion re-authenticates (when a password is supplied), purges
///   the user's Firestore data, then deletes the Firebase Auth user.
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

  // ── Social graph ──────────────────────────────────────────────────────────

  @override
  Future<void> addFriend(String userId) async {
    // TODO(backend): store friendships in Firestore (e.g. friends/{uid}).
  }

  @override
  Future<void> blockUser(String userId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null || userId.isEmpty || userId == uid) return;
    try {
      await _db
          .collection('blocks')
          .doc(uid)
          .collection('blocked')
          .doc(userId)
          .set({'blockedAt': FieldValue.serverTimestamp()});
    } catch (_) {
      // Blocking should never crash the app.
    }
  }

  @override
  Future<void> reportUser(String userId, String reason) async {
    try {
      await _db.collection('user_reports').add({
        'reportedUserId': userId,
        'reportedById': _auth.currentUser?.uid,
        'reason': reason,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // Reporting should never crash the app.
    }
  }

  // ── Account deletion ──────────────────────────────────────────────────────

  @override
  Future<void> deleteAccount({String? password}) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No signed-in account to delete.');

    // Re-authenticate email/password accounts before a destructive op.
    if (password != null && password.isNotEmpty) {
      final email = user.email;
      if (email == null || email.isEmpty) {
        throw Exception('This account has no email/password to verify.');
      }
      try {
        await user.reauthenticateWithCredential(
          EmailAuthProvider.credential(email: email, password: password),
        );
      } on FirebaseAuthException catch (e) {
        throw Exception(messageForAuthException(e));
      }
    }

    // Purge Firestore data first (while still authenticated, so security
    // rules allow the deletes).
    try {
      await _purgeUserData(user.uid);
    } catch (e) {
      debugPrint('Client-side purge incomplete ($e). '
          'The deleteUser Cloud Function performs authoritative cleanup.');
    }

    try {
      await user.delete();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        throw Exception(
          'For security, sign out and sign back in, then delete your account again.',
        );
      }
      throw Exception(messageForAuthException(e));
    }
  }

  /// Best-effort client-side cleanup of all Firestore docs owned by [uid].
  /// Runs before the auth user is deleted. Each collection is purged in its
  /// own guard so a missing index (collection-group queries need one) never
  /// aborts the rest of the batch. The `deleteUser` Cloud Function
  /// (see functions/) performs the authoritative cleanup server-side.
  Future<void> _purgeUserData(String uid) async {
    final batch = _db.batch();

    batch.delete(_users.doc(uid));
    batch.delete(_db.collection('blocks').doc(uid));

    try {
      final saves = await _users.doc(uid).collection('saved_events').get();
      for (final d in saves.docs) {
        batch.delete(d.reference);
      }
    } catch (e) {
      debugPrint('saved_events purge failed: $e');
    }

    try {
      final blocked = await _db
          .collection('blocks')
          .doc(uid)
          .collection('blocked')
          .get();
      for (final d in blocked.docs) {
        batch.delete(d.reference);
      }
    } catch (e) {
      debugPrint('blocks purge failed: $e');
    }

    try {
      final userEvents = await _db
          .collection('user_events')
          .where('creatorId', isEqualTo: uid)
          .get();
      for (final d in userEvents.docs) {
        batch.delete(d.reference);
        batch.delete(_db.collection('events').doc(d.id));
      }
    } catch (e) {
      debugPrint('user_events purge failed: $e');
    }

    // Collection-group queries require composite indexes (see
    // firestore.indexes.json). If the index is missing, log and continue —
    // the deleteUser Cloud Function performs authoritative cleanup.
    try {
      final rsvps = await _db
          .collectionGroup('rsvps')
          .where('userId', isEqualTo: uid)
          .get();
      for (final d in rsvps.docs) {
        batch.delete(d.reference);
      }
    } catch (e) {
      debugPrint('rsvps purge skipped (deploy firestore.indexes.json): $e');
    }

    try {
      final comments = await _db
          .collectionGroup('comments')
          .where('authorId', isEqualTo: uid)
          .get();
      for (final d in comments.docs) {
        batch.delete(d.reference);
      }
    } catch (e) {
      debugPrint('comments purge skipped (deploy firestore.indexes.json): $e');
    }

    try {
      final claims = await _db
          .collection('event_claims')
          .where('userId', isEqualTo: uid)
          .get();
      for (final d in claims.docs) {
        batch.delete(d.reference);
      }
    } catch (e) {
      debugPrint('event_claims purge failed: $e');
    }

    await batch.commit();
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
    var avatar = (user.photoURL?.isNotEmpty ?? false)
        ? user.photoURL!
        : (fallbackAvatar?.isNotEmpty == true
            ? fallbackAvatar!
            : _generatedAvatar(displayName));
    final email = user.email ?? '';

    // Prefer a photo the user already uploaded — never clobber it on login.
    try {
      final existing = await _users.doc(user.uid).get();
      final stored = existing.data()?['avatarUrl'] as String?;
      if (stored != null &&
          stored.isNotEmpty &&
          !stored.contains('ui-avatars.com')) {
        avatar = stored;
      }
    } catch (_) {}

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
      isAdmin: await _isAdmin(user.uid),
    );
  }

  @override
  Future<AppUser> updateAvatarUrl(String avatarUrl) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Sign in to change your photo.');
    try {
      await user.updatePhotoURL(avatarUrl);
    } catch (e) {
      debugPrint('Auth photoURL update skipped: $e');
    }
    try {
      await _users.doc(user.uid).set({
        'avatarUrl': avatarUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Firestore avatar update failed: $e');
      throw Exception('Could not save your photo. Try again.');
    }
    return _appUserFor(user);
  }

  /// Whether [uid] is listed in the `admins/{uid}` collection.
  /// Best-effort: any failure resolves to `false`.
  Future<bool> _isAdmin(String uid) async {
    try {
      final snap = await _db.collection('admins').doc(uid).get();
      return snap.exists;
    } catch (_) {
      return false;
    }
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
        // Do not overwrite avatarUrl — the user may have uploaded a photo.
        await ref.update({
          'email': email,
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
