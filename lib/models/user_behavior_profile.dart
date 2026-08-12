import 'dart:convert';

/// Holds all implicit behavioral signals collected for the current user.
///
/// Three tiers of engagement strength (highest → lowest):
///   attended  (weight ×10 in scoring)
///   saved     (weight ×4)
///   viewed    (weight ×1)
///
/// Serializes to/from JSON so it can be persisted in SharedPreferences.
class UserBehaviorProfile {
  /// How many times the user viewed a detail page per category.
  final Map<String, int> categoriesViewed;

  /// How many events the user bookmarked per category.
  final Map<String, int> categoriesSaved;

  /// How many events the user RSVP'd to per category (highest signal).
  final Map<String, int> categoriesAttended;

  /// Running average of prices across events the user has interacted with.
  final double avgPriceInteracted;

  /// Running count of interactions (used to update the rolling average).
  final int priceInteractionCount;

  /// How many interactions occurred per weekday name ('monday', 'tuesday', …).
  final Map<String, int> preferredDays;

  /// How many interactions occurred per time-of-day slot
  /// ('morning', 'afternoon', 'evening', 'night').
  final Map<String, int> preferredTimes;

  const UserBehaviorProfile({
    this.categoriesViewed = const {},
    this.categoriesSaved = const {},
    this.categoriesAttended = const {},
    this.avgPriceInteracted = 0,
    this.priceInteractionCount = 0,
    this.preferredDays = const {},
    this.preferredTimes = const {},
  });

  /// Returns the weighted interest score for a category.
  /// Attended ×10, saved ×4, viewed ×1.
  double interestScore(String category) {
    final attended = (categoriesAttended[category] ?? 0) * 10.0;
    final saved = (categoriesSaved[category] ?? 0) * 4.0;
    final viewed = (categoriesViewed[category] ?? 0) * 1.0;
    return attended + saved + viewed;
  }

  /// Returns the top categories by weighted interest score, highest first.
  List<String> topCategories({int limit = 3}) {
    final all = {
      ...categoriesViewed.keys,
      ...categoriesSaved.keys,
      ...categoriesAttended.keys,
    };
    final sorted = all.toList()
      ..sort((a, b) => interestScore(b).compareTo(interestScore(a)));
    return sorted.take(limit).toList();
  }

  /// Returns true once the user has accumulated enough data for personalization
  /// to meaningfully re-order the feed.
  bool get isWarm =>
      categoriesViewed.values.fold(0, (a, b) => a + b) >= 3 ||
      categoriesSaved.values.fold(0, (a, b) => a + b) >= 1;

  // ── Immutable update helpers ───────────────────────────────────────────────

  UserBehaviorProfile recordView({
    required String category,
    required double? price,
    required DateTime dateTime,
  }) =>
      _update(
        viewedCategory: category,
        price: price,
        dateTime: dateTime,
      );

  UserBehaviorProfile recordSave({
    required String category,
    required double? price,
    required DateTime dateTime,
  }) =>
      _update(
        savedCategory: category,
        price: price,
        dateTime: dateTime,
      );

  UserBehaviorProfile recordAttend({
    required String category,
    required double? price,
    required DateTime dateTime,
  }) =>
      _update(
        attendedCategory: category,
        price: price,
        dateTime: dateTime,
      );

  UserBehaviorProfile _update({
    String? viewedCategory,
    String? savedCategory,
    String? attendedCategory,
    double? price,
    required DateTime dateTime,
  }) {
    // Rolling average update
    double newAvg = avgPriceInteracted;
    int newCount = priceInteractionCount;
    if (price != null && price > 0) {
      newCount++;
      newAvg = avgPriceInteracted + (price - avgPriceInteracted) / newCount;
    }

    // Day of week key
    final dayKey = _weekdayName(dateTime.weekday);
    final timeKey = _timeName(dateTime.hour);

    return UserBehaviorProfile(
      categoriesViewed: viewedCategory != null
          ? _increment(categoriesViewed, viewedCategory)
          : categoriesViewed,
      categoriesSaved: savedCategory != null
          ? _increment(categoriesSaved, savedCategory)
          : categoriesSaved,
      categoriesAttended: attendedCategory != null
          ? _increment(categoriesAttended, attendedCategory)
          : categoriesAttended,
      avgPriceInteracted: newAvg,
      priceInteractionCount: newCount,
      preferredDays: _increment(preferredDays, dayKey),
      preferredTimes: _increment(preferredTimes, timeKey),
    );
  }

  static Map<String, int> _increment(Map<String, int> map, String key) {
    final copy = Map<String, int>.from(map);
    copy[key] = (copy[key] ?? 0) + 1;
    return copy;
  }

  static String _weekdayName(int weekday) {
    const names = [
      'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday',
    ];
    return names[(weekday - 1).clamp(0, 6)];
  }

  static String _timeName(int hour) {
    if (hour >= 6 && hour < 12) return 'morning';
    if (hour >= 12 && hour < 17) return 'afternoon';
    if (hour >= 17 && hour < 21) return 'evening';
    return 'night';
  }

  // ── JSON serialization ────────────────────────────────────────────────────

  Map<String, dynamic> toJson() => {
        'categoriesViewed': categoriesViewed,
        'categoriesSaved': categoriesSaved,
        'categoriesAttended': categoriesAttended,
        'avgPriceInteracted': avgPriceInteracted,
        'priceInteractionCount': priceInteractionCount,
        'preferredDays': preferredDays,
        'preferredTimes': preferredTimes,
      };

  factory UserBehaviorProfile.fromJson(Map<String, dynamic> json) {
    Map<String, int> _intMap(dynamic raw) {
      if (raw is Map) {
        return raw.map((k, v) => MapEntry(k.toString(), (v as num).toInt()));
      }
      return {};
    }

    return UserBehaviorProfile(
      categoriesViewed: _intMap(json['categoriesViewed']),
      categoriesSaved: _intMap(json['categoriesSaved']),
      categoriesAttended: _intMap(json['categoriesAttended']),
      avgPriceInteracted: (json['avgPriceInteracted'] as num?)?.toDouble() ?? 0,
      priceInteractionCount: (json['priceInteractionCount'] as num?)?.toInt() ?? 0,
      preferredDays: _intMap(json['preferredDays']),
      preferredTimes: _intMap(json['preferredTimes']),
    );
  }

  String toJsonString() => jsonEncode(toJson());

  factory UserBehaviorProfile.fromJsonString(String raw) =>
      UserBehaviorProfile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
}
