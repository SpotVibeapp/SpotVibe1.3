import 'package:flutter_test/flutter_test.dart';
import 'package:spotvibe_app/models/notification_item.dart';
import 'package:spotvibe_app/repositories/notification_repository.dart';
import 'package:spotvibe_app/repositories/user_event_repository.dart';

void main() {
  test('notification inbox starts empty and sorts actual entries newest first', () {
    final repository = NotificationRepository();
    expect(repository.getAll(), isEmpty);

    repository.add(NotificationItem(
      id: 'older',
      type: NotificationType.newEvents,
      title: 'Older activity',
      subtitle: 'A real test notification',
      createdAt: DateTime(2026, 8, 18),
    ));
    repository.add(NotificationItem(
      id: 'newer',
      type: NotificationType.social,
      socialKind: SocialNotificationKind.comment,
      title: 'Newer activity',
      subtitle: 'A real test notification',
      createdAt: DateTime(2026, 8, 19),
    ));

    final notifications = repository.getAll();
    expect(notifications.map((item) => item.id), ['newer', 'older']);
  });

  test('user-event repository returns an earliest-first sorted snapshot', () async {
    final events = await UserEventRepository().getAllUserEvents();

    expect(events, isNotEmpty);
    for (var index = 1; index < events.length; index++) {
      expect(
        events[index - 1].dateTime.compareTo(events[index].dateTime),
        lessThanOrEqualTo(0),
      );
    }
  });
}
