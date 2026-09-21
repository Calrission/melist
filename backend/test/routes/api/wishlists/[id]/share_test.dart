// expectNotAllowedMethods is marked @experimental in dart_frog_test.
// ignore_for_file: experimental_member_use

import 'dart:convert';

import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_test/dart_frog_test.dart';
import 'package:melist_backend/melist_backend.dart';
import 'package:melist_backend/src/wishlists/wishlist_handlers.dart';
import 'package:test/test.dart';

import '../../../../helpers/memory_wishlists.dart';

void main() {
  const user = AuthUser(id: 1, username: 'melist_test');
  const stranger = AuthUser(id: 2, username: 'other');
  const config = AppConfig(
    botToken: 'token',
    jwtSecret: 'secret',
    databaseUrl: 'postgres://melist@localhost/melist',
  );

  late MemoryWishlistData data;
  late WishlistService service;

  TestRequestContext contextFor(
    HttpMethod method, {
    AuthUser auth = user,
  }) {
    return TestRequestContext(
      path: '/api/wishlists/1/share',
      method: method,
    )
      ..provide<AuthUser>(auth)
      ..provide<WishlistService>(service)
      ..provide<AppConfig>(config);
  }

  setUp(() {
    data = MemoryWishlistData();
    service = memoryWishlistService(data);
  });

  group('/api/wishlists/{id}/share', () {
    test('rejects unsupported methods with 405', () async {
      await expectNotAllowedMethods(
        (context) => handleWishlistShare(context, '1'),
        // ignore: unnecessary_lambdas
        contextBuilder: (method) => contextFor(method),
        allowedMethods: [HttpMethod.post],
      );
    });

    test('POST returns a Mini App share link', () async {
      final list = await service.create(user, name: 'Birthday');

      final response = await handleWishlistShare(
        contextFor(HttpMethod.post).context,
        '${list.id}',
      );
      final body = jsonDecode(await response.body()) as Map<String, dynamic>;

      expect(response, isOk);
      expect(body['shareToken'], isNotEmpty);
      expect(
        body['url'],
        'https://t.me/melist_bot/app?startapp=wl_${body['shareToken']}',
      );
    });

    test('POST responds 403 for another user', () async {
      final list = await service.create(user, name: 'Birthday');

      final response = await handleWishlistShare(
        contextFor(HttpMethod.post, auth: stranger).context,
        '${list.id}',
      );

      expect(response, isForbidden);
    });
  });
}
