/// Typed auth error so the UI can localize by [code].
///
/// [message] stays English for logs and unit tests.
class AuthFailure implements Exception {
  const AuthFailure(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => message;
}
