/// In-memory follow graph repository.
///
/// Each key is a userId; the value is the Set of userIds that key is following.
/// Seeded with a realistic social graph for demo purposes.
class FollowRepository {
  // followerId → Set<followingId>
  final Map<String, Set<String>> _following = {
    'user_1': {'user_2', 'user_3', 'user_4', 'organizer_1'},
    'user_2': {'user_1', 'user_3'},
    'user_3': {'user_1'},
    'user_4': {'user_1', 'user_2'},
    'organizer_1': {'user_1', 'user_2', 'user_3', 'user_4'},
  };

  /// Returns true if [followerId] is following [targetId].
  bool isFollowing(String followerId, String targetId) {
    return _following[followerId]?.contains(targetId) ?? false;
  }

  /// Adds a follow relationship. No-op if already following.
  void follow(String followerId, String targetId) {
    _following.putIfAbsent(followerId, () => {}).add(targetId);
  }

  /// Removes a follow relationship. No-op if not following.
  void unfollow(String followerId, String targetId) {
    _following[followerId]?.remove(targetId);
  }

  /// Returns the list of userIds that [userId] is following.
  List<String> getFollowing(String userId) =>
      List.unmodifiable(_following[userId]?.toList() ?? []);

  /// Returns the list of userIds who follow [userId].
  List<String> getFollowers(String userId) {
    return _following.entries
        .where((e) => e.value.contains(userId))
        .map((e) => e.key)
        .toList();
  }

  /// Number of accounts [userId] is following.
  int followingCount(String userId) => _following[userId]?.length ?? 0;

  /// Number of accounts following [userId].
  int followerCount(String userId) =>
      _following.values.where((set) => set.contains(userId)).length;
}
