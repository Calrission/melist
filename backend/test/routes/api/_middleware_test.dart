import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:melist_backend/melist_backend.dart';
import 'package:melist_core/melist_core.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../../../routes/api/_middleware.dart';

class _MockRequestContext extends Mock implements RequestContext {}

void main() {
  const jwtService = JwtService(secret: 'test-secret');
  const user = UserModel(
    id: 279058397,
    firstName: 'Vladislav',
    lastName: 'Kibenko',
    username: 'vdkfrost',
  );

  setUpAll(() {
    registerFallbackValue(() => const AuthUser(id: 0));
  });

  RequestContext contextWith({String? authorization}) {
    final context = _MockRequestContext();
    final request = Request.get(
      Uri.parse('http://localhost/api/me'),
      headers: {
        if (authorization != null)
          HttpHeaders.authorizationHeader: authorization,
      },
    );

    when(() => context.request).thenReturn(request);
    when(() => context.read<JwtService>()).thenReturn(jwtService);
    when(() => context.read<DebugAuth>()).thenReturn(
      const DebugAuth.disabled(),
    );
    when(() => context.provide<AuthUser>(any())).thenReturn(context);
    return context;
  }

  Handler protectedHandler() {
    return middleware((_) => Response(body: 'ok'));
  }

  group('routes/api/_middleware', () {
    test('responds with 401 when Authorization header is missing', () async {
      final response = await protectedHandler()(contextWith());

      expect(response.statusCode, equals(HttpStatus.unauthorized));
    });

    test(
      'responds with 401 when the token is signed with another secret',
      () async {
        const otherService = JwtService(secret: 'other-secret');
        final token = otherService.issueAccessToken(user);

        final response = await protectedHandler()(
          contextWith(authorization: 'Bearer $token'),
        );

        expect(response.statusCode, equals(HttpStatus.unauthorized));
      },
    );

    test('responds with 401 when the token is malformed', () async {
      final response = await protectedHandler()(
        contextWith(authorization: 'Bearer not-a-jwt'),
      );

      expect(response.statusCode, equals(HttpStatus.unauthorized));
    });

    test(
      'passes the request and provides AuthUser for a valid token',
      () async {
        final token = jwtService.issueAccessToken(user);
        final context = contextWith(authorization: 'Bearer $token');

        final response = await protectedHandler()(context);

        expect(response.statusCode, equals(HttpStatus.ok));

        final captured = verify(
          () => context.provide<AuthUser>(captureAny()),
        ).captured;
        final provided = (captured.single as AuthUser Function())();

        expect(provided.id, equals(279058397));
        expect(provided.username, equals('vdkfrost'));
        expect(provided.firstName, equals('Vladislav'));
      },
    );

    test('accepts the debug token when DEBUG_AUTH is enabled', () async {
      const debug = DebugAuth.enabled();
      final context = contextWith(
        authorization: 'Bearer ${debug.token}',
      );
      when(() => context.read<DebugAuth>()).thenReturn(debug);

      final response = await protectedHandler()(context);

      expect(response.statusCode, equals(HttpStatus.ok));

      final captured = verify(
        () => context.provide<AuthUser>(captureAny()),
      ).captured;
      final provided = (captured.single as AuthUser Function())();

      expect(provided.id, equals(DebugAuth.defaultUserId));
      expect(provided.username, equals(DebugAuth.defaultUsername));
    });

    test('still accepts a signed JWT when debug auth is enabled', () async {
      final token = jwtService.issueAccessToken(user);
      final context = contextWith(authorization: 'Bearer $token');
      when(() => context.read<DebugAuth>()).thenReturn(
        const DebugAuth.enabled(),
      );

      final response = await protectedHandler()(context);

      expect(response.statusCode, equals(HttpStatus.ok));
    });

    test('rejects the default debug token when debug auth is off', () async {
      final response = await protectedHandler()(
        contextWith(authorization: 'Bearer ${DebugAuth.defaultToken}'),
      );

      expect(response.statusCode, equals(HttpStatus.unauthorized));
    });
  });
}
