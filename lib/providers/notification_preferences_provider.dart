import 'package:flutter/foundation.dart';
import '../repositories/notification_preferences_repository.dart';

/// Known event categories that can be opted-into for discovery alerts.
const kNotificationCategories = [
  'Music',
  'Food & Drink',
  'Arts',
  'Sports',
  'Social',
  'Comedy',
  'Outdoors',
  'Tech',
  'Film',
  'Wellness',
];

/// [ChangeNotifier] for the notification preferences screen.
///
/// Route-scoped — created in the `/notification-preferences` route builder.
class NotificationPreferencesProvider extends ChangeNotifier {
  NotificationPreferencesProvider({
    required NotificationPreferencesRepository repository,
  }) : _repo = repository;

  final NotificationPreferencesRepository _repo;

  bool _loaded = false;
  bool _eventReminders = true;
  bool _weeklyDigest = true;
  bool _socialComments = true;
  bool _socialFriendRsvp = true;
  bool _socialFriendRequests = true;
  Map<String, bool> _categoryPrefs = {};

  bool get isLoaded => _loaded;
  bool get eventReminders => _eventReminders;
  bool get weeklyDigest => _weeklyDigest;
  bool get socialComments => _socialComments;
  bool get socialFriendRsvp => _socialFriendRsvp;
  bool get socialFriendRequests => _socialFriendRequests;
  Map<String, bool> get categoryPrefs => Map.unmodifiable(_categoryPrefs);

  bool isCategoryEnabled(String category) =>
      _categoryPrefs[category] ?? true;

  // ── Load ───────────────────────────────────────────────────────────────────

  Future<void> load() async {
    _eventReminders = await _repo.getEventReminders();
    _weeklyDigest = await _repo.getWeeklyDigest();
    _socialComments = await _repo.getSocialComments();
    _socialFriendRsvp = await _repo.getSocialFriendRsvp();
    _socialFriendRequests = await _repo.getSocialFriendRequests();
    _categoryPrefs =
        await _repo.getAllCategoryPrefs(kNotificationCategories);
    _loaded = true;
    notifyListeners();
  }

  // ── Toggle helpers ─────────────────────────────────────────────────────────

  Future<void> toggleEventReminders(bool value) async {
    _eventReminders = value;
    notifyListeners();
    await _repo.setEventReminders(value);
  }

  Future<void> toggleWeeklyDigest(bool value) async {
    _weeklyDigest = value;
    notifyListeners();
    await _repo.setWeeklyDigest(value);
  }

  Future<void> toggleSocialComments(bool value) async {
    _socialComments = value;
    notifyListeners();
    await _repo.setSocialComments(value);
  }

  Future<void> toggleSocialFriendRsvp(bool value) async {
    _socialFriendRsvp = value;
    notifyListeners();
    await _repo.setSocialFriendRsvp(value);
  }

  Future<void> toggleSocialFriendRequests(bool value) async {
    _socialFriendRequests = value;
    notifyListeners();
    await _repo.setSocialFriendRequests(value);
  }

  Future<void> toggleCategory(String category, bool value) async {
    _categoryPrefs = Map.of(_categoryPrefs)..[category] = value;
    notifyListeners();
    await _repo.setCategoryEnabled(category, value);
  }

  Future<void> enableAllCategories() async {
    for (final cat in kNotificationCategories) {
      _categoryPrefs[cat] = true;
      await _repo.setCategoryEnabled(cat, true);
    }
    notifyListeners();
  }
}
