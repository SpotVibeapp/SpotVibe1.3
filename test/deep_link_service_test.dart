import 'package:flutter_test/flutter_test.dart';
import 'package:spotvibe_app/services/deep_link_service.dart';

void main() {
  group('DeepLinkService.pathFromUri', () {
    test('parses SpotVibe https event links', () {
      expect(
        DeepLinkService.pathFromUri('https://spotvibe.app/event/evt_1'),
        '/event/evt_1',
      );
      expect(
        DeepLinkService.pathFromUri('https://www.spotvibe.app/user-event/42'),
        '/user-event/42',
      );
    });

    test('parses spotvibe:// custom-scheme links', () {
      expect(
        DeepLinkService.pathFromUri('spotvibe://event/evt_1'),
        '/event/evt_1',
      );
    });

    test('still accepts legacy Vibely links', () {
      expect(
        DeepLinkService.pathFromUri('https://vibely.app/event/evt_1'),
        '/event/evt_1',
      );
      expect(
        DeepLinkService.pathFromUri('vibely://user-event/99'),
        '/user-event/99',
      );
    });

    test('rejects unknown hosts and paths', () {
      expect(DeepLinkService.pathFromUri('https://example.com/event/1'), isNull);
      expect(DeepLinkService.pathFromUri('https://spotvibe.app/about'), isNull);
      expect(DeepLinkService.pathFromUri('not a uri %%'), isNull);
    });
  });

  test('eventLink uses the SpotVibe domain', () {
    expect(kDeepLinkBase, 'https://spotvibe.app');
    expect(DeepLinkService.eventLink('abc'), 'https://spotvibe.app/event/abc');
    expect(
      DeepLinkService.userEventLink('xyz'),
      'https://spotvibe.app/user-event/xyz',
    );
  });
}
