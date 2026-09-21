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
      path: '/api/subscriptions/users/1',
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

  group('/api/subscriptions/users/{userId}', () {
    test('rejects unsupported methods with 405', () async {
      await expectNotAllowedMethods(
        (context) => handleUserUnsubscribe(context, '1'),
        // ignore: unnecessary_lambdas
        contextBuilder: (method) => contextFor(method),
        allowedMethods: [HttpMethod.delete],
      );
    });

    test('DELETE unsubscribes from the profile', () async {
      await wishlists.create(owner, name: 'Mine');
      await subscriptions.subscribeUser(guest, owner.id);

      final response = await handleUserUnsubscribe(
        contextFor(HttpMethod.delete).context,
        '${owner.id}',
      );

      expect(response.statusCode, HttpStatus.noContent);
      expect(await subscriptions.listUsers(guest), isEmpty);
    });

    test('DELETE responds 404 when not subscribed', () async {
      final response = await handleUserUnsubscribe(
        contextFor(HttpMethod.delete).context,
        '99',
      );

      expect(response, isNotFound);
    });
  });
}
