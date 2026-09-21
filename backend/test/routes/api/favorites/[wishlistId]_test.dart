// expectNotAllowedMethods is marked @experimental in dart_frog_test.
// ignore_for_file: experimental_member_use

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

  TestRequestContext contextFor(HttpMethod method) {
    return TestRequestContext(
        path: '/api/favorites/1',
        method: method,
      )
      ..provide<AuthUser>(guest)
      ..provide<FavoriteService>(favorites);
  }

  setUp(() {
    data = MemoryWishlistData();
    wishlists = memoryWishlistService(data);
    favorites = memoryFavoriteService(data);
  });

  group('/api/favorites/{wishlistId}', () {
    test('rejects unsupported methods with 405', () async {
      await expectNotAllowedMethods(
        (context) => handleFavoriteByWishlistId(context, '1'),
        // ignore: unnecessary_lambdas
        contextBuilder: (method) => contextFor(method),
        allowedMethods: [HttpMethod.delete],
      );
    });

    test('DELETE removes the favorite and keeps the wishlist', () async {
      final list = await wishlists.create(
        owner,
        name: 'Birthday',
        visibility: 'link',
      );
      final token = await wishlists.share(owner, list.id);
      await favorites.add(guest, token);

      final response = await handleFavoriteByWishlistId(
        contextFor(HttpMethod.delete).context,
        '${list.id}',
      );

      expect(response.statusCode, HttpStatus.noContent);
      expect(await favorites.list(guest), isEmpty);
      expect(data.wishlists.containsKey(list.id), isTrue);
    });

    test('DELETE responds 404 when not favorited', () async {
      final response = await handleFavoriteByWishlistId(
        contextFor(HttpMethod.delete).context,
        '99',
      );

      expect(response, isNotFound);
    });
  });
}
