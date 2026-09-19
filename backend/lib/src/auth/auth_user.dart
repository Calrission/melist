import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';

/// Authenticated Telegram user restored from access JWT claims.
class AuthUser {
  const AuthUser({
    required this.id,
    this.firstName,
    this.lastName,
    this.username,
  });

  /// Builds a user from a verified JWT. Returns `null` when `sub` is missing
  /// or is not a Telegram user id.
  static AuthUser? fromJwt(JWT jwt) {
    final id = int.tryParse(jwt.subject ?? '');
    if (id == null) {
      return null;
    }

    final payload = jwt.payload;
    final claims = payload is Map ? payload : const <dynamic, dynamic>{};

    return AuthUser(
      id: id,
      firstName: claims['firstName'] as String?,
      lastName: claims['lastName'] as String?,
      username: claims['username'] as String?,
    );
  }

  final int id;
  final String? firstName;
  final String? lastName;
  final String? username;
}
