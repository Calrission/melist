import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_test/dart_frog_test.dart';
import 'package:melist_backend/src/profiles/profile_handlers.dart';
import 'package:melist_backend/src/subscriptions/subscription_handlers.dart';
import 'package:melist_backend/src/wishes/wish_handlers.dart';
import 'package:melist_backend/src/wishlists/wishlist_handlers.dart';
import 'package:test/test.dart';

import '../helpers/scenario_harness.dart';

void main() {
  late ScenarioHarness app;

  setUp(() {
    app = ScenarioHarness();
  });

  group('docs/scenarios.md wishlists', () {
    test('1. new wishes attached to a new wishlist', () async {
      final w1 = await handleWishesCollection(
        app
            .context(HttpMethod.post, '/api/wishes', body: {'name': 'Наушники'})
            .context,
      );
      final w2 = await handleWishesCollection(
        app
            .context(HttpMethod.post, '/api/wishes', body: {'name': 'Книга'})
            .context,
      );
      expect(w1, isCreated);
      expect(w2, isCreated);
      final w1Body = await jsonMap(w1);
      final w2Body = await jsonMap(w2);
      expect(w1Body['ownerId'], ScenarioHarness.a.id);
      expect(w2Body['ownerId'], ScenarioHarness.a.id);

      final created = await handleWishlistsCollection(
        app
            .context(
              HttpMethod.post,
              '/api/wishlists',
              body: {
                'name': 'День рождения',
                'visibility': 'public',
                'wishIds': [idOf(w1Body), idOf(w2Body)],
              },
            )
            .context,
      );
      expect(created, isCreated);
      final wl = await jsonMap(created);
      expect(wl['name'], 'День рождения');
      expect(wl['visibility'], 'public');

      final card = await handleWishlistById(
        app.context(HttpMethod.get, '/api/wishlists/${wl['id']}').context,
        '${wl['id']}',
      );
      expect(card, isOk);
      final items = (await jsonMap(card))['items'] as List<dynamic>;
      expect(items.map((item) => (item as Map)['id']), [
        idOf(w1Body),
        idOf(w2Body),
      ]);
    });

    test('2. new wishes appended to an existing wishlist', () async {
      final seed = await handleWishesCollection(
        app
            .context(HttpMethod.post, '/api/wishes', body: {'name': 'W1'})
            .context,
      );
      final w1 = idOf(await jsonMap(seed));
      final list = await handleWishlistsCollection(
        app
            .context(
              HttpMethod.post,
              '/api/wishlists',
              body: {
                'name': 'List',
                'visibility': 'public',
                'wishIds': [w1],
              },
            )
            .context,
      );
      final wl = idOf(await jsonMap(list));

      final camera = await handleWishlistWishes(
        app
            .context(
              HttpMethod.post,
              '/api/wishlists/$wl/wishes',
              body: {
                'wish': {'name': 'Камера'},
              },
            )
            .context,
        '$wl',
      );
      final watch = await handleWishlistWishes(
        app
            .context(
              HttpMethod.post,
              '/api/wishlists/$wl/wishes',
              body: {
                'wish': {'name': 'Часы'},
              },
            )
            .context,
        '$wl',
      );
      expect(camera, isCreated);
      expect(watch, isCreated);
      final cameraId = idOf(await jsonMap(camera));
      final watchId = idOf(await jsonMap(watch));
      expect(cameraId, isNot(w1));
      expect(watchId, isNot(w1));

      final card = await jsonMap(
        await handleWishlistById(
          app.context(HttpMethod.get, '/api/wishlists/$wl').context,
          '$wl',
        ),
      );
      expect(
        (card['items'] as List<dynamic>).map((item) => (item as Map)['name']),
        ['W1', 'Камера', 'Часы'],
      );
    });

    test(
      '3. B reads public wishes via profile and share, not owner card',
      () async {
        final list = await handleWishlistsCollection(
          app
              .context(
                HttpMethod.post,
                '/api/wishlists',
                body: {'name': 'Public', 'visibility': 'public'},
              )
              .context,
        );
        final wl = idOf(await jsonMap(list));
        await handleWishlistWishes(
          app
              .context(
                HttpMethod.post,
                '/api/wishlists/$wl/wishes',
                body: {
                  'wish': {'name': 'Наушники'},
                },
              )
              .context,
          '$wl',
        );
        final share = await jsonMap(
          await handleWishlistShare(
            app.context(HttpMethod.post, '/api/wishlists/$wl/share').context,
            '$wl',
          ),
        );
        final token = share['shareToken'] as String;

        final profile = await handlePublicUser(
          app
              .context(
                HttpMethod.get,
                '/api/users/${ScenarioHarness.a.id}',
                as: ScenarioHarness.b,
              )
              .context,
          '${ScenarioHarness.a.id}',
        );
        expect(profile, isOk);
        final lists = (await jsonMap(profile))['wishlists'] as List<dynamic>;
        expect(
          lists.map((item) => (item as Map)['id']),
          contains(wl),
        );

        final shared = await handleSharedWishlist(
          app
              .context(
                HttpMethod.get,
                '/api/shared/$token',
                as: ScenarioHarness.b,
              )
              .context,
          token,
        );
        expect(shared, isOk);
        final items = (await jsonMap(shared))['items'] as List<dynamic>;
        expect(
          items.map((item) => (item as Map)['name']),
          contains('Наушники'),
        );

        final card = await handleWishlistById(
          app
              .context(
                HttpMethod.get,
                '/api/wishlists/$wl',
                as: ScenarioHarness.b,
              )
              .context,
          '$wl',
        );
        expect(card, isForbidden);
      },
    );

    test('4. B cannot read a draft without a share link', () async {
      final list = await handleWishlistsCollection(
        app
            .context(
              HttpMethod.post,
              '/api/wishlists',
              body: {'name': 'Draft', 'visibility': 'draft'},
            )
            .context,
      );
      final wl = idOf(await jsonMap(list));
      await handleWishlistWishes(
        app
            .context(
              HttpMethod.post,
              '/api/wishlists/$wl/wishes',
              body: {
                'wish': {'name': 'Secret'},
              },
            )
            .context,
        '$wl',
      );

      final profile = await jsonMap(
        await handlePublicUser(
          app
              .context(
                HttpMethod.get,
                '/api/users/${ScenarioHarness.a.id}',
                as: ScenarioHarness.b,
              )
              .context,
          '${ScenarioHarness.a.id}',
        ),
      );
      expect(
        (profile['wishlists'] as List<dynamic>).map(
          (item) => (item as Map)['id'],
        ),
        isNot(contains(wl)),
      );

      final card = await handleWishlistById(
        app
            .context(
              HttpMethod.get,
              '/api/wishlists/$wl',
              as: ScenarioHarness.b,
            )
            .context,
        '$wl',
      );
      expect(card, isForbidden);

      final sub = await handleWishlistSubscriptions(
        app
            .context(
              HttpMethod.post,
              '/api/subscriptions/wishlists',
              as: ScenarioHarness.b,
              body: {'wishlistId': wl},
            )
            .context,
      );
      expect(sub, isNotFound);
      expect((await jsonMap(sub))['error'], 'Wishlist not found');
    });

    test('5. create wishlist name, visibility and cover', () async {
      final first = await handleWishlistsCollection(
        app
            .context(
              HttpMethod.post,
              '/api/wishlists',
              body: {
                'name': 'НГ',
                'visibility': 'draft',
                'coverUrl': 'https://example.com/c.png',
              },
            )
            .context,
      );
      expect(first, isCreated);
      final firstBody = await jsonMap(first);
      expect(firstBody['visibility'], 'draft');
      expect(firstBody['coverUrl'], 'https://example.com/c.png');

      final second = await jsonMap(
        await handleWishlistsCollection(
          app
              .context(
                HttpMethod.post,
                '/api/wishlists',
                body: {'name': 'НГ'},
              )
              .context,
        ),
      );
      expect(second['visibility'], 'draft');
      expect(second['coverUrl'], isNull);

      final bad = await handleWishlistsCollection(
        app
            .context(
              HttpMethod.post,
              '/api/wishlists',
              body: {'visibility': 'draft'},
            )
            .context,
      );
      expect(bad, isBadRequest);
      expect((await jsonMap(bad))['error'], 'name is required');
    });

    test('6. list own wishlists and open a card with items', () async {
      final first = await jsonMap(
        await handleWishlistsCollection(
          app
              .context(
                HttpMethod.post,
                '/api/wishlists',
                body: {'name': 'WL1'},
              )
              .context,
        ),
      );
      await handleWishlistsCollection(
        app
            .context(
              HttpMethod.post,
              '/api/wishlists',
              body: {'name': 'WL2'},
            )
            .context,
      );
      await handleWishlistWishes(
        app
            .context(
              HttpMethod.post,
              '/api/wishlists/${first['id']}/wishes',
              body: {
                'wish': {'name': 'Item'},
              },
            )
            .context,
        '${first['id']}',
      );

      final listed = await handleWishlistsCollection(
        app.context(HttpMethod.get, '/api/wishlists').context,
      );
      expect(listed, isOk);
      final lists = await jsonList(listed);
      expect(lists, hasLength(2));
      expect((lists.first as Map)['name'], 'WL1');
      expect(
        ((lists.first as Map)['items'] as List).single['name'],
        'Item',
      );
      expect((lists.last as Map)['items'], isEmpty);

      final card = await handleWishlistById(
        app.context(HttpMethod.get, '/api/wishlists/${first['id']}').context,
        '${first['id']}',
      );
      expect(card, isOk);
      expect((await jsonMap(card))['items'] as List<dynamic>, hasLength(1));
    });

    test('7. owner can patch a wishlist, stranger cannot', () async {
      final created = await jsonMap(
        await handleWishlistsCollection(
          app
              .context(
                HttpMethod.post,
                '/api/wishlists',
                body: {'name': 'Старое', 'visibility': 'draft'},
              )
              .context,
        ),
      );
      final wl = created['id'];

      final updated = await handleWishlistById(
        app
            .context(
              HttpMethod.patch,
              '/api/wishlists/$wl',
              body: {
                'name': 'Новое',
                'visibility': 'public',
                'coverUrl': 'https://example.com/c.png',
              },
            )
            .context,
        '$wl',
      );
      expect(updated, isOk);
      final body = await jsonMap(updated);
      expect(body['name'], 'Новое');
      expect(body['visibility'], 'public');
      expect(body['coverUrl'], 'https://example.com/c.png');

      final cleared = await handleWishlistById(
        app
            .context(
              HttpMethod.patch,
              '/api/wishlists/$wl',
              body: {'coverUrl': null},
            )
            .context,
        '$wl',
      );
      expect(cleared, isOk);
      final clearedBody = await jsonMap(cleared);
      expect(clearedBody['coverUrl'], isNull);
      expect(clearedBody['name'], 'Новое');

      final forbidden = await handleWishlistById(
        app
            .context(
              HttpMethod.patch,
              '/api/wishlists/$wl',
              as: ScenarioHarness.b,
              body: {'name': 'Hack'},
            )
            .context,
        '$wl',
      );
      expect(forbidden, isForbidden);

      final empty = await handleWishlistById(
        app
            .context(
              HttpMethod.patch,
              '/api/wishlists/$wl',
              body: <String, Object?>{},
            )
            .context,
        '$wl',
      );
      expect(empty, isBadRequest);
      expect((await jsonMap(empty))['error'], 'No fields to update');
    });

    test('8. attach an existing own wish without copying', () async {
      final wish = await jsonMap(
        await handleWishesCollection(
          app
              .context(HttpMethod.post, '/api/wishes', body: {'name': 'Book'})
              .context,
        ),
      );
      final list = await jsonMap(
        await handleWishlistsCollection(
          app
              .context(
                HttpMethod.post,
                '/api/wishlists',
                body: {'name': 'List'},
              )
              .context,
        ),
      );

      final attached = await handleWishlistWishes(
        app
            .context(
              HttpMethod.post,
              '/api/wishlists/${list['id']}/wishes',
              body: {'wishId': wish['id']},
            )
            .context,
        '${list['id']}',
      );
      expect(attached, isCreated);
      expect(idOf(await jsonMap(attached)), wish['id']);

      final card = await jsonMap(
        await handleWishlistById(
          app.context(HttpMethod.get, '/api/wishlists/${list['id']}').context,
          '${list['id']}',
        ),
      );
      expect(
        (card['items'] as List<dynamic>).map((item) => (item as Map)['id']),
        [wish['id']],
      );

      final catalog = await jsonList(
        await handleWishesCollection(
          app.context(HttpMethod.get, '/api/wishes').context,
        ),
      );
      expect(catalog, hasLength(1));
      expect((catalog.single as Map)['id'], wish['id']);
    });

    test('9. attaching the same wish twice conflicts', () async {
      final wish = await jsonMap(
        await handleWishesCollection(
          app
              .context(HttpMethod.post, '/api/wishes', body: {'name': 'Book'})
              .context,
        ),
      );
      final list = await jsonMap(
        await handleWishlistsCollection(
          app
              .context(
                HttpMethod.post,
                '/api/wishlists',
                body: {
                  'name': 'List',
                  'wishIds': [wish['id']],
                },
              )
              .context,
        ),
      );

      final again = await handleWishlistWishes(
        app
            .context(
              HttpMethod.post,
              '/api/wishlists/${list['id']}/wishes',
              body: {'wishId': wish['id']},
            )
            .context,
        '${list['id']}',
      );
      expect(again, hasStatus(HttpStatus.conflict));
      expect(
        (await jsonMap(again))['error'],
        'Wish is already in the wishlist',
      );
      expect(
        await jsonList(
          await handleWishesCollection(
            app.context(HttpMethod.get, '/api/wishes').context,
          ),
        ),
        hasLength(1),
      );
    });

    test('10. copy a foreign public wish onto own wishlist', () async {
      final bList = await jsonMap(
        await handleWishlistsCollection(
          app
              .context(
                HttpMethod.post,
                '/api/wishlists',
                as: ScenarioHarness.b,
                body: {'name': 'B list', 'visibility': 'public'},
              )
              .context,
        ),
      );
      final source = await jsonMap(
        await handleWishlistWishes(
          app
              .context(
                HttpMethod.post,
                '/api/wishlists/${bList['id']}/wishes',
                as: ScenarioHarness.b,
                body: {
                  'wish': {'name': 'Camera'},
                },
              )
              .context,
          '${bList['id']}',
        ),
      );
      final aList = await jsonMap(
        await handleWishlistsCollection(
          app
              .context(
                HttpMethod.post,
                '/api/wishlists',
                body: {'name': 'A list'},
              )
              .context,
        ),
      );

      final copied = await handleWishlistWishes(
        app
            .context(
              HttpMethod.post,
              '/api/wishlists/${aList['id']}/wishes',
              body: {'copyFromWishId': source['id']},
            )
            .context,
        '${aList['id']}',
      );
      expect(copied, isCreated);
      final copyBody = await jsonMap(copied);
      expect(copyBody['id'], isNot(source['id']));
      expect(copyBody['ownerId'], ScenarioHarness.a.id);
      expect(copyBody['copiedFrom'], source['id']);
      expect(copyBody['name'], 'Camera');

      final original = await handleWishById(
        app
            .context(
              HttpMethod.get,
              '/api/wishes/${source['id']}',
              as: ScenarioHarness.b,
            )
            .context,
        '${source['id']}',
      );
      expect(original, isOk);
      expect((await jsonMap(original))['name'], 'Camera');
    });

    test('11. cannot copy a foreign wish that is not public', () async {
      final source = await jsonMap(
        await handleWishesCollection(
          app
              .context(
                HttpMethod.post,
                '/api/wishes',
                as: ScenarioHarness.b,
                body: {'name': 'Secret'},
              )
              .context,
        ),
      );
      final aList = await jsonMap(
        await handleWishlistsCollection(
          app
              .context(
                HttpMethod.post,
                '/api/wishlists',
                body: {'name': 'A list'},
              )
              .context,
        ),
      );

      final response = await handleWishlistWishes(
        app
            .context(
              HttpMethod.post,
              '/api/wishlists/${aList['id']}/wishes',
              body: {'copyFromWishId': source['id']},
            )
            .context,
        '${aList['id']}',
      );
      expect(response, isForbidden);
      expect(
        await jsonList(
          await handleWishesCollection(
            app.context(HttpMethod.get, '/api/wishes').context,
          ),
        ),
        isEmpty,
      );
    });

    test('12. reorder own wishlists', () async {
      final ids = <int>[];
      for (final name in ['A', 'B', 'C']) {
        ids.add(
          idOf(
            await jsonMap(
              await handleWishlistsCollection(
                app
                    .context(
                      HttpMethod.post,
                      '/api/wishlists',
                      body: {'name': name},
                    )
                    .context,
              ),
            ),
          ),
        );
      }

      final patched = await handleWishlistsCollection(
        app
            .context(
              HttpMethod.patch,
              '/api/wishlists',
              body: {
                'order': [ids[2], ids[0], ids[1]],
              },
            )
            .context,
      );
      expect(patched.statusCode, HttpStatus.noContent);

      final listed = await jsonList(
        await handleWishlistsCollection(
          app.context(HttpMethod.get, '/api/wishlists').context,
        ),
      );
      expect(listed.map((item) => (item as Map)['id']), [
        ids[2],
        ids[0],
        ids[1],
      ]);

      final incomplete = await handleWishlistsCollection(
        app
            .context(
              HttpMethod.patch,
              '/api/wishlists',
              body: {
                'order': [ids[0], ids[1]],
              },
            )
            .context,
      );
      expect(incomplete, isBadRequest);
    });

    test('13. reorder wishes inside a wishlist', () async {
      final list = await jsonMap(
        await handleWishlistsCollection(
          app
              .context(
                HttpMethod.post,
                '/api/wishlists',
                body: {'name': 'List'},
              )
              .context,
        ),
      );
      final names = ['W1', 'W2', 'W3'];
      final wishIds = <int>[];
      for (final name in names) {
        wishIds.add(
          idOf(
            await jsonMap(
              await handleWishlistWishes(
                app
                    .context(
                      HttpMethod.post,
                      '/api/wishlists/${list['id']}/wishes',
                      body: {
                        'wish': {'name': name},
                      },
                    )
                    .context,
                '${list['id']}',
              ),
            ),
          ),
        );
      }

      final patched = await handleWishlistWishes(
        app
            .context(
              HttpMethod.patch,
              '/api/wishlists/${list['id']}/wishes',
              body: {
                'order': [wishIds[2], wishIds[0], wishIds[1]],
              },
            )
            .context,
        '${list['id']}',
      );
      expect(patched.statusCode, HttpStatus.noContent);

      final card = await jsonMap(
        await handleWishlistById(
          app.context(HttpMethod.get, '/api/wishlists/${list['id']}').context,
          '${list['id']}',
        ),
      );
      expect(
        (card['items'] as List<dynamic>).map((item) => (item as Map)['id']),
        [wishIds[2], wishIds[0], wishIds[1]],
      );

      final incomplete = await handleWishlistWishes(
        app
            .context(
              HttpMethod.patch,
              '/api/wishlists/${list['id']}/wishes',
              body: {
                'order': [wishIds[0]],
              },
            )
            .context,
        '${list['id']}',
      );
      expect(incomplete, isBadRequest);
    });

    test('14. detach wish from list but keep it in catalog', () async {
      final wish = await jsonMap(
        await handleWishesCollection(
          app
              .context(HttpMethod.post, '/api/wishes', body: {'name': 'Book'})
              .context,
        ),
      );
      final list = await jsonMap(
        await handleWishlistsCollection(
          app
              .context(
                HttpMethod.post,
                '/api/wishlists',
                body: {
                  'name': 'List',
                  'wishIds': [wish['id']],
                },
              )
              .context,
        ),
      );

      final deleted = await handleWishlistWishById(
        app
            .context(
              HttpMethod.delete,
              '/api/wishlists/${list['id']}/wishes/${wish['id']}',
            )
            .context,
        '${list['id']}',
        '${wish['id']}',
      );
      expect(deleted.statusCode, HttpStatus.noContent);

      final card = await jsonMap(
        await handleWishlistById(
          app.context(HttpMethod.get, '/api/wishlists/${list['id']}').context,
          '${list['id']}',
        ),
      );
      expect(card['items'], isEmpty);

      final stillThere = await handleWishById(
        app.context(HttpMethod.get, '/api/wishes/${wish['id']}').context,
        '${wish['id']}',
      );
      expect(stillThere, isOk);

      final again = await handleWishlistWishById(
        app
            .context(
              HttpMethod.delete,
              '/api/wishlists/${list['id']}/wishes/${wish['id']}',
            )
            .context,
        '${list['id']}',
        '${wish['id']}',
      );
      expect(again, isNotFound);
      expect((await jsonMap(again))['error'], 'Wish is not in the wishlist');
    });

    test('15. delete one wishlist, keep the wish, forbid stranger', () async {
      final wish = await jsonMap(
        await handleWishesCollection(
          app
              .context(HttpMethod.post, '/api/wishes', body: {'name': 'Book'})
              .context,
        ),
      );
      final list = await jsonMap(
        await handleWishlistsCollection(
          app
              .context(
                HttpMethod.post,
                '/api/wishlists',
                body: {
                  'name': 'List',
                  'wishIds': [wish['id']],
                },
              )
              .context,
        ),
      );

      final stranger = await handleWishlistById(
        app
            .context(
              HttpMethod.delete,
              '/api/wishlists/${list['id']}',
              as: ScenarioHarness.b,
            )
            .context,
        '${list['id']}',
      );
      expect(stranger, isForbidden);

      final deleted = await handleWishlistById(
        app.context(HttpMethod.delete, '/api/wishlists/${list['id']}').context,
        '${list['id']}',
      );
      expect(deleted.statusCode, HttpStatus.noContent);

      final missing = await handleWishlistById(
        app.context(HttpMethod.get, '/api/wishlists/${list['id']}').context,
        '${list['id']}',
      );
      expect(missing, isNotFound);

      final catalog = await handleWishById(
        app.context(HttpMethod.get, '/api/wishes/${wish['id']}').context,
        '${wish['id']}',
      );
      expect(catalog, isOk);
    });

    test('16. bulk-delete wishlists', () async {
      final ids = <int>[];
      for (final name in ['WL1', 'WL2', 'WL3']) {
        ids.add(
          idOf(
            await jsonMap(
              await handleWishlistsCollection(
                app
                    .context(
                      HttpMethod.post,
                      '/api/wishlists',
                      body: {'name': name},
                    )
                    .context,
              ),
            ),
          ),
        );
      }

      final deleted = await handleWishlistsCollection(
        app
            .context(
              HttpMethod.delete,
              '/api/wishlists',
              body: {
                'ids': [ids[0], ids[1]],
              },
            )
            .context,
      );
      expect(deleted.statusCode, HttpStatus.noContent);

      final listed = await jsonList(
        await handleWishlistsCollection(
          app.context(HttpMethod.get, '/api/wishlists').context,
        ),
      );
      expect(listed.map((item) => (item as Map)['id']), [ids[2]]);

      final empty = await handleWishlistsCollection(
        app
            .context(
              HttpMethod.delete,
              '/api/wishlists',
              body: {'ids': <int>[]},
            )
            .context,
      );
      expect(empty, isBadRequest);

      final missing = await handleWishlistsCollection(
        app
            .context(
              HttpMethod.delete,
              '/api/wishlists',
              body: {
                'ids': [ids[2], 999],
              },
            )
            .context,
      );
      expect(missing, isNotFound);
      expect(
        (await jsonMap(missing))['error'],
        'Some wishlists were not found',
      );
    });
  });
}
