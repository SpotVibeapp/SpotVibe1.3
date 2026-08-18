import '../models/user.dart';
import 'user_repository.dart';

/// In-memory fake of [UserRepository].
///
/// Kept for offline development, demos, and unit tests. Any email/password
/// combination "works" and sessions vanish when the app restarts. Production
/// uses [FirebaseUserRepository] instead (see main.dart).
class MockUserRepository implements UserRepository {
  AppUser? _currentUser;
  final Set<String> _blockedIds = {};

  @override
  Future<AppUser?> getCurrentUser() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _currentUser;
  }

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
    await Future.delayed(const Duration(milliseconds: 600));
    final safeId = '${provider.toLowerCase()}_${email.hashCode.abs()}';
    final safeAvatar = avatarUrl?.isNotEmpty == true
        ? avatarUrl!
        : 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(name)}&size=200&background=6C5CE7&color=fff';
    _currentUser = AppUser(
      id: safeId,
      displayName: name,
      email: email,
      avatarUrl: safeAvatar,
    );
    return _currentUser!;
  }

  @override
  Future<AppUser> login(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 800));
    _currentUser = AppUser(
      id: 'user_1',
      displayName: email.split('@').first.replaceAll('.', ' '),
      email: email,
      avatarUrl: 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(email.split('@').first)}&size=200&background=6C5CE7&color=fff',
    );
    return _currentUser!;
  }

  @override
  Future<AppUser> register(String name, String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 800));
    _currentUser = AppUser(
      id: 'user_1',
      displayName: name,
      email: email,
      avatarUrl: 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(name)}&size=200&background=6C5CE7&color=fff',
    );
    return _currentUser!;
  }

  @override
  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _currentUser = null;
  }

  @override
  Future<void> addFriend(String userId) async {
    await Future.delayed(const Duration(milliseconds: 300));
  }

  @override
  Future<void> blockUser(String userId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _blockedIds.add(userId);
  }

  @override
  Future<void> reportUser(String userId, String reason) async {
    await Future.delayed(const Duration(milliseconds: 300));
  }

  @override
  Future<void> deleteAccount({String? password}) async {
    await Future.delayed(const Duration(milliseconds: 400));
    _currentUser = null;
  }

  @override
  Future<AppUser> updateAvatarUrl(String avatarUrl) async {
    final user = _currentUser;
    if (user == null) throw Exception('Sign in to change your photo.');
    _currentUser = user.copyWith(avatarUrl: avatarUrl);
    return _currentUser!;
  }
}
