import 'package:flutter_test/flutter_test.dart';
import 'package:spotvibe_app/services/deep_link_service.dart';

void main() {
  group('DeepLinkService.pathFromUri', () {
    test('parses SpotVibe https event links on all known hosts', () {
      expect(
        DeepLinkService.pathFromUri(
            'https://spotvibeapp.com/app/event/evt_1'),
        '/event/evt_1',
      );
      expect(
        DeepLinkService.pathFromUri(
            'https://www.spotvibeapp.com/app/user-event/42'),
        '/user-event/42',
      );
      expect(
        DeepLinkService.pathFromUri('https://spotvibeapp.net/event/evt_1'),
        '/event/evt_1',
      );
      expect(
        DeepLinkService.pathFromUri('https://www.spotvibeapp.net/user-event/42'),
        '/user-event/42',
      );
      expect(
        DeepLinkService.pathFromUri(
            'https://spotvibe-cfa08.web.app/event/evt_1'),
        '/event/evt_1',
      );
      expect(
        DeepLinkService.pathFromUri(
            'https://spotvibe-cfa08.firebaseapp.com/user-event/42'),
        '/user-event/42',
      );
    });

    test('parses spotvibe:// custom-scheme links', () {
      expect(
        DeepLinkService.pathFromUri('spotvibe://event/evt_1'),
        '/event/evt_1',
      );
    });

    test('does not route legacy Vibely links', () {
      expect(
          DeepLinkService.pathFromUri('https://vibely.app/event/evt_1'), isNull);
      expect(DeepLinkService.pathFromUri('vibely://user-event/99'), isNull);
    });

    test('rejects unknown hosts and paths', () {
      expect(DeepLinkService.pathFromUri('https://example.com/event/1'), isNull);
      expect(
          DeepLinkService.pathFromUri('https://spotvibe.app/about'), isNull);
      expect(DeepLinkService.pathFromUri('not a uri %%'), isNull);
    });
  });

  test('invite text names the store title and is only a message, not a send', () {
    final message = DeepLinkService.inviteMessage();
    expect(message, contains('SpotVibe - Find Your Vibe'));
    expect(message, contains(kDeepLinkBase));
    expect(message.toLowerCase(), isNot(contains('mailto:')));
  });

  test('share links open the web app on spotvibeapp.com', () {
    expect(kDeepLinkBase, 'https://spotvibeapp.com/app');
    expect(DeepLinkService.eventLink('abc'),
        'https://spotvibeapp.com/app/event/abc');
    expect(
      DeepLinkService.userEventLink('xyz'),
      'https://spotvibeapp.com/app/user-event/xyz',
    );
  });
}
