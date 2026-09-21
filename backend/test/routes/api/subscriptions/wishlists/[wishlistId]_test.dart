// expectNotAllowedMethods is marked @experimental in dart_frog_test.
// ignore_for_file: experimental_member_use

import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_test/dart_frog_test.dart';
import 'package:melist_backend/melist_backend.dart';
import 'package:melist_backend/src/subscriptions/subscription_handlers.dart';
import 'package:test/test.dart';

import '../../../../helpers/memory_wishlists.dart';

void main() {
  const owner = AuthUser(id: 1, username: 'ann');
  const guest = AuthUser(id: 2, username: 'bob');

  late MemoryWishlistData data;
  late WishlistService wishlists;
  late SubscriptionService subscriptions;

  TestRequestContext contextFor(HttpMethod method) {
    return TestRequestContext(
      path: '/api/subscriptions/wishlists/1',
      method: method,
    )
      ..provide<AuthUser>(guest)
      ..provide<SubscriptionService>(subscriptions);
  }

  setUp(() {
    data = MemoryWishlistData();
    wishlists = memoryWishlistService(data);
    subscriptions = memorySubscriptionService(data);
  });

  group('/api/subscriptions/wishlists/{wishlistId}', () {
    test('rejects unsupported methods with 405', () async {
      await expectNotAllowedMethods(
        (context) => handleWishlistUnsubscribe(context, '1'),
        // ignore: unnecessary_lambdas
        contextBuilder: (method) => contextFor(method),
        allowedMethods: [HttpMethod.delete],
      );
    });

    test('DELETE unsubscribes and keeps the wishlist', () async {
      final list = await wishlists.create(
        owner,
        name: 'Birthday',
        visibility: 'public',
      );
      await subscriptions.subscribeWishlist(guest, list.id);

      final response = await handleWishlistUnsubscribe(
        contextFor(HttpMethod.delete).context,
        '${list.id}',
      );

      expect(response.statusCode, HttpStatus.noContent);
      expect(await subscriptions.listWishlists(guest), isEmpty);
      expect(data.wishlists.containsKey(list.id), isTrue);
    });

    test('DELETE responds 404 when not subscribed', () async {
      final response = await handleWishlistUnsubscribe(
        contextFor(HttpMethod.delete).context,
        '99',
      );

      expect(response, isNotFound);
    });
  });
}
