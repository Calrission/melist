// expectNotAllowedMethods is marked @experimental in dart_frog_test.
// ignore_for_file: experimental_member_use

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
  }) {
    return TestRequestContext(
        path: '/api/wishlists/1/wishes/1',
        method: method,
      )
      ..provide<AuthUser>(auth)
      ..provide<WishlistService>(service);
  }

  setUp(() {
    data = MemoryWishlistData();
    service = memoryWishlistService(data);
  });

  group('/api/wishlists/{id}/wishes/{wishId}', () {
    test('rejects unsupported methods with 405', () async {
      await expectNotAllowedMethods(
        (context) => handleWishlistWishById(context, '1', '1'),
        // ignore: unnecessary_lambdas
        contextBuilder: (method) => contextFor(method),
        allowedMethods: [HttpMethod.delete],
      );
    });

    test('DELETE detaches the wish and keeps the catalog row', () async {
      final list = await service.create(user, name: 'A');
      final wish = await service.addWish(
        user,
        list.id,
        wish: {'name': 'Book'},
      );

      final response = await handleWishlistWishById(
        contextFor(HttpMethod.delete).context,
        '${list.id}',
        '${wish.id}',
      );

      expect(response.statusCode, HttpStatus.noContent);
      expect((await service.getById(user, list.id)).items, isEmpty);
      expect(data.wishes.containsKey(wish.id), isTrue);
    });

    test('DELETE responds 403 for another user', () async {
      final list = await service.create(user, name: 'A');
      final wish = await service.addWish(
        user,
        list.id,
        wish: {'name': 'Book'},
      );

      final response = await handleWishlistWishById(
        contextFor(HttpMethod.delete, auth: stranger).context,
        '${list.id}',
        '${wish.id}',
      );

      expect(response, isForbidden);
    });

    test('DELETE responds 404 when the wish is not in the list', () async {
      final list = await service.create(user, name: 'A');

      final response = await handleWishlistWishById(
        contextFor(HttpMethod.delete).context,
        '${list.id}',
        '99',
      );

      expect(response, isNotFound);
    });
  });
}
