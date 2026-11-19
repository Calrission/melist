// expectNotAllowedMethods is marked @experimental in dart_frog_test.
// ignore_for_file: experimental_member_use

import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_test/dart_frog_test.dart';
import 'package:melist_backend/melist_backend.dart';
import 'package:melist_backend/src/wishes/wish_handlers.dart';
import 'package:test/test.dart';

import '../../../helpers/memory_wishes.dart';

void main() {
  const user = AuthUser(id: 1, username: 'melist_test');

  late MemoryWishData data;
  late WishService service;

  TestRequestContext contextFor(
    HttpMethod method, {
    String path = '/api/v1/wishes',
    Map<String, Object?>? body,
  }) {
    return TestRequestContext(
        path: path,
        method: method,
        body: body == null ? null : jsonEncode(body),
        headers: body == null
            ? const {}
            : {HttpHeaders.contentTypeHeader: 'application/json'},
      )
      ..provide<AuthUser>(user)
      ..provide<WishService>(service);
  }

  setUp(() {
    data = MemoryWishData();
    service = memoryWishService(data);
  });

  group('/api/v1/wishes', () {
    test('rejects unsupported methods with 405', () async {
      await expectNotAllowedMethods(
        handleWishesCollection,
        // ignore: unnecessary_lambdas
        contextBuilder: (method) => contextFor(method),
        allowedMethods: [
          HttpMethod.get,
          HttpMethod.post,
          HttpMethod.delete,
        ],
      );
    });

    test('GET returns own wishes', () async {
      await service.create(user, name: 'Headphones');

      final response = await handleWishesCollection(
        contextFor(HttpMethod.get).context,
      );
      final body = jsonDecode(await response.body()) as List<dynamic>;

      expect(response, isOk);
      expect(body, hasLength(1));
      expect((body.first as Map)['name'], 'Headphones');
    });

    test('GET rejects mine=false', () async {
      final response = await handleWishesCollection(
        contextFor(HttpMethod.get, path: '/api/v1/wishes?mine=false').context,
      );

      expect(response, isBadRequest);
    });

    test('POST creates a wish', () async {
      final response = await handleWishesCollection(
        contextFor(
          HttpMethod.post,
          body: {
            'name': 'Headphones',
            'price': 12000,
            'status': 'draft',
          },
        ).context,
      );
      final body = jsonDecode(await response.body()) as Map<String, dynamic>;

      expect(response, isCreated);
      expect(body['name'], 'Headphones');
      expect(body['price'], 12000);
      expect(body['ownerId'], 1);
    });

    test('POST responds 400 when name is missing', () async {
      final response = await handleWishesCollection(
        contextFor(HttpMethod.post, body: {'price': 1}).context,
      );

      expect(response, isBadRequest);
      expectJsonBody(response, {'error': 'name is required'});
    });

    test('DELETE removes own wishes', () async {
      final created = await service.create(user, name: 'A');

      final response = await handleWishesCollection(
        contextFor(
          HttpMethod.delete,
          body: {
            'ids': [created.id],
          },
        ).context,
      );

      expect(response.statusCode, HttpStatus.noContent);
      expect(data.wishes, isEmpty);
    });

    test('DELETE responds 400 when ids are missing', () async {
      final response = await handleWishesCollection(
        contextFor(HttpMethod.delete, body: {}).context,
      );

      expect(response, isBadRequest);
    });
  });
}
