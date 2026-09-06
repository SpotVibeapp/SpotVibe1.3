import 'package:flutter_test/flutter_test.dart';
import 'package:spotvibe_app/services/deep_link_service.dart';

void main() {
  group('DeepLinkService.pathFromUri', () {
    test('parses SpotVibe https event links on all known hosts', () {
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

  test('share links use the live Firebase Hosting domain by default', () {
    // The custom spotvibe.app domain is not connected yet — share links must
    // point at a host that actually serves a fallback page today.
    expect(kDeepLinkBase, 'https://spotvibe-cfa08.web.app');
    expect(DeepLinkService.eventLink('abc'),
        'https://spotvibe-cfa08.web.app/event/abc');
    expect(
      DeepLinkService.userEventLink('xyz'),
      'https://spotvibe-cfa08.web.app/user-event/xyz',
    );
  });
}
