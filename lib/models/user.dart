class AppUser {
  final String id;
  final String displayName;
  final String email;
  final String avatarUrl;
  final List<String> friendIds;
  final List<String> blockedIds;
  final bool isGuest;

  const AppUser({
    required this.id,
    required this.displayName,
    required this.email,
    required this.avatarUrl,
    this.friendIds = const [],
    this.blockedIds = const [],
    this.isGuest = false,
  });

  AppUser copyWith({
    String? displayName,
    String? email,
    String? avatarUrl,
    List<String>? friendIds,
    List<String>? blockedIds,
    bool? isGuest,
  }) =>
      AppUser(
        id: id,
        displayName: displayName ?? this.displayName,
        email: email ?? this.email,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        friendIds: friendIds ?? this.friendIds,
        blockedIds: blockedIds ?? this.blockedIds,
        isGuest: isGuest ?? this.isGuest,
      );
}
