import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spotvibe_app/repositories/notification_preferences_repository.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('notification preferences default to enabled for a new install',
      () async {
    final repository = NotificationPreferencesRepository();

    expect(await repository.getEventReminders(), isTrue);
    expect(await repository.getWeeklyDigest(), isTrue);
    expect(await repository.getSocialComments(), isTrue);
    expect(await repository.getSocialFriendRsvp(), isTrue);
    expect(await repository.getSocialFriendRequests(), isTrue);
    expect(await repository.getCategoryEnabled('Music'), isTrue);
  });

  test('notification preferences persist independently', () async {
    final repository = NotificationPreferencesRepository();

    await repository.setEventReminders(false);
    await repository.setWeeklyDigest(false);
    await repository.setSocialComments(false);
    await repository.setSocialFriendRsvp(false);
    await repository.setSocialFriendRequests(false);
    await repository.setCategoryEnabled('Music', false);

    expect(await repository.getEventReminders(), isFalse);
    expect(await repository.getWeeklyDigest(), isFalse);
    expect(await repository.getSocialComments(), isFalse);
    expect(await repository.getSocialFriendRsvp(), isFalse);
    expect(await repository.getSocialFriendRequests(), isFalse);
    expect(await repository.getCategoryEnabled('Music'), isFalse);
    expect(await repository.getCategoryEnabled('Arts'), isTrue);
  });
}
