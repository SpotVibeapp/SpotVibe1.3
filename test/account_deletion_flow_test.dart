import 'package:flutter_test/flutter_test.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:spotvibe_app/services/account_deletion_flow.dart';
import 'package:spotvibe_app/services/apple_reauth.dart';

/// Records which deletion steps ran, in order.
class _Harness {
  final calls = <String>[];
  String? revokedCode;
  AppleDeletionAuthorization? reauthWith;

  AccountDeletionFlow build({
    required List<String> providers,
    bool appleSupported = true,
    bool withPassword = false,
    Object? appleError,
    Object? revokeError,
    Object? purgeError,
    String? identityToken = 'id-token',
  }) {
    return AccountDeletionFlow(
      providerIds: providers,
      appleAuthorizationSupported: appleSupported,
      reauthenticateWithPassword: withPassword
          ? () async => calls.add('passwordReauth')
          : null,
      requestAppleAuthorization: () async {
        calls.add('appleSheet');
        if (appleError != null) throw appleError;
        return AppleDeletionAuthorization(
          authorizationCode: 'auth-code',
          identityToken: identityToken,
          rawNonce: 'nonce',
        );
      },
      reauthenticateWithApple: (auth) async {
        calls.add('appleReauth');
        reauthWith = auth;
      },
      revokeAppleToken: (code) async {
        calls.add('revoke');
        if (revokeError != null) throw revokeError;
        revokedCode = code;
      },
      purgeUserData: () async {
        calls.add('purge');
        if (purgeError != null) throw purgeError;
      },
      deleteAuthUser: () async => calls.add('deleteUser'),
    );
  }
}

void main() {
  late _Harness h;
  setUp(() => h = _Harness());

  group('Apple account deletion', () {
    test('re-authorizes, revokes, then purges and deletes in order', () async {
      final result = await h.build(providers: ['apple.com']).run();

      expect(h.calls,
          ['appleSheet', 'appleReauth', 'revoke', 'purge', 'deleteUser']);
      expect(h.revokedCode, 'auth-code');
      expect(h.reauthWith!.rawNonce, 'nonce');
      expect(result.isAppleAccount, isTrue);
      expect(result.appleTokenRevoked, isTrue);
    });

    test('cancelling the Apple sheet aborts before anything is deleted',
        () async {
      final flow = h.build(
        providers: ['apple.com'],
        appleError: appleAuthorizationError(AuthorizationErrorCode.canceled),
      );

      await expectLater(flow.run(), throwsA(isA<AccountDeletionCancelled>()));
      expect(h.calls, ['appleSheet']);
    });

    test('cancel message is clear and UI-ready', () {
      final e = appleAuthorizationError(AuthorizationErrorCode.canceled);
      expect(e, isA<AccountDeletionCancelled>());
      final shown = e.toString().replaceFirst('Exception: ', '');
      expect(shown, startsWith('Account deletion cancelled.'));
    });

    test('other Apple failures abort with a retry message', () async {
      final err = appleAuthorizationError(AuthorizationErrorCode.failed);
      expect(err, isNot(isA<AccountDeletionCancelled>()));
      expect(err.toString(), contains('not deleted'));

      final flow = h.build(providers: ['apple.com'], appleError: err);
      await expectLater(flow.run(), throwsA(isA<Exception>()));
      expect(h.calls, ['appleSheet']);
    });

    test('revocation failure is logged and deletion still completes',
        () async {
      final result = await h
          .build(providers: ['apple.com'], revokeError: Exception('network'))
          .run();

      expect(h.calls,
          ['appleSheet', 'appleReauth', 'revoke', 'purge', 'deleteUser']);
      expect(result.appleTokenRevoked, isFalse);
      expect(result.revocationError, isNotNull);
    });

    test('missing identity token skips re-auth but still revokes', () async {
      await h.build(providers: ['apple.com'], identityToken: null).run();
      expect(h.calls, ['appleSheet', 'revoke', 'purge', 'deleteUser']);
    });

    test('platform without native Apple sign-in still deletes', () async {
      final result =
          await h.build(providers: ['apple.com'], appleSupported: false).run();
      expect(h.calls, ['purge', 'deleteUser']);
      expect(result.appleTokenRevoked, isFalse);
    });

    test('Apple account linked with a password does both re-auths', () async {
      await h
          .build(providers: ['password', 'apple.com'], withPassword: true)
          .run();
      expect(h.calls, [
        'passwordReauth',
        'appleSheet',
        'appleReauth',
        'revoke',
        'purge',
        'deleteUser',
      ]);
    });
  });

  group('non-Apple account deletion is unchanged', () {
    test('email/password: password re-auth, purge, delete', () async {
      final result =
          await h.build(providers: ['password'], withPassword: true).run();
      expect(h.calls, ['passwordReauth', 'purge', 'deleteUser']);
      expect(result.isAppleAccount, isFalse);
      expect(result.appleTokenRevoked, isFalse);
    });

    test('Google: never shows the Apple sheet or revokes', () async {
      await h.build(providers: ['google.com']).run();
      expect(h.calls, ['purge', 'deleteUser']);
    });

    test('a failed Firestore purge does not block auth deletion', () async {
      await h
          .build(providers: ['google.com'], purgeError: Exception('rules'))
          .run();
      expect(h.calls, ['purge', 'deleteUser']);
    });
  });
}
