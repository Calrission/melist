// expectNotAllowedMethods is marked @experimental in dart_frog_test.
// ignore_for_file: experimental_member_use

import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_test/dart_frog_test.dart';
import 'package:melist_backend/melist_backend.dart';
import 'package:melist_backend/src/wishlists/wishlist_handlers.dart';
import 'package:test/test.dart';

import '../../../../../helpers/memory_wishlists.dart';

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
      path: '/api/wishlists/1/wishes',
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

  group('/api/wishlists/{id}/wishes', () {
    test('rejects unsupported methods with 405', () async {
      await expectNotAllowedMethods(
        (context) => handleWishlistWishes(context, '1'),
        // ignore: unnecessary_lambdas
        contextBuilder: (method) => contextFor(method),
        allowedMethods: [HttpMethod.post, HttpMethod.patch],
      );
    });

    test('POST creates a wish inside the wishlist', () async {
      final list = await service.create(user, name: 'Birthday');

      final response = await handleWishlistWishes(
        contextFor(
          HttpMethod.post,
          body: {
            'wish': {'name': 'Headphones', 'price': 12000},
          },
        ).context,
        '${list.id}',
      );
      final body = jsonDecode(await response.body()) as Map<String, dynamic>;

      expect(response, isCreated);
      expect(body['name'], 'Headphones');
      expect(body['ownerId'], 1);
      expect(
        (await service.getById(user, list.id)).items.single.id,
        body['id'],
      );
    });

    test('POST attaches an existing own wish', () async {
      final first = await service.create(user, name: 'A');
      final second = await service.create(user, name: 'B');
      final wish = await service.addWish(
        user,
        first.id,
        wish: {'name': 'Book'},
      );

      final response = await handleWishlistWishes(
        contextFor(HttpMethod.post, body: {'wishId': wish.id}).context,
        '${second.id}',
      );
      final body = jsonDecode(await response.body()) as Map<String, dynamic>;

      expect(response, isCreated);
      expect(body['id'], wish.id);
    });

    test('POST copies from another public wishlist', () async {
      final publicList = await service.create(
        stranger,
        name: 'Public',
        visibility: 'public',
      );
      final source = await service.addWish(
        stranger,
        publicList.id,
        wish: {'name': 'Headphones'},
      );
      final mine = await service.create(user, name: 'Mine');

      final response = await handleWishlistWishes(
        contextFor(
          HttpMethod.post,
          body: {'copyFromWishId': source.id},
        ).context,
        '${mine.id}',
      );
      final body = jsonDecode(await response.body()) as Map<String, dynamic>;

      expect(response, isCreated);
      expect(body['id'], isNot(source.id));
      expect(body['copiedFrom'], source.id);
      expect(body['ownerId'], 1);
    });

    test('POST responds 409 when the wish is already attached', () async {
      final list = await service.create(user, name: 'A');
      final wish = await service.addWish(
        user,
        list.id,
        wish: {'name': 'Book'},
      );

      final response = await handleWishlistWishes(
        contextFor(HttpMethod.post, body: {'wishId': wish.id}).context,
        '${list.id}',
      );

      expect(response.statusCode, HttpStatus.conflict);
      expectJsonBody(response, {'error': 'Wish is already in the wishlist'});
    });

    test('POST responds 400 when no variant is provided', () async {
      final list = await service.create(user, name: 'A');

      final response = await handleWishlistWishes(
        contextFor(HttpMethod.post, body: {}).context,
        '${list.id}',
      );

      expect(response, isBadRequest);
    });

    test('POST responds 403 for another user', () async {
      final list = await service.create(user, name: 'A');

      final response = await handleWishlistWishes(
        contextFor(
          HttpMethod.post,
          auth: stranger,
          body: {
            'wish': {'name': 'Book'},
          },
        ).context,
        '${list.id}',
      );

      expect(response, isForbidden);
    });

    test('PATCH reorders wishes', () async {
      final list = await service.create(user, name: 'A');
      final first = await service.addWish(
        user,
        list.id,
        wish: {'name': 'One'},
      );
      final second = await service.addWish(
        user,
        list.id,
        wish: {'name': 'Two'},
      );

      final response = await handleWishlistWishes(
        contextFor(
          HttpMethod.patch,
          body: {
            'order': [second.id, first.id],
          },
        ).context,
        '${list.id}',
      );

      expect(response.statusCode, HttpStatus.noContent);
      expect(
        (await service.getById(user, list.id)).items.map((item) => item.id),
        [second.id, first.id],
      );
    });

    test('PATCH responds 400 when order is missing', () async {
      final list = await service.create(user, name: 'A');

      final response = await handleWishlistWishes(
        contextFor(HttpMethod.patch, body: {}).context,
        '${list.id}',
      );

      expect(response, isBadRequest);
    });
  });
}
