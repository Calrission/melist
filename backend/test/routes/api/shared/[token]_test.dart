// expectNotAllowedMethods is marked @experimental in dart_frog_test.
// ignore_for_file: experimental_member_use

import 'dart:convert';

import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_test/dart_frog_test.dart';
import 'package:melist_backend/melist_backend.dart';
import 'package:melist_backend/src/wishlists/wishlist_handlers.dart';
import 'package:test/test.dart';

import '../../../helpers/memory_wishlists.dart';

void main() {
  const user = AuthUser(id: 1, username: 'melist_test');
  const stranger = AuthUser(id: 2, username: 'other');

  late MemoryWishlistData data;
  late WishlistService service;

  TestRequestContext contextFor(
    HttpMethod method, {
    AuthUser auth = stranger,
    String token = 'abc',
  }) {
    return TestRequestContext(
        path: '/api/v1/shared/$token',
        method: method,
      )
      ..provide<AuthUser>(auth)
      ..provide<WishlistService>(service);
  }

  setUp(() {
    data = MemoryWishlistData();
    service = memoryWishlistService(data);
  });

  group('/api/v1/shared/{token}', () {
    test('rejects unsupported methods with 405', () async {
      await expectNotAllowedMethods(
        (context) => handleSharedWishlist(context, 'abc'),
        // ignore: unnecessary_lambdas
        contextBuilder: (method) => contextFor(method),
        allowedMethods: [HttpMethod.get],
      );
    });

    test('GET returns the wishlist by share token', () async {
      final list = await service.create(
        user,
        name: 'Birthday',
        visibility: 'link',
      );
      final token = await service.share(user, list.id);

      final response = await handleSharedWishlist(
        contextFor(HttpMethod.get, token: token).context,
        token,
      );
      final body = jsonDecode(await response.body()) as Map<String, dynamic>;

      expect(response, isOk);
      expect(body['id'], list.id);
      expect(body['name'], 'Birthday');
      expect(body['shareToken'], token);
    });

    test('GET responds 404 for an unknown token', () async {
      final response = await handleSharedWishlist(
        contextFor(HttpMethod.get).context,
        'missing',
      );

      expect(response, isNotFound);
    });
  });
}
