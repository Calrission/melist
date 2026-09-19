// expectNotAllowedMethods is marked @experimental in dart_frog_test.
// ignore_for_file: experimental_member_use

import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_test/dart_frog_test.dart';
import 'package:melist_backend/melist_backend.dart';
import 'package:test/test.dart';

import '../../../routes/auth/debug.dart' as route;

void main() {
  TestRequestContext contextFor(
    HttpMethod method, {
    required DebugAuth debug,
  }) {
    return TestRequestContext(
      path: '/auth/debug',
      method: method,
    )..provide<DebugAuth>(debug);
  }

  group('GET /auth/debug', () {
    test('rejects unsupported methods with 405', () async {
      await expectNotAllowedMethods(
        route.onRequest,
        contextBuilder: (method) => contextFor(
          method,
          debug: const DebugAuth.enabled(),
        ),
        allowedMethods: [HttpMethod.get],
      );
    });

    test('returns 404 when debug auth is disabled', () async {
      final response = await route.onRequest(
        contextFor(HttpMethod.get, debug: const DebugAuth.disabled()).context,
      );

      expect(response, isNotFound);
      expectJsonBody(response, {'error': 'Debug auth is disabled'});
    });

    test('returns the fixed Bearer token when enabled', () async {
      final response = await route.onRequest(
        contextFor(HttpMethod.get, debug: const DebugAuth.enabled()).context,
      );

      expect(response, isOk);
      expectJsonBody(response, {
        'accessToken': DebugAuth.defaultToken,
        'tokenType': 'Bearer',
        'user': {
          'id': DebugAuth.defaultUserId,
          'firstName': DebugAuth.defaultFirstName,
          'lastName': DebugAuth.defaultLastName,
          'username': DebugAuth.defaultUsername,
        },
      });
    });
  });
}
