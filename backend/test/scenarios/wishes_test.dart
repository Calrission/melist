import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_test/dart_frog_test.dart';
import 'package:melist_backend/src/wishes/wish_handlers.dart';
import 'package:test/test.dart';

import '../helpers/scenario_harness.dart';

void main() {
  late ScenarioHarness app;

  setUp(() {
    app = ScenarioHarness();
  });

  group('docs/scenarios.md wishes catalog', () {
    test('28. create a wish with fields; name is required', () async {
      final created = await handleWishesCollection(
        app
            .context(
              HttpMethod.post,
              '/api/wishes',
              body: {
                'name': 'Наушники',
                'price': 12000,
                'url': 'https://example.com',
                'description': 'чёрные',
                'coverUrl': 'https://example.com/c.png',
              },
            )
            .context,
      );
      expect(created, isCreated);
      final body = await jsonMap(created);
      expect(body['name'], 'Наушники');
      expect(body['price'], 12000);
      expect(body['url'], 'https://example.com');
      expect(body['description'], 'чёрные');
      expect(body['coverUrl'], 'https://example.com/c.png');
      expect(body['status'], 'free');

      final missing = await handleWishesCollection(
        app
            .context(
              HttpMethod.post,
              '/api/wishes',
              body: <String, Object?>{},
            )
            .context,
      );
      expect(missing, isBadRequest);
      expect((await jsonMap(missing))['error'], 'name is required');
    });

    test('29. own wishes newest first, not B’s', () async {
      await handleWishesCollection(
        app
            .context(HttpMethod.post, '/api/wishes', body: {'name': 'W1'})
            .context,
      );
      await handleWishesCollection(
        app
            .context(HttpMethod.post, '/api/wishes', body: {'name': 'W2'})
            .context,
      );
      await handleWishesCollection(
        app
            .context(
              HttpMethod.post,
              '/api/wishes',
              as: ScenarioHarness.b,
              body: {'name': 'Other'},
            )
            .context,
      );

      final listed = await handleWishesCollection(
        app.context(HttpMethod.get, '/api/wishes').context,
      );
      expect(listed, isOk);
      expect(
        (await jsonList(listed)).map((item) => (item as Map)['name']),
        ['W2', 'W1'],
      );
    });

    test('30. search by name; mine=false is 400', () async {
      await handleWishesCollection(
        app
            .context(
              HttpMethod.post,
              '/api/wishes',
              body: {'name': 'Наушники'},
            )
            .context,
      );
      await handleWishesCollection(
        app
            .context(HttpMethod.post, '/api/wishes', body: {'name': 'Книга'})
            .context,
      );

      final found = await handleWishesCollection(
        app.context(HttpMethod.get, '/api/wishes?query=науш').context,
      );
      expect(found, isOk);
      expect(
        (await jsonList(found)).map((item) => (item as Map)['name']),
        ['Наушники'],
      );

      final missed = await handleWishesCollection(
        app.context(HttpMethod.get, '/api/wishes?query=стол').context,
      );
      expect(await jsonList(missed), isEmpty);

      final mine = await handleWishesCollection(
        app.context(HttpMethod.get, '/api/wishes?mine=false').context,
      );
      expect(mine, isBadRequest);
      expect((await jsonMap(mine))['error'], 'mine must be true');
    });

    test('31. get, patch, delete own wish; B is forbidden', () async {
      final created = await jsonMap(
        await handleWishesCollection(
          app
              .context(
                HttpMethod.post,
                '/api/wishes',
                body: {'name': 'Старое'},
              )
              .context,
        ),
      );
      final id = '${created['id']}';

      final got = await handleWishById(
        app.context(HttpMethod.get, '/api/wishes/$id').context,
        id,
      );
      expect(got, isOk);

      final patched = await handleWishById(
        app
            .context(
              HttpMethod.patch,
              '/api/wishes/$id',
              body: {'name': 'Новое'},
            )
            .context,
        id,
      );
      expect(patched, isOk);
      expect((await jsonMap(patched))['name'], 'Новое');

      final asBGet = await handleWishById(
        app
            .context(
              HttpMethod.get,
              '/api/wishes/$id',
              as: ScenarioHarness.b,
            )
            .context,
        id,
      );
      expect(asBGet, isForbidden);

      final deleted = await handleWishById(
        app.context(HttpMethod.delete, '/api/wishes/$id').context,
        id,
      );
      expect(deleted.statusCode, HttpStatus.noContent);

      final missing = await handleWishById(
        app.context(HttpMethod.get, '/api/wishes/$id').context,
        id,
      );
      expect(missing, isNotFound);
    });

    test('33. wish status values', () async {
      final created = await jsonMap(
        await handleWishesCollection(
          app
              .context(HttpMethod.post, '/api/wishes', body: {'name': 'W'})
              .context,
        ),
      );
      final id = '${created['id']}';
      for (final status in ['draft', 'free', 'reserved']) {
        final patched = await handleWishById(
          app
              .context(
                HttpMethod.patch,
                '/api/wishes/$id',
                body: {'status': status},
              )
              .context,
          id,
        );
        expect(patched, isOk);
        expect((await jsonMap(patched))['status'], status);
      }

      final bad = await handleWishById(
        app
            .context(
              HttpMethod.patch,
              '/api/wishes/$id',
              body: {'status': 'done'},
            )
            .context,
        id,
      );
      expect(bad, isBadRequest);
    });

    test('34. duplicate own wish; B cannot', () async {
      final created = await jsonMap(
        await handleWishesCollection(
          app
              .context(
                HttpMethod.post,
                '/api/wishes',
                body: {'name': 'Наушники'},
              )
              .context,
        ),
      );
      final id = '${created['id']}';

      final copy = await handleWishDuplicate(
        app.context(HttpMethod.post, '/api/wishes/$id/duplicate').context,
        id,
      );
      expect(copy, isCreated);
      final copyBody = await jsonMap(copy);
      expect(copyBody['id'], isNot(created['id']));
      expect(copyBody['copiedFrom'], created['id']);
      expect(copyBody['name'], 'Наушники');

      final original = await jsonMap(
        await handleWishById(
          app.context(HttpMethod.get, '/api/wishes/$id').context,
          id,
        ),
      );
      expect(original['name'], 'Наушники');
      expect(original['copiedFrom'], isNull);

      final asB = await handleWishDuplicate(
        app
            .context(
              HttpMethod.post,
              '/api/wishes/$id/duplicate',
              as: ScenarioHarness.b,
            )
            .context,
        id,
      );
      expect(asB, isForbidden);
    });

    test('35. bulk-delete wishes', () async {
      final ids = <int>[];
      for (final name in ['W1', 'W2', 'W3']) {
        ids.add(
          idOf(
            await jsonMap(
              await handleWishesCollection(
                app
                    .context(
                      HttpMethod.post,
                      '/api/wishes',
                      body: {'name': name},
                    )
                    .context,
              ),
            ),
          ),
        );
      }

      final deleted = await handleWishesCollection(
        app
            .context(
              HttpMethod.delete,
              '/api/wishes',
              body: {
                'ids': [ids[0], ids[1]],
              },
            )
            .context,
      );
      expect(deleted.statusCode, HttpStatus.noContent);

      final listed = await jsonList(
        await handleWishesCollection(
          app.context(HttpMethod.get, '/api/wishes').context,
        ),
      );
      expect(listed.map((item) => (item as Map)['id']), [ids[2]]);

      final empty = await handleWishesCollection(
        app
            .context(
              HttpMethod.delete,
              '/api/wishes',
              body: {'ids': <int>[]},
            )
            .context,
      );
      expect(empty, isBadRequest);

      final foreign = await jsonMap(
        await handleWishesCollection(
          app
              .context(
                HttpMethod.post,
                '/api/wishes',
                as: ScenarioHarness.b,
                body: {'name': 'Other'},
              )
              .context,
        ),
      );
      final missing = await handleWishesCollection(
        app
            .context(
              HttpMethod.delete,
              '/api/wishes',
              body: {
                'ids': [ids[2], foreign['id']],
              },
            )
            .context,
      );
      expect(missing, isNotFound);
    });

    test('36. B cannot read, patch or delete A’s wish', () async {
      final created = await jsonMap(
        await handleWishesCollection(
          app
              .context(HttpMethod.post, '/api/wishes', body: {'name': 'Mine'})
              .context,
        ),
      );
      final id = '${created['id']}';

      final got = await handleWishById(
        app
            .context(
              HttpMethod.get,
              '/api/wishes/$id',
              as: ScenarioHarness.b,
            )
            .context,
        id,
      );
      expect(got, isForbidden);

      final patched = await handleWishById(
        app
            .context(
              HttpMethod.patch,
              '/api/wishes/$id',
              as: ScenarioHarness.b,
              body: {'name': 'X'},
            )
            .context,
        id,
      );
      expect(patched, isForbidden);

      final deleted = await handleWishById(
        app
            .context(
              HttpMethod.delete,
              '/api/wishes/$id',
              as: ScenarioHarness.b,
            )
            .context,
        id,
      );
      expect(deleted, isForbidden);

      final listed = await jsonList(
        await handleWishesCollection(
          app
              .context(
                HttpMethod.get,
                '/api/wishes',
                as: ScenarioHarness.b,
              )
              .context,
        ),
      );
      expect(listed, isEmpty);
    });
  });
}
