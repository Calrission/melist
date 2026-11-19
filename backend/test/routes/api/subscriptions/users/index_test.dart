// expectNotAllowedMethods is marked @experimental in dart_frog_test.
// ignore_for_file: experimental_member_use

import 'dart:convert';
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

  TestRequestContext contextFor(
    HttpMethod method, {
    Map<String, Object?>? body,
  }) {
    return TestRequestContext(
        path: '/api/v1/subscriptions/users',
        method: method,
        body: body == null ? null : jsonEncode(body),
        headers: body == null
            ? const {}
            : {HttpHeaders.contentTypeHeader: 'application/json'},
      )
      ..provide<AuthUser>(guest)
      ..provide<SubscriptionService>(subscriptions);
  }

  setUp(() {
    data = MemoryWishlistData();
    wishlists = memoryWishlistService(data);
    subscriptions = memorySubscriptionService(data);
  });

  group('/api/v1/subscriptions/users', () {
    test('rejects unsupported methods with 405', () async {
      await expectNotAllowedMethods(
        handleUserSubscriptions,
        // ignore: unnecessary_lambdas
        contextBuilder: (method) => contextFor(method),
        allowedMethods: [HttpMethod.get, HttpMethod.post],
      );
    });

    test('GET returns followed users', () async {
      await wishlists.create(owner, name: 'Mine');
      await subscriptions.subscribeUser(guest, owner.id);

      final response = await handleUserSubscriptions(
        contextFor(HttpMethod.get).context,
      );
      final body = jsonDecode(await response.body()) as List<dynamic>;

      expect(response, isOk);
      expect((body.first as Map)['username'], 'ann');
    });

    test('POST subscribes by userId', () async {
      await wishlists.create(owner, name: 'Mine');

      final response = await handleUserSubscriptions(
        contextFor(HttpMethod.post, body: {'userId': owner.id}).context,
      );
      final body = jsonDecode(await response.body()) as Map<String, dynamic>;

      expect(response, isCreated);
      expect(body['id'], owner.id);
      expect(body['username'], 'ann');
    });

    test('POST returns 400 without userId', () async {
      final response = await handleUserSubscriptions(
        contextFor(HttpMethod.post, body: {}).context,
      );

      expect(response, isBadRequest);
    });
  });
}
