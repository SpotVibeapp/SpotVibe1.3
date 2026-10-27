import 'package:flutter_test/flutter_test.dart';
import 'package:spotvibe_app/services/admob_ids.dart';
import 'package:spotvibe_app/services/ads_service.dart';

void main() {
  group('admobReleaseIdProblem', () {
    test("Google's sample ids are rejected", () {
      expect(
        admobReleaseIdProblem(
            'ca-app-pub-3940256099942544~3347511713', AdMobIdKind.app),
        isNotNull,
      );
      expect(
        admobReleaseIdProblem(
            'ca-app-pub-3940256099942544/6300978111', AdMobIdKind.adUnit),
        isNotNull,
      );
    });

    test('blank and template placeholders are rejected', () {
      expect(admobReleaseIdProblem('', AdMobIdKind.app), isNotNull);
      expect(
        admobReleaseIdProblem(
            'ca-app-pub-XXXXXXXXXXXXXXXX~YYYYYYYYYY', AdMobIdKind.app),
        isNotNull,
      );
      expect(
        admobReleaseIdProblem(
            'ca-app-pub-XXXXXXXX/ZZZZZZZZ', AdMobIdKind.adUnit),
        isNotNull,
      );
    });

    test('app id and ad unit id are not interchangeable', () {
      expect(
        admobReleaseIdProblem(
            'ca-app-pub-1234567890123456/1234567890', AdMobIdKind.app),
        isNotNull,
      );
      expect(
        admobReleaseIdProblem(
            'ca-app-pub-1234567890123456~1234567890', AdMobIdKind.adUnit),
        isNotNull,
      );
    });

    test('real-looking ids pass', () {
      expect(
        admobReleaseIdProblem(
            'ca-app-pub-1234567890123456~1234567890', AdMobIdKind.app),
        isNull,
      );
      expect(
        admobReleaseIdProblem(
            ' ca-app-pub-1234567890123456/1234567890 ', AdMobIdKind.adUnit),
        isNull,
      );
    });
  });

  group('AdsService.bannerAllowedFor', () {
    const testUnit = 'ca-app-pub-3940256099942544/6300978111';
    const realUnit = 'ca-app-pub-1234567890123456/1234567890';

    test('debug builds keep Google test ads', () {
      expect(AdsService.bannerAllowedFor(testUnit, releaseMode: false), isTrue);
    });

    test('release builds never request a test or placeholder unit', () {
      expect(AdsService.bannerAllowedFor(testUnit, releaseMode: true), isFalse);
      expect(AdsService.bannerAllowedFor('', releaseMode: true), isFalse);
      expect(AdsService.bannerAllowedFor(realUnit, releaseMode: true), isTrue);
    });
  });
}
