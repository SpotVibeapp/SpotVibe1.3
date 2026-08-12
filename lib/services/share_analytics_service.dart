import 'package:flutter/foundation.dart';

/// Share method identifiers — kept as constants so callers never typo them.
class ShareMethod {
  const ShareMethod._();

  static const String card = 'share_card';
  static const String link = 'native_share';
  static const String clipboard = 'clipboard';
  static const String instagramStory = 'instagram_story';
}

/// Holds aggregated analytics for a single event.
@immutable
class EventShareStats {
  final String eventId;
  final String category;
  final int totalShares;
  final Map<String, int> byMethod;

  const EventShareStats({
    required this.eventId,
    required this.category,
    required this.totalShares,
    required this.byMethod,
  });
}

/// In-memory tracker for share events.
///
/// Records every share call during the session; wire the [recordShare] method
/// to a real analytics backend (Firebase Analytics, Amplitude, etc.) by
/// replacing or extending the [_sendToBackend] stub below.
class ShareAnalyticsService {
  // eventId → { method → count }
  final Map<String, Map<String, int>> _counts = {};
  // eventId → category (cached for reporting)
  final Map<String, String> _categories = {};

  /// Record a share action.
  ///
  /// [method] should be one of the [ShareMethod] constants.
  void recordShare({
    required String eventId,
    required String category,
    required String method,
  }) {
    _categories[eventId] = category;
    final methods = _counts.putIfAbsent(eventId, () => {});
    methods[method] = (methods[method] ?? 0) + 1;
    _sendToBackend(eventId: eventId, category: category, method: method);
  }

  /// Returns share stats for a specific event, or null if never shared.
  EventShareStats? statsFor(String eventId) {
    final methods = _counts[eventId];
    if (methods == null) return null;
    return EventShareStats(
      eventId: eventId,
      category: _categories[eventId] ?? '',
      totalShares: methods.values.fold(0, (a, b) => a + b),
      byMethod: Map.unmodifiable(methods),
    );
  }

  /// Total shares recorded across all events this session.
  int get totalShares =>
      _counts.values.fold(0, (sum, m) => sum + m.values.fold(0, (a, b) => a + b));

  /// Returns stats for all events that have been shared, sorted by total desc.
  List<EventShareStats> get allStats {
    return _counts.entries
        .map((e) => EventShareStats(
              eventId: e.key,
              category: _categories[e.key] ?? '',
              totalShares: e.value.values.fold(0, (a, b) => a + b),
              byMethod: Map.unmodifiable(e.value),
            ))
        .toList()
      ..sort((a, b) => b.totalShares.compareTo(a.totalShares));
  }

  // ── Stub: replace with a real analytics call ──────────────────────────────
  // ignore: unused_element
  void _sendToBackend({
    required String eventId,
    required String category,
    required String method,
  }) {
    // Example Firebase Analytics call (uncomment when wired):
    // FirebaseAnalytics.instance.logEvent(
    //   name: 'event_shared',
    //   parameters: {
    //     'event_id': eventId,
    //     'event_category': category,
    //     'share_method': method,
    //   },
    // );
  }
}
