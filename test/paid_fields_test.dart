import 'package:flutter_test/flutter_test.dart';
import 'package:spotvibe_app/repositories/firebase_user_event_repository.dart';
import 'package:spotvibe_app/models/user_event.dart';
import 'package:spotvibe_app/repositories/founding_member_repository.dart';
import 'package:spotvibe_app/repositories/user_event_repository.dart';
import 'package:spotvibe_app/services/user_event_service.dart';

/// Records whether the service asked for the weekly feature, and what the
/// "server" answered.
class _FeatureSpyRepository extends UserEventRepository {
  _FeatureSpyRepository({this.grant});
  final String? grant;
  final List<String> requested = [];

  @override
  Future<String?> requestWeeklyFeature(String eventId, String creatorId) async {
    requested.add(eventId);
    return grant;
  }
}

Future<UserCreatedEvent> _create(
  UserEventService service, {
  required bool pro,
  String title = 'Open mic',
}) {
  final start = DateTime.now().add(const Duration(days: 2));
  return service.createEvent(
    creatorId: 'creator-1',
    title: title,
    description: 'Bring a song.',
    dateTime: start,
    endDateTime: start.add(const Duration(hours: 2)),
    location: 'Monarch',
    address: '204 Cincinnati',
    category: 'Music',
    organizerName: 'Monarch',
    isPremiumListing: false,
    isCreatorPro: pro,
  );
}

void main() {
  group('clientEventPayload', () {
    final full = <String, dynamic>{
      'title': 'Open mic',
      'creatorId': 'u1',
      'featuredWeekKey': '2026-W33',
      'featuredAt': 1,
      'analyticsViews': 9,
      'analyticsSearchImpressions': 9,
      'analyticsSaves': 9,
      'analyticsClicks': 9,
      'bookmarkedCount': 9,
      'interestedCount': 9,
    };

    test('never sends the paid featured fields', () {
      for (final isCreate in [true, false]) {
        final out = clientEventPayload(full, isCreate: isCreate);
        expect(out.containsKey('featuredWeekKey'), isFalse);
        expect(out.containsKey('featuredAt'), isFalse);
        expect(out['title'], 'Open mic');
      }
    });

    test('updates never overwrite live counters', () {
      final out = clientEventPayload(full, isCreate: false);
      for (final key in kEventCounterFields) {
        expect(out.containsKey(key), isFalse, reason: key);
      }
    });

    test('creates keep their (zero) counters for the rules check', () {
      final out = clientEventPayload(full, isCreate: true);
      expect(out['analyticsViews'], 9);
    });
  });

  test('analytics are one +1 write per counter', () {
    expect(analyticsIncrementFields(views: 1), ['analyticsViews']);
    expect(analyticsIncrementFields(impressions: 3), ['analyticsSearchImpressions']);
    expect(analyticsIncrementFields(), isEmpty);
    expect(
      analyticsIncrementFields(saves: 1, clicks: 1),
      ['analyticsSaves', 'analyticsClicks'],
    );
  });

  group('weekly featured slot is granted by the server only', () {
    test('a free creator never asks for it', () async {
      final repo = _FeatureSpyRepository(grant: '2026-W33');
      final event = await _create(UserEventService(repository: repo), pro: false);
      expect(repo.requested, isEmpty);
      expect(event.featuredWeekKey, isNull);
    });

    test('a Premium creator gets it only when the server grants it', () async {
      final granted = _FeatureSpyRepository(grant: '2026-W33');
      final event = await _create(UserEventService(repository: granted), pro: true);
      expect(granted.requested, [event.id]);
      expect(event.featuredWeekKey, '2026-W33');
      expect(event.isPremiumListing, isTrue);

      final denied = _FeatureSpyRepository(grant: null);
      final plain = await _create(UserEventService(repository: denied), pro: true);
      expect(plain.featuredWeekKey, isNull);
    });

    test('the event is created without a client-chosen featuredWeekKey', () async {
      final repo = UserEventRepository();
      final service = UserEventService(repository: repo);
      final first = await _create(service, pro: true, title: 'First');
      final second = await _create(service, pro: true, title: 'Second');
      // In-memory stand-in for the server: once per creator per week.
      expect(first.featuredWeekKey, isNotNull);
      expect(second.featuredWeekKey, isNull);
    });
  });

  test('founding callable result is parsed without trusting the client', () {
    final snap = foundingSnapshotFromCallable({
      'claimedCount': 7,
      'userIsMember': true,
      'verified': true,
    });
    expect(snap.claimedCount, 7);
    expect(snap.userIsMember, isTrue);
    final denied = foundingSnapshotFromCallable({'claimedCount': 25});
    expect(denied.userIsMember, isFalse);
    expect(denied.slotsOpen, isFalse);
  });
}
