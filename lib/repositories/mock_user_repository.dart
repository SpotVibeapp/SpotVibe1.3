import '../models/user.dart';
import 'firebase_user_repository.dart';
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

  /// Remembers the profile of each social account so a later sign-in that
  /// carries no name/email (e.g. Apple after the first time) keeps the values
  /// from the first sign-in instead of blanking them, like production does.
  final Map<String, AppUser> _socialAccounts = {};

  @override
  Future<AppUser> loginWithSocial({
    required String provider,
    String? name,
    String? email,
    String? avatarUrl,
    String? idToken,
    String? accessToken,
    String? rawNonce,
    String? providerUserId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 600));
    String? clean(String? v) =>
        (v == null || v.trim().isEmpty) ? null : v.trim();
    final cleanName = clean(name);
    final cleanEmail = clean(email);
    // Key by the provider's stable id when we have one, never by an invented
    // email. Fall back to the email/name only for providers without an id.
    final key = clean(providerUserId) ?? cleanEmail ?? cleanName ?? 'anonymous';
    final safeId = '${provider.toLowerCase()}_${key.hashCode.abs()}';
    final previous = _socialAccounts[safeId];
    final resolvedEmail = cleanEmail ?? previous?.email ?? '';
    final resolvedName = cleanName ??
        previous?.displayName ??
        FirebaseUserRepository.resolveDisplayName(email: resolvedEmail);
    final safeAvatar = avatarUrl?.isNotEmpty == true
        ? avatarUrl!
        : previous?.avatarUrl ??
            'https://ui-avatars.com/api/?name=${Uri.encodeComponent(resolvedName)}&size=200&background=6C5CE7&color=fff';
    _currentUser = AppUser(
      id: safeId,
      displayName: resolvedName,
      email: resolvedEmail,
      avatarUrl: safeAvatar,
    );
    _socialAccounts[safeId] = _currentUser!;
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
  Future<void> sendPasswordResetEmail(String email) async {
    await Future.delayed(const Duration(milliseconds: 300));
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
  Future<void> reportContent({
    required String contentType,
    required String contentId,
    String reportedUserId = '',
    required String reason,
  }) async {
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

  @override
  Future<AppUser> updateDisplayName(String displayName) async {
    final user = _currentUser;
    if (user == null) throw Exception('Sign in to edit your profile.');
    _currentUser = user.copyWith(displayName: displayName);
    return _currentUser!;
  }
}
