import 'dart:async';

import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../services/revenue_cat_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _service;
  final NotificationService? _notifications;
  final RevenueCatService? _revenueCat;

  AuthProvider({
    required AuthService service,
    NotificationService? notificationService,
    RevenueCatService? revenueCatService,
  })  : _service = service,
        _notifications = notificationService,
        _revenueCat = revenueCatService;

  AppUser? _user;
  AppUser? get user => _user;
  bool get isLoggedIn => _user != null;
  bool get isGuest => _user?.isGuest ?? false;

  /// Whether the signed-in user is an app administrator / moderator.
  bool get isAdmin => _user?.isAdmin ?? false;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  /// Restores a persisted session at app start (Firebase sessions survive
  /// restarts). Safe to call once from main.dart; no-op on failure.
  Future<void> restoreSession() async {
    try {
      _user = await _service.restoreSession();
    } catch (_) {
      _user = null;
    }
    await _syncRevenueCatIdentity();
    notifyListeners();
  }

  Future<bool> loginWithGoogle() => _socialLogin(_service.loginWithGoogle);
  Future<bool> loginWithFacebook() => _socialLogin(_service.loginWithFacebook);
  Future<bool> loginWithApple() => _socialLogin(_service.loginWithApple);

  Future<bool> _socialLogin(Future<AppUser> Function() call) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _user = await call();
      await _syncRevenueCatIdentity();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      _error = (msg.toLowerCase().contains('cancel')) ? null : msg;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _user = await _service.login(email, password);
      await _syncRevenueCatIdentity();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e is ArgumentError ? e.message.toString() : 'Login failed';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(String name, String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _user = await _service.register(name, email, password);
      await _syncRevenueCatIdentity();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e is ArgumentError ? e.message.toString() : 'Registration failed';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Requests a reset link without disclosing whether the address belongs to
  /// an account. Firebase sends the actual email when appropriate.
  Future<bool> sendPasswordResetEmail(String email) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _service.sendPasswordResetEmail(email);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e is ArgumentError ? e.message.toString() : 'Could not send reset email.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void continueAsGuest() {
    _user = const AppUser(
      id: 'guest',
      displayName: 'Guest',
      email: '',
      avatarUrl: '',
      isGuest: true,
    );
    unawaited(_syncRevenueCatIdentity());
    notifyListeners();
  }

  Future<void> logout() async {
    await _service.logout();
    _user = null;
    await _syncRevenueCatIdentity();
    notifyListeners();
  }

  /// Permanently deletes the account and signs out on success.
  Future<void> deleteAccount({String? password}) async {
    await _service.deleteAccount(password: password);
    _user = null;
    await _syncRevenueCatIdentity();
    notifyListeners();
  }

  Future<void> blockUser(String userId) async {
    try {
      await _service.blockUser(userId);
    } catch (_) {}
  }

  Future<void> reportUser(String userId, String reason) async {
    try {
      await _service.reportUser(userId, reason);
    } catch (_) {}
  }

  Future<void> addFriend(String userId, {String friendName = 'this user'}) async {
    try {
      await _service.addFriend(userId);
      _notifications?.notifyFriendRequest(
        fromName: friendName,
        isSentByMe: true,
      );
    } catch (_) {}
  }

  /// Keeps RevenueCat tied to the Firebase UID, so a store purchase or
  /// partner offer follows the same SpotVibe account across devices.
  Future<void> _syncRevenueCatIdentity() async {
    final revenueCat = _revenueCat;
    final user = _user;
    if (revenueCat == null) return;
    if (user == null || user.isGuest) {
      await revenueCat.logOut();
    } else {
      await revenueCat.logIn(user.id);
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> updateAvatarUrl(String avatarUrl) async {
    _user = await _service.updateAvatarUrl(avatarUrl);
    notifyListeners();
  }
}
