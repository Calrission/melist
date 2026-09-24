import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:melist_backend/melist_backend.dart';
import 'package:melist_core/melist_core.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../../../routes/auth/refresh.dart' as route;
import '../../helpers/memory_refresh_tokens.dart';
import '../../helpers/memory_wishlists.dart';

class _MockRequestContext extends Mock implements RequestContext {}

void main() {
  const jwtService = JwtService(secret: 'test-secret');
  const config = AppConfig(
    botToken: 'token',
    jwtSecret: 'test-secret',
    databaseUrl: 'postgres://melist@localhost/melist',
  );
  const user = UserModel(
    id: 279058397,
    firstName: 'Vladislav',
    username: 'vdkfrost',
  );

  late MemoryUserRepository users;
  late MemoryRefreshTokenRepository tokens;
  late AuthSessionService sessions;

  RequestContext contextWith(Request request) {
    final context = _MockRequestContext();
    when(() => context.request).thenReturn(request);
    when(() => context.read<AuthSessionService>()).thenReturn(sessions);
    when(() => context.read<AppConfig>()).thenReturn(config);
    return context;
  }

  setUp(() {
    users = MemoryUserRepository(MemoryWishlistData());
    tokens = MemoryRefreshTokenRepository();
    sessions = memoryAuthSessionService(
      jwtService: jwtService,
      users: users,
      tokens: tokens,
    );
  });

  group('POST /auth/refresh', () {
    test('responds with 405 when the method is not POST', () async {
      final response = await route.onRequest(
        contextWith(Request.get(Uri.parse('http://localhost/auth/refresh'))),
      );

      expect(response.statusCode, equals(HttpStatus.methodNotAllowed));
    });

    test('responds with 401 when the cookie is missing', () async {
      final response = await route.onRequest(
        contextWith(Request.post(Uri.parse('http://localhost/auth/refresh'))),
      );
      final body = jsonDecode(await response.body()) as Map<String, dynamic>;

      expect(response.statusCode, equals(HttpStatus.unauthorized));
      expect(body['error'], equals('Invalid refresh token'));
      expect(
        response.headers[HttpHeaders.setCookieHeader],
        contains('Max-Age=0'),
      );
    });

    test('rotates the cookie and returns a new access token', () async {
      await users.upsertTelegram(user);
      final issued = await sessions.issue(user);

      final response = await route.onRequest(
        contextWith(
          Request.post(
            Uri.parse('http://localhost/auth/refresh'),
            headers: {
              HttpHeaders.cookieHeader:
                  '${RefreshCookie.name}=${issued.refreshToken}',
            },
          ),
        ),
      );
      final body = jsonDecode(await response.body()) as Map<String, dynamic>;
      final cookie = response.headers[HttpHeaders.setCookieHeader]!;

      expect(response.statusCode, equals(HttpStatus.ok));
      expect(body.containsKey('refreshToken'), isFalse);
      expect(
        jwtService.verify(body['accessToken'] as String).subject,
        '279058397',
      );
      expect(cookie, contains('refresh_token='));
      expect(cookie, isNot(contains(issued.refreshToken)));
      expect(tokens.rows.first.isRevoked, isTrue);
    });

    test('responds with 401 when the cookie is reused', () async {
      await users.upsertTelegram(user);
      final issued = await sessions.issue(user);
      await sessions.rotate(issued.refreshToken);

      final response = await route.onRequest(
        contextWith(
          Request.post(
            Uri.parse('http://localhost/auth/refresh'),
            headers: {
              HttpHeaders.cookieHeader:
                  '${RefreshCookie.name}=${issued.refreshToken}',
            },
          ),
        ),
      );

      expect(response.statusCode, equals(HttpStatus.unauthorized));
      expect(tokens.rows.every((row) => row.isRevoked), isTrue);
    });
  });
}
