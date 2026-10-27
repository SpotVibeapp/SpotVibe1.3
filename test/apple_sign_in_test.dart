import 'package:flutter_test/flutter_test.dart';
import 'package:spotvibe_app/repositories/firebase_user_repository.dart';
import 'package:spotvibe_app/repositories/mock_user_repository.dart';
import 'package:spotvibe_app/services/apple_sign_in_profile.dart';

/// Regression tests for Sign in with Apple: the app must never invent an
/// email address (it used to fabricate `<userId>@privaterelay.appleid.com`
/// whenever Apple returned no email).
void main() {
  group('AppleSignInProfile', () {
    test('keeps the email Apple provides', () {
      final p = AppleSignInProfile.fromCredentialFields(
        email: 'jane@example.com',
        givenName: 'Jane',
        familyName: 'Doe',
        userIdentifier: '001234.abcd.5678',
      );
      expect(p.email, 'jane@example.com');
      expect(p.isPrivateRelayEmail, isFalse);
      expect(p.fullName, 'Jane Doe');
      expect(p.userIdentifier, '001234.abcd.5678');
    });

    test('keeps a real private relay email Apple provides', () {
      final p = AppleSignInProfile.fromCredentialFields(
        email: 'x7k2q9mm4p@privaterelay.appleid.com',
        givenName: 'Jane',
        familyName: null,
        userIdentifier: '001234.abcd.5678',
      );
      expect(p.email, 'x7k2q9mm4p@privaterelay.appleid.com');
      expect(p.isPrivateRelayEmail, isTrue);
      expect(p.fullName, 'Jane');
    });

    test('no email from Apple stays null (never fabricated)', () {
      final p = AppleSignInProfile.fromCredentialFields(
        email: null,
        givenName: null,
        familyName: null,
        userIdentifier: '001234.abcd.5678',
      );
      expect(p.email, isNull);
      expect(p.hasEmail, isFalse);
      expect(p.fullName, isNull);
      expect(p.userIdentifier, '001234.abcd.5678');
    });

    test('blank email and name parts are treated as missing', () {
      final p = AppleSignInProfile.fromCredentialFields(
        email: '   ',
        givenName: ' ',
        familyName: '',
        userIdentifier: 'id',
      );
      expect(p.email, isNull);
      expect(p.fullName, isNull);
    });
  });

  group('FirebaseUserRepository.resolveEmail', () {
    test('prefers the email the provider returned', () {
      expect(
        FirebaseUserRepository.resolveEmail(
          providerEmail: 'jane@example.com',
          authEmail: 'other@example.com',
        ),
        'jane@example.com',
      );
    });

    test('keeps a private relay email', () {
      expect(
        FirebaseUserRepository.resolveEmail(
          providerEmail: 'abc@privaterelay.appleid.com',
        ),
        'abc@privaterelay.appleid.com',
      );
    });

    test('falls back to the Firebase user email, then the stored one', () {
      expect(
        FirebaseUserRepository.resolveEmail(
          providerEmail: null,
          authEmail: 'fb@example.com',
          storedEmail: 'stored@example.com',
        ),
        'fb@example.com',
      );
      expect(
        FirebaseUserRepository.resolveEmail(storedEmail: 'stored@example.com'),
        'stored@example.com',
      );
    });

    test('no email anywhere yields empty string, never an invented one', () {
      final email = FirebaseUserRepository.resolveEmail(
        providerEmail: null,
        authEmail: null,
        storedEmail: '',
      );
      expect(email, isEmpty);
      expect(email, isNot(contains('privaterelay')));
    });
  });

  group('FirebaseUserRepository.resolveDisplayName', () {
    test('never replaces a known name with a blank one', () {
      expect(
        FirebaseUserRepository.resolveDisplayName(
          authDisplayName: '',
          storedName: 'Jane Doe',
          fallbackName: null,
        ),
        'Jane Doe',
      );
    });

    test('uses the provider name on first sign-in', () {
      expect(
        FirebaseUserRepository.resolveDisplayName(fallbackName: 'Jane Doe'),
        'Jane Doe',
      );
    });

    test('does not use a random relay local part as a name', () {
      expect(
        FirebaseUserRepository.resolveDisplayName(
          email: 'x7k2q9mm4p@privaterelay.appleid.com',
        ),
        'User',
      );
      expect(
        FirebaseUserRepository.resolveDisplayName(email: 'jane@example.com'),
        'jane',
      );
      expect(FirebaseUserRepository.resolveDisplayName(), 'User');
    });
  });

  group('Apple sign-in through MockUserRepository', () {
    late MockUserRepository repo;
    setUp(() => repo = MockUserRepository());

    test('email provided is used as-is', () async {
      final user = await repo.loginWithSocial(
        provider: 'apple',
        name: 'Jane Doe',
        email: 'jane@example.com',
        providerUserId: 'apple-1',
      );
      expect(user.email, 'jane@example.com');
      expect(user.displayName, 'Jane Doe');
    });

    test('private relay email provided is kept', () async {
      final user = await repo.loginWithSocial(
        provider: 'apple',
        name: 'Jane Doe',
        email: 'abc@privaterelay.appleid.com',
        providerUserId: 'apple-1',
      );
      expect(user.email, 'abc@privaterelay.appleid.com');
    });

    test('no email signs in with an empty email keyed by Apple id', () async {
      final user = await repo.loginWithSocial(
        provider: 'apple',
        name: null,
        email: null,
        providerUserId: 'apple-1',
      );
      expect(user.email, isEmpty);
      expect(user.id, startsWith('apple_'));
      expect(user.displayName, 'User');

      final other = await repo.loginWithSocial(
        provider: 'apple',
        email: null,
        providerUserId: 'apple-2',
      );
      expect(other.id, isNot(user.id));
    });

    test('later sign-in without name/email keeps first-sign-in values',
        () async {
      final first = await repo.loginWithSocial(
        provider: 'apple',
        name: 'Jane Doe',
        email: 'abc@privaterelay.appleid.com',
        providerUserId: 'apple-1',
      );
      await repo.logout();
      final second = await repo.loginWithSocial(
        provider: 'apple',
        name: null,
        email: null,
        providerUserId: 'apple-1',
      );
      expect(second.id, first.id);
      expect(second.displayName, 'Jane Doe');
      expect(second.email, 'abc@privaterelay.appleid.com');
    });
  });
}
