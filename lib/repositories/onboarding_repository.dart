import 'package:shared_preferences/shared_preferences.dart';

const _kOnboardingDoneKey = 'vibely_onboarding_done';
const _kInterestsKey = 'vibely_interests';

/// Persists first-launch onboarding state and the user's selected interest
/// categories. All operations are no-ops safe to call without error handling.
class OnboardingRepository {
  /// Whether the user has completed or skipped the onboarding flow.
  Future<bool> isOnboardingDone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kOnboardingDoneKey) ?? false;
  }

  /// Mark onboarding as completed so it is never shown again.
  Future<void> markDone() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kOnboardingDoneKey, true);
  }

  /// Returns the previously saved interest categories, or an empty list.
  Future<List<String>> getInterests() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kInterestsKey) ?? '';
    if (raw.isEmpty) return [];
    return raw.split(',').where((s) => s.isNotEmpty).toList();
  }

  /// Saves the selected interest categories.
  Future<void> saveInterests(List<String> interests) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kInterestsKey, interests.join(','));
  }
}
