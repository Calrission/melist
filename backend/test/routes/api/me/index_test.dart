// expectNotAllowedMethods is marked @experimental in dart_frog_test.
// ignore_for_file: experimental_member_use

import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_test/dart_frog_test.dart';
import 'package:melist_backend/melist_backend.dart';
import 'package:melist_backend/src/profiles/profile_handlers.dart';
import 'package:test/test.dart';

import '../../../helpers/memory_wishlists.dart';

void main() {
  const user = AuthUser(
    id: 1,
    firstName: 'Ann',
    username: 'ann',
  );

  late MemoryWishlistData data;
  late ProfileService profiles;

  TestRequestContext contextFor(
    HttpMethod method, {
    Map<String, Object?>? body,
  }) {
    return TestRequestContext(
        path: '/api/me',
        method: method,
        body: body == null ? null : jsonEncode(body),
        headers: body == null
            ? const {}
            : {HttpHeaders.contentTypeHeader: 'application/json'},
      )
      ..provide<AuthUser>(user)
      ..provide<ProfileService>(profiles);
  }

  setUp(() {
    data = MemoryWishlistData();
    profiles = memoryProfileService(data);
  });

  group('/api/me', () {
    test('rejects unsupported methods with 405', () async {
      await expectNotAllowedMethods(
        handleMe,
        // ignore: unnecessary_lambdas
        contextBuilder: (method) => contextFor(method),
        allowedMethods: [HttpMethod.get, HttpMethod.patch],
      );
    });

    test('GET returns the current profile', () async {
      final response = await handleMe(contextFor(HttpMethod.get).context);
      final body = jsonDecode(await response.body()) as Map<String, dynamic>;

      expect(response, isOk);
      expect(body['id'], 1);
      expect(body['firstName'], 'Ann');
      expect(body['username'], 'ann');
      expect(body['theme'], 'system');
      expect(body['birthday'], isNull);
    });

    test('PATCH updates birthday and theme', () async {
      final response = await handleMe(
        contextFor(
          HttpMethod.patch,
          body: {'birthday': '1990-05-12', 'theme': 'dark'},
        ).context,
      );
      final body = jsonDecode(await response.body()) as Map<String, dynamic>;

      expect(response, isOk);
      expect(body['birthday'], '1990-05-12');
      expect(body['theme'], 'dark');
    });

    test('PATCH returns 400 for invalid JSON and empty body', () async {
      final invalidContext =
          TestRequestContext(
              path: '/api/me',
              method: HttpMethod.patch,
              body: '[]',
              headers: {HttpHeaders.contentTypeHeader: 'application/json'},
            )
            ..provide<AuthUser>(user)
            ..provide<ProfileService>(profiles);
      final invalid = await handleMe(invalidContext.context);
      expect(invalid, isBadRequest);

      final empty = await handleMe(
        contextFor(HttpMethod.patch, body: {}).context,
      );
      expect(empty, isBadRequest);
    });
  });
}
