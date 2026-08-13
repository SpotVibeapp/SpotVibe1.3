import 'package:flutter_test/flutter_test.dart';
import 'package:spotvibe_app/repositories/rsvp_repository.dart';

void main() {
  test('mock RSVPs and comments start empty', () async {
    final repo = MockRsvpRepository();
    expect(await repo.getRsvps('evt_ep_001'), isEmpty);
    expect(await repo.getComments('evt_ep_001'), isEmpty);
  });

  test('a real RSVP is the only attendee', () async {
    final repo = MockRsvpRepository();
    await repo.addRsvp(
      eventId: 'evt_ep_001',
      userId: 'user_1',
      userName: 'Pat',
      avatarUrl: '',
      isPrivate: false,
    );
    final rsvps = await repo.getRsvps('evt_ep_001');
    expect(rsvps, hasLength(1));
    expect(rsvps.single.userName, 'Pat');
    expect(rsvps.any((r) => r.userName == 'Alex Rivera'), isFalse);
  });
}
