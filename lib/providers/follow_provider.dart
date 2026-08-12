import 'package:flutter/foundation.dart';
import '../repositories/follow_repository.dart';

/// Global ChangeNotifier managing the user follow graph.
///
/// Registered in main.dart so any screen can read/watch follow state without
/// route-scoping. All mutations are in-memory (backend stub ready).
class FollowProvider extends ChangeNotifier {
  final FollowRepository _repository;

  FollowProvider({required FollowRepository repository})
      : _repository = repository;

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Whether [currentUserId] is currently following [targetId].
  bool isFollowing(String currentUserId, String targetId) =>
      _repository.isFollowing(currentUserId, targetId);

  /// Toggles follow/unfollow for [currentUserId] → [targetId].
  /// Returns the new following state (true = now following).
  bool toggleFollow(String currentUserId, String targetId) {
    final nowFollowing = !_repository.isFollowing(currentUserId, targetId);
    if (nowFollowing) {
      _repository.follow(currentUserId, targetId);
    } else {
      _repository.unfollow(currentUserId, targetId);
    }
    notifyListeners();
    return nowFollowing;
  }

  /// Number of accounts [userId] follows.
  int followingCount(String userId) => _repository.followingCount(userId);

  /// Number of accounts following [userId].
  int followerCount(String userId) => _repository.followerCount(userId);

  /// IDs of users that [userId] follows.
  List<String> getFollowing(String userId) => _repository.getFollowing(userId);

  /// IDs of users who follow [userId].
  List<String> getFollowers(String userId) => _repository.getFollowers(userId);
}
