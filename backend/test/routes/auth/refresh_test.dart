import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:melist_backend/melist_backend.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../../../routes/auth/refresh.dart' as route;
import '../../helpers/init_data.dart';

class _MockRequestContext extends Mock implements RequestContext {}

void main() {
  final now = DateTime.utc(2026, 9, 19, 8, 13);
  final validator = InitDataValidator(
    botToken: testBotToken,
    clock: () => now,
  );
  const jwtService = JwtService(secret: 'test-secret');

  RequestContext contextWith(Request request) {
    final context = _MockRequestContext();
    when(() => context.request).thenReturn(request);
    when(() => context.read<InitDataValidator>()).thenReturn(validator);
    when(() => context.read<JwtService>()).thenReturn(jwtService);
    return context;
  }

  group('POST /auth/refresh', () {
    test('responds with 400 when initData is missing', () async {
      final context = contextWith(
        Request.post(
          Uri.parse('http://localhost/auth/refresh'),
          headers: {HttpHeaders.contentTypeHeader: 'application/json'},
          body: jsonEncode(<String, dynamic>{}),
        ),
      );

      final response = await route.onRequest(context);

      expect(response.statusCode, equals(HttpStatus.badRequest));
    });

    test('issues a new JWT when initData is still valid', () async {
      final context = contextWith(
        Request.post(
          Uri.parse('http://localhost/auth/refresh'),
          headers: {HttpHeaders.contentTypeHeader: 'application/json'},
          body: jsonEncode({
            'initData': signInitData(authDate: unixSeconds(now)),
          }),
        ),
      );

      final response = await route.onRequest(context);
      final body = jsonDecode(await response.body()) as Map<String, dynamic>;
      final jwt = jwtService.verify(body['accessToken'] as String);

      expect(response.statusCode, equals(HttpStatus.ok));
      expect(jwt.subject, equals('279058397'));
    });
  });
}
