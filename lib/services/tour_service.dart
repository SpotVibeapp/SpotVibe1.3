import 'package:shared_preferences/shared_preferences.dart';

/// Persists which guided tours the user has already seen, and supports
/// resetting them all so the tours can be replayed from Profile.
class TourService {
  TourService._();

  static const String _kSeenKey = 'spotvibe_tour_seen';

  static Future<Set<String>> _seen() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_kSeenKey) ?? const <String>[]).toSet();
  }

  /// Whether the tour with [tourId] has already been shown.
  static Future<bool> isSeen(String tourId) async =>
      (await _seen()).contains(tourId);

  /// Marks [tourId] as seen so it won't auto-play again.
  static Future<void> markSeen(String tourId) async {
    final prefs = await SharedPreferences.getInstance();
    final ids = (prefs.getStringList(_kSeenKey) ?? const <String>[]).toSet();
    ids.add(tourId);
    await prefs.setStringList(_kSeenKey, ids.toList());
  }

  /// Clears all "seen" flags — every tour will play again on its next screen.
  static Future<void> resetAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kSeenKey);
  }
}
