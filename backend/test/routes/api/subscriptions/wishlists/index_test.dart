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
      path: '/api/subscriptions/wishlists',
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

  group('/api/subscriptions/wishlists', () {
    test('rejects unsupported methods with 405', () async {
      await expectNotAllowedMethods(
        handleWishlistSubscriptions,
        // ignore: unnecessary_lambdas
        contextBuilder: (method) => contextFor(method),
        allowedMethods: [HttpMethod.get, HttpMethod.post],
      );
    });

    test('GET returns followed public wishlists', () async {
      final list = await wishlists.create(
        owner,
        name: 'Birthday',
        visibility: 'public',
      );
      await subscriptions.subscribeWishlist(guest, list.id);

      final response = await handleWishlistSubscriptions(
        contextFor(HttpMethod.get).context,
      );
      final body = jsonDecode(await response.body()) as List<dynamic>;

      expect(response, isOk);
      expect((body.first as Map)['name'], 'Birthday');
    });

    test('POST subscribes by wishlistId', () async {
      final list = await wishlists.create(
        owner,
        name: 'Birthday',
        visibility: 'public',
      );

      final response = await handleWishlistSubscriptions(
        contextFor(
          HttpMethod.post,
          body: {'wishlistId': list.id},
        ).context,
      );
      final body = jsonDecode(await response.body()) as Map<String, dynamic>;

      expect(response, isCreated);
      expect(body['id'], list.id);
      expect(body['name'], 'Birthday');
    });

    test('POST returns 400 without wishlistId', () async {
      final response = await handleWishlistSubscriptions(
        contextFor(HttpMethod.post, body: {}).context,
      );

      expect(response, isBadRequest);
    });
  });
}
