import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:melist_backend/melist_backend.dart';
import 'package:melist_core/melist_core.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../../../routes/auth/logout.dart' as route;
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
  const user = UserModel(id: 1, firstName: 'Ann');

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

  group('POST /auth/logout', () {
    test('responds with 405 when the method is not POST', () async {
      final response = await route.onRequest(
        contextWith(Request.get(Uri.parse('http://localhost/auth/logout'))),
      );

      expect(response.statusCode, equals(HttpStatus.methodNotAllowed));
    });

    test('responds with 204 and clears the cookie without a session', () async {
      final response = await route.onRequest(
        contextWith(Request.post(Uri.parse('http://localhost/auth/logout'))),
      );

      expect(response.statusCode, equals(HttpStatus.noContent));
      expect(
        response.headers[HttpHeaders.setCookieHeader],
        contains('Max-Age=0'),
      );
    });

    test('revokes the current refresh token', () async {
      await users.upsertTelegram(user);
      final issued = await sessions.issue(user);

      final response = await route.onRequest(
        contextWith(
          Request.post(
            Uri.parse('http://localhost/auth/logout'),
            headers: {
              HttpHeaders.cookieHeader:
                  '${RefreshCookie.name}=${issued.refreshToken}',
            },
          ),
        ),
      );

      expect(response.statusCode, equals(HttpStatus.noContent));
      expect(tokens.rows.single.isRevoked, isTrue);
      expect(
        response.headers[HttpHeaders.setCookieHeader],
        contains('Max-Age=0'),
      );
    });
  });
}
