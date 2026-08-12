import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_behavior_profile.dart';

const _kProfileKey = 'spotvibe_behavior_profile';
const _kProfileKeyLegacy = 'vibely_behavior_profile';

/// Persists the [UserBehaviorProfile] to SharedPreferences so implicit
/// learning signals survive app restarts.
///
/// All methods are safe to call without try/catch — failures are silenced
/// and return sensible defaults.
class PersonalizationRepository {
  /// Loads the saved profile, or returns a fresh empty one if none exists.
  Future<UserBehaviorProfile> loadProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kProfileKey) ??
          prefs.getString(_kProfileKeyLegacy);
      if (raw == null || raw.isEmpty) return const UserBehaviorProfile();
      return UserBehaviorProfile.fromJsonString(raw);
    } catch (_) {
      return const UserBehaviorProfile();
    }
  }

  /// Saves the profile. Silently swallows errors (non-critical operation).
  Future<void> saveProfile(UserBehaviorProfile profile) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kProfileKey, profile.toJsonString());
    } catch (_) {}
  }

  /// Wipes the stored profile — useful for sign-out or profile reset.
  Future<void> clearProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kProfileKey);
      await prefs.remove(_kProfileKeyLegacy);
    } catch (_) {}
  }
}
