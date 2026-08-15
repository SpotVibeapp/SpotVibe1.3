import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import '../models/user.dart';
import '../repositories/user_repository.dart';

/// Orchestrates sign-in flows on top of a [UserRepository] (Firebase in
/// production, mock in offline/demo mode). Handles client-side validation
/// and the platform OAuth exchanges, then hands real credentials to the
/// repository.
class AuthService {
  final UserRepository _repository;

  AuthService({required UserRepository repository}) : _repository = repository;

  /// Restores a persisted session (Firebase keeps users signed in across
  /// restarts). Returns null when signed out.
  Future<AppUser?> restoreSession() => _repository.getCurrentUser();

  // ── Google ────────────────────────────────────────────────────────────────
  Future<AppUser> loginWithGoogle() async {
    final googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);
    final account = await googleSignIn.signIn();
    if (account == null) throw Exception('Google sign-in cancelled');
    final authentication = await account.authentication;
    return _repository.loginWithSocial(
      provider: 'google',
      name: account.displayName ?? account.email.split('@').first,
      email: account.email,
      avatarUrl: account.photoUrl,
      idToken: authentication.idToken,
      accessToken: authentication.accessToken,
    );
  }

  // ── Facebook ──────────────────────────────────────────────────────────────
  Future<AppUser> loginWithFacebook() async {
    if (kIsWeb) throw Exception('Facebook login is not supported on web');
    final result = await FacebookAuth.instance.login(
      permissions: ['email', 'public_profile'],
    );
    if (result.status != LoginStatus.success) {
      throw Exception('Facebook sign-in cancelled or failed');
    }
    final data = await FacebookAuth.instance.getUserData(
      fields: 'name,email,picture.width(200)',
    );
    final name = (data['name'] as String?) ?? 'Facebook User';
    final email = (data['email'] as String?) ?? '';
    final avatarUrl = (data['picture']?['data']?['url'] as String?) ?? '';
    return _repository.loginWithSocial(
      provider: 'facebook',
      name: name,
      email: email,
      avatarUrl: avatarUrl,
      accessToken: result.accessToken?.tokenString,
    );
  }

  // ── Apple ─────────────────────────────────────────────────────────────────
  Future<AppUser> loginWithApple() async {
    if (kIsWeb) throw Exception('Apple login is not supported on web');

    // Apple requires a nonce: we send the SHA-256 of a random raw nonce to
    // Apple, then hand the raw nonce to Firebase so it can verify the
    // returned identity token (prevents token replay attacks).
    final rawNonce = _generateNonce();
    final nonceSha256 = sha256.convert(utf8.encode(rawNonce)).toString();

    final credential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      nonce: nonceSha256,
    );
    final firstName = credential.givenName ?? '';
    final lastName = credential.familyName ?? '';
    final fullName =
        ('$firstName $lastName'.trim().isNotEmpty)
            ? '$firstName $lastName'.trim()
            : credential.userIdentifier ?? 'Apple User';
    final email = credential.email ?? '${credential.userIdentifier}@privaterelay.appleid.com';
    return _repository.loginWithSocial(
      provider: 'apple',
      name: fullName,
      email: email,
      avatarUrl: null,
      idToken: credential.identityToken,
      rawNonce: rawNonce,
    );
  }

  Future<AppUser> login(String email, String password) async {
    final trimmedEmail = email.trim();
    // NOTE: passwords are intentionally NOT trimmed — leading/trailing spaces
    // can be part of a legitimate password.
    if (trimmedEmail.isEmpty) throw ArgumentError('Email is required');
    if (password.isEmpty) throw ArgumentError('Password is required');
    if (!trimmedEmail.contains('@')) throw ArgumentError('Invalid email format');
    if (password.length < 6) throw ArgumentError('Password must be at least 6 characters');
    return _repository.login(trimmedEmail, password);
  }

  Future<AppUser> register(String name, String email, String password) async {
    final trimmedName = name.trim();
    final trimmedEmail = email.trim();
    // NOTE: passwords are intentionally NOT trimmed — leading/trailing spaces
    // can be part of a legitimate password.
    if (trimmedName.isEmpty) throw ArgumentError('Name is required');
    if (trimmedEmail.isEmpty) throw ArgumentError('Email is required');
    if (!trimmedEmail.contains('@')) throw ArgumentError('Invalid email format');
    if (password.length < 6) throw ArgumentError('Password must be at least 6 characters');
    return _repository.register(trimmedName, trimmedEmail, password);
  }

  Future<void> logout() async {
    await _repository.logout();
  }

  /// Permanently deletes the current user's account and associated data.
  /// [password] re-authenticates email/password accounts.
  Future<void> deleteAccount({String? password}) async {
    await _repository.deleteAccount(password: password);
  }

  Future<void> blockUser(String userId) async {
    await _repository.blockUser(userId);
  }

  Future<void> reportUser(String userId, String reason) async {
    await _repository.reportUser(userId, reason);
  }

  Future<void> addFriend(String userId) async {
    await _repository.addFriend(userId);
  }

  /// Cryptographically secure random nonce for Apple Sign-In.
  static String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
  }
}
