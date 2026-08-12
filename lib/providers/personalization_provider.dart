import 'package:flutter/foundation.dart';
import '../models/event.dart';
import '../models/user_behavior_profile.dart';
import '../repositories/personalization_repository.dart';
import '../services/personalization_service.dart';

/// Global provider that owns the live [UserBehaviorProfile] and exposes
/// tracking methods and feed personalization.
///
/// Registration: app-global in main.dart MultiProvider (like NotificationProvider).
/// Usage: read via `context.read<PersonalizationProvider>()` to record signals;
///         watch via `context.watch<PersonalizationProvider>()` for UI state.
class PersonalizationProvider extends ChangeNotifier {
  final PersonalizationRepository _repository;
  final PersonalizationService _service;

  UserBehaviorProfile _profile = const UserBehaviorProfile();
  bool _loaded = false;

  PersonalizationProvider({
    required PersonalizationRepository repository,
    PersonalizationService service = const PersonalizationService(),
  })  : _repository = repository,
        _service = service {
    _load();
  }

  // ── Public state ──────────────────────────────────────────────────────────

  UserBehaviorProfile get profile => _profile;

  /// True once the profile has been loaded from storage and has enough signals
  /// to meaningfully influence the feed ranking.
  bool get isActive => _loaded && _profile.isWarm;

  /// The user's top interest categories, sorted by engagement strength.
  List<String> get topCategories => _profile.topCategories(limit: 3);

  // ── Tracking API ──────────────────────────────────────────────────────────

  /// Call when the user opens an event's detail page.
  Future<void> recordView(Event event) async {
    _update(_profile.recordView(
      category: event.category,
      price: event.cost,
      dateTime: event.dateTime,
    ));
  }

  /// Call when the user bookmarks / saves an event.
  Future<void> recordSave(Event event) async {
    _update(_profile.recordSave(
      category: event.category,
      price: event.cost,
      dateTime: event.dateTime,
    ));
  }

  /// Call when the user RSVP's to an event (highest-signal action).
  Future<void> recordAttend(Event event) async {
    _update(_profile.recordAttend(
      category: event.category,
      price: event.cost,
      dateTime: event.dateTime,
    ));
  }

  // ── Scoring / ranking ─────────────────────────────────────────────────────

  /// Returns a personalized ranking of [events] when [isActive] is true.
  /// Falls back to the original order if the profile is cold.
  List<Event> rank(List<Event> events, {double? userLat, double? userLng}) {
    if (!isActive) return events;
    return _service.rank(
      events: events,
      profile: _profile,
      userLat: userLat,
      userLng: userLng,
    );
  }

  /// Clears all learned signals and resets to a blank profile.
  Future<void> reset() async {
    _profile = const UserBehaviorProfile();
    await _repository.clearProfile();
    notifyListeners();
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  Future<void> _load() async {
    _profile = await _repository.loadProfile();
    _loaded = true;
    notifyListeners();
  }

  void _update(UserBehaviorProfile updated) {
    _profile = updated;
    notifyListeners();
    // Persist asynchronously — fire and forget.
    _repository.saveProfile(updated);
  }
}
