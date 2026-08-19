import 'package:flutter_test/flutter_test.dart';
import 'package:spotvibe_app/models/partner_promo_code.dart';
import 'package:spotvibe_app/repositories/partner_promo_repository.dart';

void main() {
  test('a stocked store code starts available and can be issued only once', () async {
    final repository = MockPartnerPromoRepository();
    final stocked = await repository.stockStoreCode(
      code: 'play-abc-123',
      platform: PartnerPromoPlatform.android,
      offerLabel: 'Partner Premium',
      durationLabel: '90-day free period',
      adminUid: 'admin_1',
    );

    expect(stocked.code, 'PLAY-ABC-123');
    expect(stocked.isAvailable, isTrue);

    final issued = await repository.issueCode(
      codeId: stocked.id,
      partnerName: 'Example Venue',
      partnerEmail: 'owner@examplevenue.com',
      adminUid: 'admin_1',
    );

    expect(issued.isIssued, isTrue);
    expect(issued.partnerName, 'Example Venue');
    await expectLater(
      repository.issueCode(
        codeId: stocked.id,
        partnerName: 'Another Venue',
        partnerEmail: '',
        adminUid: 'admin_1',
      ),
      throwsA(isA<StateError>()),
    );
  });

  test('an admin can revoke an unissued store code', () async {
    final repository = MockPartnerPromoRepository();
    final stocked = await repository.stockStoreCode(
      code: 'ios-xyz-789',
      platform: PartnerPromoPlatform.ios,
      offerLabel: 'Partner Premium',
      durationLabel: '30-day free period',
      adminUid: 'admin_1',
    );

    await repository.revokeCode(codeId: stocked.id, adminUid: 'admin_1');

    final code = (await repository.getCodes()).single;
    expect(code.isRevoked, isTrue);
  });
}
