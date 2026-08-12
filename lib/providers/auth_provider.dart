import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _service;
  final NotificationService? _notifications;

  AuthProvider({
    required AuthService service,
    NotificationService? notificationService,
  })  : _service = service,
        _notifications = notificationService;

  AppUser? _user;
  AppUser? get user => _user;
  bool get isLoggedIn => _user != null;
  bool get isGuest => _user?.isGuest ?? false;

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

  void continueAsGuest() {
    _user = const AppUser(
      id: 'guest',
      displayName: 'Guest',
      email: '',
      avatarUrl: '',
      isGuest: true,
    );
    notifyListeners();
  }

  Future<void> logout() async {
    await _service.logout();
    _user = null;
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

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
