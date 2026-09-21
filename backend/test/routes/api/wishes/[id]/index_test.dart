// expectNotAllowedMethods is marked @experimental in dart_frog_test.
// ignore_for_file: experimental_member_use

import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_test/dart_frog_test.dart';
import 'package:melist_backend/melist_backend.dart';
import 'package:melist_backend/src/wishes/wish_handlers.dart';
import 'package:test/test.dart';

import '../../../../helpers/memory_wishes.dart';

void main() {
  const user = AuthUser(id: 1, username: 'melist_test');
  const stranger = AuthUser(id: 2, username: 'other');

  late MemoryWishData data;
  late WishService service;

  TestRequestContext contextFor(
    HttpMethod method, {
    AuthUser auth = user,
    Map<String, Object?>? body,
  }) {
    return TestRequestContext(
      path: '/api/wishes/1',
      method: method,
      body: body == null ? null : jsonEncode(body),
      headers: body == null
          ? const {}
          : {HttpHeaders.contentTypeHeader: 'application/json'},
    )
      ..provide<AuthUser>(auth)
      ..provide<WishService>(service);
  }

  setUp(() {
    data = MemoryWishData();
    service = memoryWishService(data);
  });

  group('/api/wishes/{id}', () {
    test('rejects unsupported methods with 405', () async {
      await expectNotAllowedMethods(
        (context) => handleWishById(context, '1'),
        // ignore: unnecessary_lambdas
        contextBuilder: (method) => contextFor(method),
        allowedMethods: [
          HttpMethod.get,
          HttpMethod.patch,
          HttpMethod.delete,
        ],
      );
    });

    test('GET returns the wish', () async {
      final created = await service.create(user, name: 'Headphones');

      final response = await handleWishById(
        contextFor(HttpMethod.get).context,
        '${created.id}',
      );
      final body = jsonDecode(await response.body()) as Map<String, dynamic>;

      expect(response, isOk);
      expect(body['name'], 'Headphones');
    });

    test('GET responds 403 for another user', () async {
      final created = await service.create(user, name: 'Headphones');

      final response = await handleWishById(
        contextFor(HttpMethod.get, auth: stranger).context,
        '${created.id}',
      );

      expect(response, isForbidden);
    });

    test('GET responds 400 for a non-numeric id', () async {
      final response = await handleWishById(
        contextFor(HttpMethod.get).context,
        'abc',
      );

      expect(response, isBadRequest);
    });

    test('PATCH updates status and visibility', () async {
      final created = await service.create(user, name: 'Old');

      final response = await handleWishById(
        contextFor(
          HttpMethod.patch,
          body: {
            'name': 'New',
            'visibility': 'private',
            'status': 'reserved',
          },
        ).context,
        '${created.id}',
      );
      final body = jsonDecode(await response.body()) as Map<String, dynamic>;

      expect(response, isOk);
      expect(body['name'], 'New');
      expect(body['visibility'], 'private');
      expect(body['status'], 'reserved');
    });

    test('DELETE removes the wish', () async {
      final created = await service.create(user, name: 'Old');

      final response = await handleWishById(
        contextFor(HttpMethod.delete).context,
        '${created.id}',
      );

      expect(response.statusCode, HttpStatus.noContent);
      expect(data.wishes.containsKey(created.id), isFalse);
    });

    test('DELETE responds 404 when missing', () async {
      final response = await handleWishById(
        contextFor(HttpMethod.delete).context,
        '99',
      );

      expect(response, isNotFound);
    });
  });
}
