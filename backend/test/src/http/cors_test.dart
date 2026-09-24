import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:melist_backend/melist_backend.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _MockRequestContext extends Mock implements RequestContext {}

void main() {
  const listed = AppConfig(
    botToken: 'token',
    jwtSecret: 'secret',
    databaseUrl: 'postgres://melist@localhost/melist',
    corsOrigins: [
      'http://localhost:8081',
      'https://*.ngrok-free.dev',
    ],
  );
  const open = AppConfig(
    botToken: 'token',
    jwtSecret: 'secret',
    databaseUrl: 'postgres://melist@localhost/melist',
  );

  group('originIsAllowed', () {
    test('allows an exact listed origin', () {
      expect(originIsAllowed('http://localhost:8081', listed), isTrue);
    });

    test('allows a single-label ngrok wildcard', () {
      expect(
        originIsAllowed(
          'https://unworn-unshaved-cryptic.ngrok-free.dev',
          listed,
        ),
        isTrue,
      );
    });

    test('rejects a different origin', () {
      expect(originIsAllowed('https://evil.example', listed), isFalse);
    });

    test('rejects extra subdomain labels', () {
      expect(
        originIsAllowed('https://a.b.ngrok-free.dev', listed),
        isFalse,
      );
    });

    test('allows any origin when the allowlist is empty', () {
      expect(originIsAllowed('https://anywhere.example', open), isTrue);
    });
  });

  group('applyCors', () {
    test('answers OPTIONS preflight for an allowed ngrok origin', () async {
      final response = await applyCors(_notAllowed)(
        _context(
          config: listed,
          origin: 'https://unworn-unshaved-cryptic.ngrok-free.dev',
        ),
      );

      expect(response.statusCode, equals(HttpStatus.noContent));
      expect(
        response.headers['access-control-allow-origin'],
        equals('https://unworn-unshaved-cryptic.ngrok-free.dev'),
      );
      expect(response.headers['access-control-allow-credentials'], 'true');
    });

    test('answers OPTIONS without ACAO for an unknown origin', () async {
      final response = await applyCors(_notAllowed)(
        _context(config: listed, origin: 'https://evil.example'),
      );

      expect(response.statusCode, equals(HttpStatus.noContent));
      expect(response.headers['access-control-allow-origin'], isNull);
    });
  });
}

Future<Response> _notAllowed(RequestContext context) async {
  return Response(statusCode: HttpStatus.methodNotAllowed);
}

RequestContext _context({
  required AppConfig config,
  required String origin,
}) {
  final context = _MockRequestContext();
  when(() => context.request).thenReturn(
    Request(
      'OPTIONS',
      Uri.parse('http://localhost/auth/refresh'),
      headers: {
        'origin': origin,
        'access-control-request-method': 'POST',
        'access-control-request-headers': 'content-type',
      },
    ),
  );
  when(() => context.read<AppConfig>()).thenReturn(config);
  return context;
}
