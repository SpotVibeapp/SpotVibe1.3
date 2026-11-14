import 'package:flutter_test/flutter_test.dart';
import 'package:spotvibe_app/data/pii_mask.dart';

void main() {
  test('masks emails, phones, handles and social URLs', () {
    const input =
        'Bring snacks. Email maya@test.com or call (915) 555-0100, or @maya / https://instagram.com/maya';
    final out = maskContactInfo(input);
    expect(out, isNot(contains('maya@test.com')));
    expect(out, isNot(contains('555-0100')));
    expect(out, isNot(contains('@maya')));
    expect(out, isNot(contains('instagram.com')));
    expect(out, contains('Bring snacks.'));
    expect(containsContactInfo('Just a game night at Maya\'s'), isFalse);
    expect(containsContactInfo('DM me @maya'), isTrue);
  });
}
