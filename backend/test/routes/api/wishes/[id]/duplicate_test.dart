// expectNotAllowedMethods is marked @experimental in dart_frog_test.
// ignore_for_file: experimental_member_use

import 'dart:convert';

import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_test/dart_frog_test.dart';
import 'package:melist_backend/melist_backend.dart';
import 'package:melist_backend/src/wishes/wish_handlers.dart';
import 'package:test/test.dart';

import '../../../../helpers/memory_wishes.dart';

void main() {
  const user = AuthUser(id: 1, username: 'melist_test');
  const stranger = AuthUser(id: 2, username: 'other');

  late MemoryWishData data;
  late WishService service;

  TestRequestContext contextFor({AuthUser auth = user}) {
    return TestRequestContext(
        path: '/api/wishes/1/duplicate',
        method: HttpMethod.post,
      )
      ..provide<AuthUser>(auth)
      ..provide<WishService>(service);
  }

  setUp(() {
    data = MemoryWishData();
    service = memoryWishService(data);
  });

  group('POST /api/wishes/{id}/duplicate', () {
    test('rejects unsupported methods with 405', () async {
      await expectNotAllowedMethods(
        (context) => handleWishDuplicate(context, '1'),
        contextBuilder: (method) =>
            TestRequestContext(
                path: '/api/wishes/1/duplicate',
                method: method,
              )
              ..provide<AuthUser>(user)
              ..provide<WishService>(service),
        allowedMethods: [HttpMethod.post],
      );
    });

    test('creates a copy of an own wish', () async {
      final created = await service.create(user, name: 'Headphones');

      final response = await handleWishDuplicate(
        contextFor().context,
        '${created.id}',
      );
      final body = jsonDecode(await response.body()) as Map<String, dynamic>;

      expect(response, isCreated);
      expect(body['name'], 'Headphones');
      expect(body['copiedFrom'], created.id);
      expect(body['id'], isNot(created.id));
    });

    test('responds 403 for another user', () async {
      final created = await service.create(user, name: 'Headphones');

      final response = await handleWishDuplicate(
        contextFor(auth: stranger).context,
        '${created.id}',
      );

      expect(response, isForbidden);
    });
  });
}
