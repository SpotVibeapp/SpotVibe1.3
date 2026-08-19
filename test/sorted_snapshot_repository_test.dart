import 'package:flutter_test/flutter_test.dart';
import 'package:spotvibe_app/repositories/notification_repository.dart';
import 'package:spotvibe_app/repositories/user_event_repository.dart';

void main() {
  test('notification repository returns a newest-first sorted snapshot', () {
    final notifications = NotificationRepository().getAll();

    expect(notifications, isNotEmpty);
    for (var index = 1; index < notifications.length; index++) {
      expect(
        notifications[index - 1].createdAt.compareTo(notifications[index].createdAt),
        greaterThanOrEqualTo(0),
      );
    }
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
