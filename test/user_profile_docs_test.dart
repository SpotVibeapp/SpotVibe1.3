import 'package:flutter_test/flutter_test.dart';
import 'package:spotvibe_app/repositories/user_profile_docs.dart';

void main() {
  group('planProfileSync', () {
    test('first sign-in creates a public doc without any private field', () {
      final plan = planProfileSync(
        publicData: null,
        privateData: null,
        name: 'Ana',
        email: 'ana@example.com',
        avatarUrl: 'https://img/ana.png',
        provider: 'google',
      );
      expect(plan.createPublic, isTrue);
      expect(plan.publicFields, {
        'name': 'Ana',
        'avatarUrl': 'https://img/ana.png',
        'provider': 'google',
      });
      for (final field in kPrivateProfileFields) {
        expect(plan.publicFields.containsKey(field), isFalse);
      }
      expect(plan.privateFields, {'email': 'ana@example.com'});
    });

    test('Apple with no email writes nothing private and invents nothing', () {
      final plan = planProfileSync(
        publicData: null,
        privateData: null,
        name: 'User',
        email: '',
        avatarUrl: 'a',
        provider: 'apple',
      );
      expect(plan.privateFields, isEmpty);
      expect(plan.publicFields.containsKey('email'), isFalse);
    });

    test('a blank email never overwrites a stored private email', () {
      final plan = planProfileSync(
        publicData: {'name': 'Ana', 'avatarUrl': 'a'},
        privateData: {'email': 'relay@privaterelay.appleid.com'},
        name: 'Ana',
        email: '',
        avatarUrl: 'a',
      );
      expect(plan.privateFields, isEmpty);
      expect(plan.removeFromPublic, isEmpty);
      expect(plan.publicFields, isEmpty);
    });

    test('an unchanged email causes no private write', () {
      final plan = planProfileSync(
        publicData: {'name': 'Ana'},
        privateData: {'email': 'ana@example.com'},
        name: 'Ana',
        email: 'ana@example.com',
        avatarUrl: 'a',
      );
      expect(plan.privateFields, isEmpty);
    });

    test('a legacy public email is moved to the private doc', () {
      final plan = planProfileSync(
        publicData: {
          'name': 'Ana',
          'email': 'old@example.com',
          'phone': '+1 915 555 0100',
        },
        privateData: null,
        name: 'Ana',
        email: '',
        avatarUrl: 'a',
      );
      expect(plan.createPublic, isFalse);
      expect(plan.privateFields, {
        'email': 'old@example.com',
        'phone': '+1 915 555 0100',
      });
      expect(plan.removeFromPublic, unorderedEquals(['email', 'phone']));
    });

    test('a fresher provider email wins over the legacy public one', () {
      final plan = planProfileSync(
        publicData: {'name': 'Ana', 'email': 'old@example.com'},
        privateData: null,
        name: 'Ana',
        email: 'new@example.com',
        avatarUrl: 'a',
      );
      expect(plan.privateFields['email'], 'new@example.com');
      expect(plan.removeFromPublic, ['email']);
    });

    test('a blank legacy key is just removed', () {
      final plan = planProfileSync(
        publicData: {'name': 'Ana', 'email': ''},
        privateData: null,
        name: 'Ana',
        email: '',
        avatarUrl: 'a',
      );
      expect(plan.privateFields, isEmpty);
      expect(plan.removeFromPublic, ['email']);
    });

    test('a stored name is kept and a blank one is filled', () {
      final keep = planProfileSync(
        publicData: {'name': 'Ana'},
        privateData: null,
        name: 'Someone Else',
        email: '',
        avatarUrl: 'a',
      );
      expect(keep.publicFields.containsKey('name'), isFalse);
      final fill = planProfileSync(
        publicData: {'name': ' '},
        privateData: null,
        name: 'Ana',
        email: '',
        avatarUrl: 'a',
      );
      expect(fill.publicFields['name'], 'Ana');
    });
  });

  group('storedEmailFor', () {
    test('prefers the private doc, then a not-yet-migrated public value', () {
      expect(
        storedEmailFor(
          publicData: {'email': 'legacy@example.com'},
          privateData: {'email': 'private@example.com'},
        ),
        'private@example.com',
      );
      expect(
        storedEmailFor(publicData: {'email': 'legacy@example.com'}),
        'legacy@example.com',
      );
      expect(storedEmailFor(), '');
      expect(storedEmailFor(privateData: {'email': '  '}), '');
    });
  });
}
