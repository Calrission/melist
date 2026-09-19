import 'package:melist_backend/src/auth/auth_user.dart';
import 'package:melist_backend/src/config/app_config.dart';

/// Local-only bypass of Telegram `initData`. Off unless `DEBUG_AUTH=true`.
///
/// When enabled, `Authorization: Bearer <token>` is accepted as this user
/// without verifying a JWT. Never turn this on in production.
class DebugAuth {
  const DebugAuth.disabled()
    : enabled = false,
      token = defaultToken,
      user = defaultUser;

  const DebugAuth.enabled({
    this.token = defaultToken,
    this.user = defaultUser,
  }) : enabled = true;

  factory DebugAuth.fromConfig(AppConfig config) {
    if (!config.debugAuth) {
      return const DebugAuth.disabled();
    }
    final raw = config.debugToken?.trim();
    return DebugAuth.enabled(
      token: (raw == null || raw.isEmpty) ? defaultToken : raw,
      user: AuthUser(
        id: config.debugUserId,
        firstName: defaultFirstName,
        lastName: defaultLastName,
        username: defaultUsername,
      ),
    );
  }

  static const defaultToken = 'dev-admin';
  static const defaultUserId = 1;
  static const defaultUsername = 'debug_admin';
  static const defaultFirstName = 'Debug';
  static const defaultLastName = 'Admin';
  static const defaultUser = AuthUser(
    id: defaultUserId,
    firstName: defaultFirstName,
    lastName: defaultLastName,
    username: defaultUsername,
  );

  final bool enabled;
  final String token;
  final AuthUser user;

  /// Returns the debug user when [enabled] and [rawToken] matches [token].
  AuthUser? match(String rawToken) {
    if (!enabled || rawToken != token) {
      return null;
    }
    return user;
  }

  Map<String, Object?>? tokenPayload() {
    if (!enabled) {
      return null;
    }
    return {
      'accessToken': token,
      'tokenType': 'Bearer',
      'user': {
        'id': user.id,
        'firstName': user.firstName,
        'lastName': user.lastName,
        'username': user.username,
      },
    };
  }
}
