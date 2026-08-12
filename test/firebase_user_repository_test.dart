import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spotvibe_app/repositories/firebase_user_repository.dart';

void main() {
  group('FirebaseUserRepository.messageForAuthException', () {
    String messageFor(String code) => FirebaseUserRepository
        .messageForAuthException(FirebaseAuthException(code: code));

    test('wrong credentials map to a single non-leaky message', () {
      // Never tell the user which of email/password was wrong, and never
      // reveal whether an account exists (prevents account enumeration).
      expect(messageFor('wrong-password'), 'Incorrect email or password.');
      expect(messageFor('user-not-found'), 'Incorrect email or password.');
      expect(messageFor('invalid-credential'), 'Incorrect email or password.');
    });

    test('email-already-in-use suggests logging in', () {
      expect(messageFor('email-already-in-use'), contains('already exists'));
    });

    test('invalid email is explained', () {
      expect(messageFor('invalid-email'), contains('not valid'));
    });

    test('rate limiting is explained', () {
      expect(messageFor('too-many-requests'), contains('Too many attempts'));
    });

    test('network failures are explained', () {
      expect(messageFor('network-request-failed'), contains('Network error'));
    });

    test('disabled sign-in method is explained', () {
      expect(messageFor('operation-not-allowed'), contains('not enabled'));
    });

    test('unknown codes fall back to the server message or generic text', () {
      final withMessage = FirebaseUserRepository.messageForAuthException(
        FirebaseAuthException(code: 'weird-new-code', message: 'Server says hi'),
      );
      expect(withMessage, 'Server says hi');

      final withoutMessage = FirebaseUserRepository.messageForAuthException(
        FirebaseAuthException(code: 'weird-new-code'),
      );
      expect(withoutMessage, 'Authentication failed. Please try again.');
    });
  });
}
