import 'package:shared_preferences/shared_preferences.dart';

/// Persists the user's notification opt-in preferences to SharedPreferences.
///
/// Keys are stable strings; missing keys default to `true` (opted-in) for
/// all preferences so new users don't miss notifications.
class NotificationPreferencesRepository {
  static const _kWeeklyDigest = 'notif_pref_weekly_digest';
  static const _kEventReminders = 'notif_pref_event_reminders';
  static const _kSocialComments = 'notif_pref_social_comments';
  static const _kSocialFriendRsvp = 'notif_pref_social_friend_rsvp';
  static const _kSocialFriendRequests = 'notif_pref_social_friend_requests';
  static const _kCategoryPrefix = 'notif_pref_cat_';

  // ── Read ───────────────────────────────────────────────────────────────────

  Future<bool> getWeeklyDigest() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kWeeklyDigest) ?? true;
  }

  Future<bool> getEventReminders() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kEventReminders) ?? true;
  }

  Future<bool> getSocialComments() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kSocialComments) ?? true;
  }

  Future<bool> getSocialFriendRsvp() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kSocialFriendRsvp) ?? true;
  }

  Future<bool> getSocialFriendRequests() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kSocialFriendRequests) ?? true;
  }

  /// Returns whether alerts for [category] are enabled. Defaults to true.
  Future<bool> getCategoryEnabled(String category) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('$_kCategoryPrefix${category.toLowerCase()}') ?? true;
  }

  /// Returns a map of category → enabled for all known categories.
  Future<Map<String, bool>> getAllCategoryPrefs(List<String> categories) async {
    final prefs = await SharedPreferences.getInstance();
    return {
      for (final cat in categories)
        cat: prefs.getBool('$_kCategoryPrefix${cat.toLowerCase()}') ?? true,
    };
  }

  // ── Write ──────────────────────────────────────────────────────────────────

  Future<void> setWeeklyDigest(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kWeeklyDigest, value);
  }

  Future<void> setEventReminders(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kEventReminders, value);
  }

  Future<void> setSocialComments(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kSocialComments, value);
  }

  Future<void> setSocialFriendRsvp(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kSocialFriendRsvp, value);
  }

  Future<void> setSocialFriendRequests(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kSocialFriendRequests, value);
  }

  Future<void> setCategoryEnabled(String category, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_kCategoryPrefix${category.toLowerCase()}', value);
  }
}
