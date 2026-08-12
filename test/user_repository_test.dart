import 'package:flutter_test/flutter_test.dart';
import 'package:spotvibe_app/repositories/mock_user_repository.dart';

void main() {
  late MockUserRepository repo;

  setUp(() {
    repo = MockUserRepository();
  });

  group('MockUserRepository session', () {
    test('no user before login', () async {
      expect(await repo.getCurrentUser(), isNull);
    });

    test('login sets the current user', () async {
      await repo.login('jane@example.com', 'password1');
      final user = await repo.getCurrentUser();
      expect(user, isNotNull);
      expect(user!.email, 'jane@example.com');
    });

    test('logout clears the session', () async {
      await repo.login('jane@example.com', 'password1');
      await repo.logout();
      expect(await repo.getCurrentUser(), isNull);
    });

    test('social login produces a stable provider-scoped id', () async {
      final first = await repo.loginWithSocial(
        provider: 'Google',
        name: 'Jane Doe',
        email: 'jane@example.com',
      );
      final second = await repo.loginWithSocial(
        provider: 'Google',
        name: 'Jane Doe',
        email: 'jane@example.com',
      );
      expect(first.id, second.id);
      expect(first.id, startsWith('google_'));
    });

    test('social login without avatar falls back to generated avatar URL',
        () async {
      final user = await repo.loginWithSocial(
        provider: 'apple',
        name: 'Jane Doe',
        email: 'jane@example.com',
        avatarUrl: null,
      );
      expect(user.avatarUrl, contains('ui-avatars.com'));
      expect(user.avatarUrl, contains('Jane%20Doe'));
    });
  });
}
