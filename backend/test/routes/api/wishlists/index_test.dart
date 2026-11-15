// expectNotAllowedMethods is marked @experimental in dart_frog_test.
// ignore_for_file: experimental_member_use

import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_test/dart_frog_test.dart';
import 'package:melist_backend/melist_backend.dart';
import 'package:melist_backend/src/wishlists/wishlist_handlers.dart';
import 'package:melist_core/melist_core.dart';
import 'package:test/test.dart';

import '../../../helpers/memory_wishlists.dart';

void main() {
  const user = AuthUser(id: 1, username: 'melist_test');

  late MemoryWishlistData data;
  late WishlistService service;

  TestRequestContext contextFor(
    HttpMethod method, {
    Map<String, Object?>? body,
  }) {
    return TestRequestContext(
        path: '/api/wishlists',
        method: method,
        body: body == null ? null : jsonEncode(body),
        headers: body == null
            ? const {}
            : {HttpHeaders.contentTypeHeader: 'application/json'},
      )
      ..provide<AuthUser>(user)
      ..provide<WishlistService>(service);
  }

  setUp(() {
    data = MemoryWishlistData();
    service = memoryWishlistService(data);
  });

  group('/api/wishlists', () {
    test('rejects unsupported methods with 405', () async {
      await expectNotAllowedMethods(
        handleWishlistsCollection,
        // ignore: unnecessary_lambdas
        contextBuilder: (method) => contextFor(method),
        allowedMethods: [
          HttpMethod.get,
          HttpMethod.post,
          HttpMethod.patch,
          HttpMethod.delete,
        ],
      );
    });

    test('GET returns own wishlists with items', () async {
      data.wishes[1] = const WishModel(id: 1, ownerId: 1, name: 'Headphones');
      await service.create(user, name: 'Birthday', wishIds: [1]);

      final response = await handleWishlistsCollection(
        contextFor(HttpMethod.get).context,
      );
      final body = jsonDecode(await response.body()) as List<dynamic>;
      final wishlist = body.first as Map;

      expect(response, isOk);
      expect(body, hasLength(1));
      expect(wishlist['name'], 'Birthday');
      expect((wishlist['items'] as List).single['name'], 'Headphones');
    });

    test('POST creates a wishlist', () async {
      final response = await handleWishlistsCollection(
        contextFor(
          HttpMethod.post,
          body: {
            'name': 'Birthday',
            'visibility': 'public',
            'coverUrl': ' https://img.example/cover.png ',
          },
        ).context,
      );
      final body = jsonDecode(await response.body()) as Map<String, dynamic>;

      expect(response, isCreated);
      expect(body['name'], 'Birthday');
      expect(body['visibility'], 'public');
      expect(body['coverUrl'], 'https://img.example/cover.png');
      expect(body['ownerId'], 1);
    });

    test('POST responds 400 when name is missing', () async {
      final response = await handleWishlistsCollection(
        contextFor(HttpMethod.post, body: {'visibility': 'public'}).context,
      );

      expect(response, isBadRequest);
      expectJsonBody(response, {'error': 'name is required'});
    });

    test('PATCH reorders own wishlists', () async {
      final first = await service.create(user, name: 'A');
      final second = await service.create(user, name: 'B');

      final response = await handleWishlistsCollection(
        contextFor(
          HttpMethod.patch,
          body: {
            'order': [second.id, first.id],
          },
        ).context,
      );

      expect(response.statusCode, HttpStatus.noContent);
      expect(
        (await service.listMine(user)).map((item) => item.name),
        ['B', 'A'],
      );
    });

    test('PATCH responds 400 when order is missing', () async {
      final response = await handleWishlistsCollection(
        contextFor(HttpMethod.patch, body: {}).context,
      );

      expect(response, isBadRequest);
    });

    test('DELETE removes own wishlists', () async {
      final created = await service.create(user, name: 'A');

      final response = await handleWishlistsCollection(
        contextFor(
          HttpMethod.delete,
          body: {
            'ids': [created.id],
          },
        ).context,
      );

      expect(response.statusCode, HttpStatus.noContent);
      expect(data.wishlists, isEmpty);
    });

    test('DELETE responds 400 when ids are missing', () async {
      final response = await handleWishlistsCollection(
        contextFor(HttpMethod.delete, body: {}).context,
      );

      expect(response, isBadRequest);
    });
  });
}
