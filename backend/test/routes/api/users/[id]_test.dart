// expectNotAllowedMethods is marked @experimental in dart_frog_test.
// ignore_for_file: experimental_member_use

import 'dart:convert';

import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_test/dart_frog_test.dart';
import 'package:melist_backend/melist_backend.dart';
import 'package:melist_backend/src/profiles/profile_handlers.dart';
import 'package:test/test.dart';

import '../../../helpers/memory_wishlists.dart';

void main() {
  const owner = AuthUser(id: 1, firstName: 'Ann', username: 'ann');
  const guest = AuthUser(id: 2, username: 'bob');

  late MemoryWishlistData data;
  late WishlistService wishlists;
  late ProfileService profiles;

  TestRequestContext contextFor(
    HttpMethod method, {
    String id = '1',
    AuthUser auth = guest,
  }) {
    return TestRequestContext(
      path: '/api/users/$id',
      method: method,
    )
      ..provide<AuthUser>(auth)
      ..provide<ProfileService>(profiles);
  }

  setUp(() {
    data = MemoryWishlistData();
    wishlists = memoryWishlistService(data);
    profiles = memoryProfileService(data);
  });

  group('/api/users/{id}', () {
    test('rejects unsupported methods with 405', () async {
      await expectNotAllowedMethods(
        (context) => handlePublicUser(context, '1'),
        // ignore: unnecessary_lambdas
        contextBuilder: (method) => contextFor(method),
        allowedMethods: [HttpMethod.get],
      );
    });

    test('GET returns the public profile and public wishlists', () async {
      await wishlists.create(owner, name: 'Birthday', visibility: 'public');
      await wishlists.create(owner, name: 'Draft', visibility: 'draft');

      final response = await handlePublicUser(
        contextFor(HttpMethod.get).context,
        '1',
      );
      final body = jsonDecode(await response.body()) as Map<String, dynamic>;
      final user = body['user'] as Map<String, dynamic>;
      final lists = body['wishlists'] as List<dynamic>;

      expect(response, isOk);
      expect(user['id'], 1);
      expect(user['username'], 'ann');
      expect(lists, hasLength(1));
      expect((lists.first as Map)['name'], 'Birthday');
    });

    test('GET returns 404 when the user is missing', () async {
      final response = await handlePublicUser(
        contextFor(HttpMethod.get, id: '404').context,
        '404',
      );

      expect(response, isNotFound);
    });

    test('GET returns 400 for an invalid id', () async {
      final response = await handlePublicUser(
        contextFor(HttpMethod.get, id: 'abc').context,
        'abc',
      );

      expect(response, isBadRequest);
    });
  });
}
