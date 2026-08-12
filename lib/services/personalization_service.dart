import 'dart:math' as math;
import '../models/event.dart';
import '../models/user_behavior_profile.dart';

/// Pure scoring engine — no state, no Flutter dependencies.
///
/// Scores each event against the user's [UserBehaviorProfile] using five
/// weighted signals, matching the reference JavaScript implementation:
///
///   1. Category interest   — sum of (attended×10 + saved×4 + viewed×1)
///   2. Price match         — +5 if price ≤ avg interacted price × 1.5
///   3. Distance proximity  — up to +10 (closer = more points)
///   4. Time-of-day match   — +3 if event's time slot is user's most preferred
///   5. Recency boost       — up to +5 (events created within 5 days get a boost)
///
/// A higher score means the event is more likely to engage this user.
class PersonalizationService {
  const PersonalizationService();

  /// Returns a ranked copy of [events], most relevant first.
  /// Falls back to chronological order if the profile has no signals yet.
  List<Event> rank({
    required List<Event> events,
    required UserBehaviorProfile profile,
    double? userLat,
    double? userLng,
  }) {
    if (!profile.isWarm) return events;

    final scored = events
        .map((e) => _ScoredEvent(
              event: e,
              score: scoreEvent(
                event: e,
                profile: profile,
                userLat: userLat,
                userLng: userLng,
              ),
            ))
        .toList()
      ..sort((a, b) => b.score.compareTo(a.score));

    return scored.map((s) => s.event).toList();
  }

  /// Computes the personalization score for a single event.
  double scoreEvent({
    required Event event,
    required UserBehaviorProfile profile,
    double? userLat,
    double? userLng,
  }) {
    double score = 0;

    // ── 1. Category interest (highest weight) ─────────────────────────────
    // Uses weighted sum: attended interactions count most, saves next, views last.
    score += profile.interestScore(event.category);

    // ── 2. Price match ─────────────────────────────────────────────────────
    // +5 if event price is within 1.5× of the user's average interacted price.
    if (profile.avgPriceInteracted > 0) {
      final eventPrice = event.cost ?? 0.0;
      if (eventPrice <= profile.avgPriceInteracted * 1.5) {
        score += 5;
      }
    } else if (event.isFree) {
      // No price history yet but event is free → slight boost.
      score += 2;
    }

    // ── 3. Distance proximity (+0 to +10) ─────────────────────────────────
    if (userLat != null && userLng != null &&
        !(event.latitude == 0 && event.longitude == 0)) {
      final dist = _haversineDistanceMiles(
          userLat, userLng, event.latitude, event.longitude);
      score += math.max(0, 10 - dist);
    }

    // ── 4. Time-of-day preference (+3) ────────────────────────────────────
    final eventTimeSlot = _timeName(event.dateTime.hour);
    final topTime = _topKey(profile.preferredTimes);
    if (topTime != null && eventTimeSlot == topTime) {
      score += 3;
    }

    // ── 5. Recency boost (+0 to +5) ───────────────────────────────────────
    // Events created recently get a small boost to surface fresh content.
    final ageInDays =
        DateTime.now().difference(event.dateTime).inHours.abs() / 24.0;
    score += math.max(0.0, 5.0 - ageInDays);

    return score;
  }

  /// Returns the key with the highest count in a map, or null if empty.
  static String? _topKey(Map<String, int> map) {
    if (map.isEmpty) return null;
    return map.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  }

  static String _timeName(int hour) {
    if (hour >= 6 && hour < 12) return 'morning';
    if (hour >= 12 && hour < 17) return 'afternoon';
    if (hour >= 17 && hour < 21) return 'evening';
    return 'night';
  }
}

class _ScoredEvent {
  final Event event;
  final double score;
  const _ScoredEvent({required this.event, required this.score});
}

double _haversineDistanceMiles(
    double lat1, double lng1, double lat2, double lng2) {
  const earthRadiusMiles = 3958.8;
  final dLat = _toRad(lat2 - lat1);
  final dLng = _toRad(lng2 - lng1);
  final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(_toRad(lat1)) *
          math.cos(_toRad(lat2)) *
          math.sin(dLng / 2) *
          math.sin(dLng / 2);
  final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  return earthRadiusMiles * c;
}

double _toRad(double deg) => deg * math.pi / 180;
