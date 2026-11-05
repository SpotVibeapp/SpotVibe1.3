import 'package:flutter_test/flutter_test.dart';
import 'package:spotvibe_app/data/rules_compat.dart';

class _Coded implements Exception {
  _Coded(this.code);
  final String code;
}

void main() {
  test('profile creates try a blank email before a real one', () {
    final attempts = profileCreateAttempts(
      publicFields: {'name': 'Ana', 'avatarUrl': 'a', 'email': 'nope'},
      email: 'ana@example.com',
    );
    expect(attempts[0]['email'], '');
    expect(attempts[0].containsKey('phone'), isFalse);
    expect(attempts[1].containsKey('email'), isFalse);
    expect(attempts[2]['email'], 'ana@example.com');
    expect(attempts[2]['name'], 'Ana');
  });

  test('legacy public email is omitted when the compat flag is off or email is blank', () {
    final off = profileCreateAttempts(
      publicFields: {'name': 'Ana', 'avatarUrl': 'a'},
      email: 'ana@example.com',
      allowLegacyPublicEmail: false,
    );
    expect(off, hasLength(2));
    expect(off.every((body) => body['email'] != 'ana@example.com'), isTrue);

    final blank = profileCreateAttempts(
      publicFields: {'name': 'Ana', 'avatarUrl': 'a'},
      email: '  ',
    );
    expect(blank, hasLength(2));
  });

  test('only a permission denial tries the next shape', () async {
    final seen = <String>[];
    await writeFirstAllowed(
      [
        {'shape': 'strict'},
        {'shape': 'legacy'},
      ],
      (body) async {
        seen.add(body['shape'] as String);
        if (body['shape'] == 'strict') throw _Coded('permission-denied');
      },
    );
    expect(seen, ['strict', 'legacy']);
  });

  test('a non-permission error does not fall through to the legacy shape', () async {
    final seen = <String>[];
    await expectLater(
      writeFirstAllowed(
        [
          {'shape': 'strict'},
          {'shape': 'legacy'},
        ],
        (body) async {
          seen.add(body['shape'] as String);
          throw _Coded('unavailable');
        },
      ),
      throwsA(isA<_Coded>()),
    );
    expect(seen, ['strict']);
  });
}
