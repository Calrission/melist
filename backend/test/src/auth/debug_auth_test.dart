import 'package:melist_backend/melist_backend.dart';
import 'package:test/test.dart';

void main() {
  group('DebugAuth', () {
    test('match returns null when disabled', () {
      const debug = DebugAuth.disabled();

      expect(debug.enabled, isFalse);
      expect(debug.match(DebugAuth.defaultToken), isNull);
    });

    test('match returns the debug user for the configured token', () {
      const debug = DebugAuth.enabled();

      expect(debug.match(debug.token), same(debug.user));
      expect(debug.match('other'), isNull);
    });

    test('fromConfig stays disabled unless DEBUG_AUTH is set', () {
      const config = AppConfig(
        botToken: 'bot',
        jwtSecret: 'jwt',
        databaseUrl: 'postgres://localhost/melist',
      );

      expect(DebugAuth.fromConfig(config).enabled, isFalse);
    });

    test('fromConfig uses defaults when token is omitted', () {
      const config = AppConfig(
        botToken: 'bot',
        jwtSecret: 'jwt',
        databaseUrl: 'postgres://localhost/melist',
        debugAuth: true,
      );
      final debug = DebugAuth.fromConfig(config);

      expect(debug.enabled, isTrue);
      expect(debug.token, DebugAuth.defaultToken);
      expect(debug.user.id, DebugAuth.defaultUserId);
      expect(debug.user.username, DebugAuth.defaultUsername);
    });

    test('fromConfig honours DEBUG_TOKEN and DEBUG_USER_ID', () {
      const config = AppConfig(
        botToken: 'bot',
        jwtSecret: 'jwt',
        databaseUrl: 'postgres://localhost/melist',
        debugAuth: true,
        debugToken: '  secret-token  ',
        debugUserId: 99,
      );
      final debug = DebugAuth.fromConfig(config);

      expect(debug.token, 'secret-token');
      expect(debug.user.id, 99);
    });

    test('tokenPayload is null when disabled', () {
      expect(const DebugAuth.disabled().tokenPayload(), isNull);
    });

    test('tokenPayload exposes the Bearer token', () {
      expect(
        const DebugAuth.enabled().tokenPayload(),
        equals({
          'accessToken': DebugAuth.defaultToken,
          'tokenType': 'Bearer',
          'user': {
            'id': 1,
            'firstName': 'Debug',
            'lastName': 'Admin',
            'username': 'debug_admin',
          },
        }),
      );
    });
  });
}
