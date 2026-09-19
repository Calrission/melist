// expectNotAllowedMethods is marked @experimental in dart_frog_test.
// ignore_for_file: experimental_member_use

import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_test/dart_frog_test.dart';
import 'package:melist_backend/melist_backend.dart';
import 'package:melist_backend/src/wishlists/wishlist_handlers.dart';
import 'package:test/test.dart';

import '../../../helpers/memory_wishlists.dart';

void main() {
  const user = AuthUser(id: 1, username: 'melist_test');
  const stranger = AuthUser(id: 2, username: 'other');

  late MemoryWishlistData data;
  late WishlistService service;

  TestRequestContext contextFor(
    HttpMethod method, {
    AuthUser auth = user,
    Map<String, Object?>? body,
  }) {
    return TestRequestContext(
      path: '/api/wishlists/1',
      method: method,
      body: body == null ? null : jsonEncode(body),
      headers: body == null
          ? const {}
          : {HttpHeaders.contentTypeHeader: 'application/json'},
    )
      ..provide<AuthUser>(auth)
      ..provide<WishlistService>(service);
  }

  setUp(() {
    data = MemoryWishlistData();
    service = memoryWishlistService(data);
  });

  group('/api/wishlists/{id}', () {
    test('rejects unsupported methods with 405', () async {
      await expectNotAllowedMethods(
        (context) => handleWishlistById(context, '1'),
        // ignore: unnecessary_lambdas
        contextBuilder: (method) => contextFor(method),
        allowedMethods: [
          HttpMethod.get,
          HttpMethod.patch,
          HttpMethod.delete,
        ],
      );
    });

    test('GET returns the card with items', () async {
      final created = await service.create(user, name: 'Birthday');

      final response = await handleWishlistById(
        contextFor(HttpMethod.get).context,
        '${created.id}',
      );
      final body = jsonDecode(await response.body()) as Map<String, dynamic>;

      expect(response, isOk);
      expect(body['name'], 'Birthday');
      expect(body['items'], isEmpty);
    });

    test('GET responds 403 for another user', () async {
      final created = await service.create(user, name: 'Birthday');

      final response = await handleWishlistById(
        contextFor(HttpMethod.get, auth: stranger).context,
        '${created.id}',
      );

      expect(response, isForbidden);
    });

    test('GET responds 400 for a non-numeric id', () async {
      final response = await handleWishlistById(
        contextFor(HttpMethod.get).context,
        'abc',
      );

      expect(response, isBadRequest);
    });

    test('PATCH updates name and visibility', () async {
      final created = await service.create(user, name: 'Old');

      final response = await handleWishlistById(
        contextFor(
          HttpMethod.patch,
          body: {'name': 'New year', 'visibility': 'public'},
        ).context,
        '${created.id}',
      );
      final body = jsonDecode(await response.body()) as Map<String, dynamic>;

      expect(response, isOk);
      expect(body['name'], 'New year');
      expect(body['visibility'], 'public');
    });

    test('DELETE removes the wishlist', () async {
      final created = await service.create(user, name: 'Old');

      final response = await handleWishlistById(
        contextFor(HttpMethod.delete).context,
        '${created.id}',
      );

      expect(response.statusCode, HttpStatus.noContent);
      expect(data.wishlists.containsKey(created.id), isFalse);
    });

    test('DELETE responds 404 when missing', () async {
      final response = await handleWishlistById(
        contextFor(HttpMethod.delete).context,
        '99',
      );

      expect(response, isNotFound);
    });
  });
}
