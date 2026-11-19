// expectNotAllowedMethods is marked @experimental in dart_frog_test.
// ignore_for_file: experimental_member_use

import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_test/dart_frog_test.dart';
import 'package:melist_backend/melist_backend.dart';
import 'package:melist_backend/src/favorites/favorite_handlers.dart';
import 'package:test/test.dart';

import '../../../helpers/memory_wishlists.dart';

void main() {
  const owner = AuthUser(id: 1, username: 'melist_test');
  const guest = AuthUser(id: 2, username: 'other');

  late MemoryWishlistData data;
  late WishlistService wishlists;
  late FavoriteService favorites;

  TestRequestContext contextFor(
    HttpMethod method, {
    Map<String, Object?>? body,
  }) {
    return TestRequestContext(
        path: '/api/v1/favorites',
        method: method,
        body: body == null ? null : jsonEncode(body),
        headers: body == null
            ? const {}
            : {HttpHeaders.contentTypeHeader: 'application/json'},
      )
      ..provide<AuthUser>(guest)
      ..provide<FavoriteService>(favorites);
  }

  setUp(() {
    data = MemoryWishlistData();
    wishlists = memoryWishlistService(data);
    favorites = memoryFavoriteService(data);
  });

  group('/api/v1/favorites', () {
    test('rejects unsupported methods with 405', () async {
      await expectNotAllowedMethods(
        handleFavoritesCollection,
        // ignore: unnecessary_lambdas
        contextBuilder: (method) => contextFor(method),
        allowedMethods: [
          HttpMethod.get,
          HttpMethod.post,
          HttpMethod.patch,
        ],
      );
    });

    test('GET returns favorite wishlists', () async {
      const named = AuthUser(
        id: 1,
        firstName: 'Ann',
        lastName: 'Lee',
        username: 'melist_test',
      );
      final list = await wishlists.create(
        named,
        name: 'Birthday',
        visibility: 'link',
      );
      final token = await wishlists.share(named, list.id);
      await favorites.add(guest, token);

      final response = await handleFavoritesCollection(
        contextFor(HttpMethod.get).context,
      );
      final body = jsonDecode(await response.body()) as List<dynamic>;
      final wishlist = body.first as Map;

      expect(response, isOk);
      expect(body, hasLength(1));
      expect(wishlist['name'], 'Birthday');
      expect(wishlist['ownerId'], 1);
      expect(wishlist['ownerNickname'], 'Ann Lee');
    });

    test('POST adds a wishlist by share token', () async {
      final list = await wishlists.create(
        owner,
        name: 'Birthday',
        visibility: 'link',
      );
      final token = await wishlists.share(owner, list.id);

      final response = await handleFavoritesCollection(
        contextFor(HttpMethod.post, body: {'shareToken': token}).context,
      );
      final body = jsonDecode(await response.body()) as Map<String, dynamic>;

      expect(response, isCreated);
      expect(body['id'], list.id);
      expect(body['name'], 'Birthday');
    });

    test('POST responds 409 when already favorited', () async {
      final list = await wishlists.create(
        owner,
        name: 'Birthday',
        visibility: 'link',
      );
      final token = await wishlists.share(owner, list.id);
      await favorites.add(guest, token);

      final response = await handleFavoritesCollection(
        contextFor(HttpMethod.post, body: {'shareToken': token}).context,
      );

      expect(response.statusCode, HttpStatus.conflict);
    });

    test('POST responds 400 when shareToken is missing', () async {
      final response = await handleFavoritesCollection(
        contextFor(HttpMethod.post, body: {}).context,
      );

      expect(response, isBadRequest);
    });

    test('PATCH reorders favorites', () async {
      final firstList = await wishlists.create(
        owner,
        name: 'A',
        visibility: 'link',
      );
      final secondList = await wishlists.create(
        owner,
        name: 'B',
        visibility: 'link',
      );
      final first = await favorites.add(
        guest,
        await wishlists.share(owner, firstList.id),
      );
      final second = await favorites.add(
        guest,
        await wishlists.share(owner, secondList.id),
      );

      final response = await handleFavoritesCollection(
        contextFor(
          HttpMethod.patch,
          body: {
            'order': [second.id, first.id],
          },
        ).context,
      );

      expect(response.statusCode, HttpStatus.noContent);
      expect(
        (await favorites.list(guest)).map((item) => item.name),
        ['B', 'A'],
      );
    });
  });
}
