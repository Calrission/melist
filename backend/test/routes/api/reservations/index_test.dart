// expectNotAllowedMethods is marked @experimental in dart_frog_test.
// ignore_for_file: experimental_member_use

import 'dart:convert';

import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_test/dart_frog_test.dart';
import 'package:melist_backend/melist_backend.dart';
import 'package:melist_backend/src/wishes/wish_handlers.dart';
import 'package:test/test.dart';

import '../../../helpers/memory_wishlists.dart';

void main() {
  const owner = AuthUser(id: 7, firstName: 'Света', lastName: 'Миндаль');
  const guest = AuthUser(id: 8, username: 'bob');

  late MemoryWishlistData data;
  late WishlistService wishlists;
  late WishService wishes;

  TestRequestContext contextFor(HttpMethod method) {
    return TestRequestContext(
        path: '/api/v1/reservations',
        method: method,
      )
      ..provide<AuthUser>(guest)
      ..provide<WishService>(wishes);
  }

  setUp(() {
    data = MemoryWishlistData();
    wishlists = memoryWishlistService(data);
    wishes = memoryWishServiceFromLists(data);
  });

  group('/api/v1/reservations', () {
    test('rejects unsupported methods with 405', () async {
      await expectNotAllowedMethods(
        handleReservations,
        // ignore: unnecessary_lambdas
        contextBuilder: (method) => contextFor(method),
        allowedMethods: [HttpMethod.get],
      );
    });

    test('GET returns wishes reserved by the caller', () async {
      final list = await wishlists.create(
        owner,
        name: 'Gifts',
        visibility: 'link',
      );
      final wish = await wishlists.addWish(
        owner,
        list.id,
        wish: {'name': 'Book'},
      );
      final token = await wishlists.share(owner, list.id);
      await wishlists.reserveSharedWish(guest, token, wish.id);

      final response = await handleReservations(
        contextFor(HttpMethod.get).context,
      );
      final body = jsonDecode(await response.body()) as List<dynamic>;

      expect(response.statusCode, 200);
      expect(body, hasLength(1));
      expect(body.single, isA<Map<String, dynamic>>());
      final item = body.single as Map<String, dynamic>;
      expect(item['name'], 'Book');
      expect(item['reservedByMe'], isTrue);
      expect(item['ownerNickname'], 'Света Миндаль');
      expect(item.containsKey('reservedBy'), isFalse);
    });
  });
}
