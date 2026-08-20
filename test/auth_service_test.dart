import 'package:flutter_test/flutter_test.dart';
import 'package:spotvibe_app/repositories/mock_user_repository.dart';
import 'package:spotvibe_app/services/auth_service.dart';

void main() {
  late AuthService authService;

  setUp(() {
    authService = AuthService(repository: MockUserRepository());
  });

  group('AuthService.login validation', () {
    test('rejects empty email', () {
      expect(
        () => authService.login('   ', 'password123'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects empty password', () {
      expect(
        () => authService.login('user@example.com', ''),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects email without @', () {
      expect(
        () => authService.login('not-an-email', 'password123'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects passwords shorter than 6 characters', () {
      expect(
        () => authService.login('user@example.com', '12345'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('passwords with leading/trailing spaces are NOT trimmed (regression)',
        () async {
      // "  1234  " is 8 chars raw; the old code trimmed it to 4 chars and
      // wrongly rejected it. Validation must use the raw password.
      final user = await authService.login('user@example.com', '  1234  ');
      expect(user.email, 'user@example.com');
    });

    test('successful login returns a user', () async {
      final user = await authService.login('jane.doe@example.com', 'secret1');
      expect(user.id, 'user_1');
      expect(user.email, 'jane.doe@example.com');
      expect(user.displayName, 'jane doe'); // dots replaced with spaces
    });
  });

  group('AuthService.password reset', () {
    test('rejects an empty reset email', () {
      expect(
        () => authService.sendPasswordResetEmail('   '),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('sends a reset request for a valid email', () async {
      await expectLater(
        authService.sendPasswordResetEmail('jane@example.com'),
        completes,
      );
    });
  });

  group('AuthService.register validation', () {
    test('rejects empty name', () {
      expect(
        () => authService.register('  ', 'a@b.com', 'password123'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects short password', () {
      expect(
        () => authService.register('Jane', 'a@b.com', '12345'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('successful registration returns a user with the given name',
        () async {
      final user = await authService.register('Jane', 'a@b.com', 'password1');
      expect(user.displayName, 'Jane');
      expect(user.email, 'a@b.com');
    });
  });
}
