// expectNotAllowedMethods is marked @experimental in dart_frog_test.
// ignore_for_file: experimental_member_use

import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_test/dart_frog_test.dart';
import 'package:melist_backend/melist_backend.dart';
import 'package:test/test.dart';

import '../../../../routes/api/wishlists/index.dart' as route;

void main() {
  const user = AuthUser(id: 1, username: 'melist_test');

  TestRequestContext contextFor(HttpMethod method) {
    return TestRequestContext(path: '/api/wishlists', method: method)
      ..provide<AuthUser>(user);
  }

  group('/api/wishlists', () {
    test('rejects unsupported methods with 405', () async {
      await expectNotAllowedMethods(
        route.onRequest,
        contextBuilder: contextFor,
        allowedMethods: [
          HttpMethod.get,
          HttpMethod.post,
          HttpMethod.patch,
          HttpMethod.delete,
        ],
      );
    });

    for (final method in [
      HttpMethod.get,
      HttpMethod.post,
      HttpMethod.patch,
      HttpMethod.delete,
    ]) {
      test('${method.name.toUpperCase()} responds with 501 (stub)', () async {
        final response = await route.onRequest(contextFor(method).context);

        expect(response, isNotImplemented);
        expectJsonBody(response, {'error': 'Not implemented'});
      });
    }
  });
}
