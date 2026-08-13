import '../repositories/user_event_repository.dart';

/// Live counters for Premium analytics. Dedupes impressions and views
/// for the current app session so a feed refresh does not inflate numbers.
class EventAnalyticsService {
  EventAnalyticsService({required UserEventRepository repository})
      : _repository = repository;

  final UserEventRepository _repository;
  final Set<String> _impressed = {};
  final Set<String> _viewed = {};

  Future<void> recordImpression(String eventId) async {
    if (eventId.isEmpty || !_impressed.add(eventId)) return;
    await _repository.incrementAnalytics(eventId, impressions: 1);
  }

  Future<void> recordImpressions(Iterable<String> eventIds) async {
    for (final id in eventIds) {
      await recordImpression(id);
    }
  }

  Future<void> recordView(
    String eventId, {
    String? viewerId,
    String? creatorId,
  }) async {
    if (eventId.isEmpty) return;
    if (viewerId != null && creatorId != null && viewerId == creatorId) return;
    if (!_viewed.add(eventId)) return;
    await _repository.incrementAnalytics(eventId, views: 1);
  }

  Future<void> recordSave(String eventId) async {
    if (eventId.isEmpty) return;
    await _repository.incrementAnalytics(eventId, saves: 1);
  }

  Future<void> recordClick(String eventId) async {
    if (eventId.isEmpty) return;
    await _repository.incrementAnalytics(eventId, clicks: 1);
  }
}
