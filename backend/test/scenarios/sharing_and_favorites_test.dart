import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_test/dart_frog_test.dart';
import 'package:melist_backend/melist_backend.dart';
import 'package:melist_backend/src/favorites/favorite_handlers.dart';
import 'package:melist_backend/src/wishlists/wishlist_handlers.dart';
import 'package:test/test.dart';

import '../helpers/scenario_harness.dart';

void main() {
  late ScenarioHarness app;

  setUp(() {
    app = ScenarioHarness();
  });

  Future<({int wl, String token})> sharedList({
    String name = 'Birthday',
    String visibility = 'link',
    AuthUser as = ScenarioHarness.a,
  }) async {
    final list = await jsonMap(
      await handleWishlistsCollection(
        app
            .context(
              HttpMethod.post,
              '/api/wishlists',
              as: as,
              body: {'name': name, 'visibility': visibility},
            )
            .context,
      ),
    );
    final share = await jsonMap(
      await handleWishlistShare(
        app
            .context(
              HttpMethod.post,
              '/api/wishlists/${list['id']}/share',
              as: as,
            )
            .context,
        '${list['id']}',
      ),
    );
    return (wl: idOf(list), token: share['shareToken'] as String);
  }

  group('docs/scenarios.md sharing', () {
    test('17. share token is stable and forbidden for stranger', () async {
      final list = await jsonMap(
        await handleWishlistsCollection(
          app
              .context(
                HttpMethod.post,
                '/api/wishlists',
                body: {'name': 'Draft', 'visibility': 'draft'},
              )
              .context,
        ),
      );
      final first = await jsonMap(
        await handleWishlistShare(
          app
              .context(
                HttpMethod.post,
                '/api/wishlists/${list['id']}/share',
              )
              .context,
          '${list['id']}',
        ),
      );
      final second = await jsonMap(
        await handleWishlistShare(
          app
              .context(
                HttpMethod.post,
                '/api/wishlists/${list['id']}/share',
              )
              .context,
          '${list['id']}',
        ),
      );
      expect(first['shareToken'], isNotEmpty);
      expect(first['shareToken'], second['shareToken']);
      expect(
        first['url'],
        'https://t.me/melist_bot/app?startapp=wl_${first['shareToken']}',
      );

      final forbidden = await handleWishlistShare(
        app
            .context(
              HttpMethod.post,
              '/api/wishlists/${list['id']}/share',
              as: ScenarioHarness.b,
            )
            .context,
        '${list['id']}',
      );
      expect(forbidden, isForbidden);
    });

    test('18. Telegram share is client-only; URL comes from 17', () async {
      final shared = await sharedList();
      expect(shared.token, isNotEmpty);
    });

    test('19. B opens a link wishlist by token and wl_ prefix', () async {
      final shared = await sharedList();

      for (final token in [shared.token, 'wl_${shared.token}']) {
        final response = await handleSharedWishlist(
          app
              .context(
                HttpMethod.get,
                '/api/shared/$token',
                as: ScenarioHarness.b,
              )
              .context,
          token,
        );
        expect(response, isOk);
        expect((await jsonMap(response))['id'], shared.wl);
      }

      final missing = await handleSharedWishlist(
        app
            .context(
              HttpMethod.get,
              '/api/shared/missing',
              as: ScenarioHarness.b,
            )
            .context,
        'missing',
      );
      expect(missing, isNotFound);
      expect((await jsonMap(missing))['error'], 'Wishlist not found');

      final draft = await sharedList(name: 'Draft', visibility: 'draft');
      final hidden = await handleSharedWishlist(
        app
            .context(
              HttpMethod.get,
              '/api/shared/${draft.token}',
              as: ScenarioHarness.b,
            )
            .context,
        draft.token,
      );
      expect(hidden, isNotFound);
    });

    test('20. shared view shows every wish', () async {
      final shared = await sharedList(visibility: 'public');
      await handleWishlistWishes(
        app
            .context(
              HttpMethod.post,
              '/api/wishlists/${shared.wl}/wishes',
              body: {
                'wish': {'name': 'Public'},
              },
            )
            .context,
        '${shared.wl}',
      );
      await handleWishlistWishes(
        app
            .context(
              HttpMethod.post,
              '/api/wishlists/${shared.wl}/wishes',
              body: {
                'wish': {'name': 'Second'},
              },
            )
            .context,
        '${shared.wl}',
      );

      final asB = await jsonMap(
        await handleSharedWishlist(
          app
              .context(
                HttpMethod.get,
                '/api/shared/${shared.token}',
                as: ScenarioHarness.b,
              )
              .context,
          shared.token,
        ),
      );
      expect(
        (asB['items'] as List<dynamic>).map((item) => (item as Map)['name']),
        ['Public', 'Second'],
      );

      final asA = await jsonMap(
        await handleSharedWishlist(
          app
              .context(
                HttpMethod.get,
                '/api/shared/${shared.token}',
              )
              .context,
          shared.token,
        ),
      );
      expect(
        (asA['items'] as List<dynamic>).map((item) => (item as Map)['name']),
        ['Public', 'Second'],
      );
    });
  });

  group('docs/scenarios.md favorites', () {
    test('21. B favorites A by token and wl_ prefix', () async {
      final shared = await sharedList();
      for (final token in [shared.token, 'wl_${shared.token}']) {
        if (token.startsWith('wl_')) {
          await handleFavoriteByWishlistId(
            app
                .context(
                  HttpMethod.delete,
                  '/api/favorites/${shared.wl}',
                  as: ScenarioHarness.b,
                )
                .context,
            '${shared.wl}',
          );
        }
        final added = await handleFavoritesCollection(
          app
              .context(
                HttpMethod.post,
                '/api/favorites',
                as: ScenarioHarness.b,
                body: {'shareToken': token},
              )
              .context,
        );
        expect(added, isCreated);
        expect(idOf(await jsonMap(added)), shared.wl);
      }
    });

    test('22. favorites list keeps add order', () async {
      final first = await sharedList(name: 'WL1');
      final second = await sharedList(name: 'WL2');
      await handleFavoritesCollection(
        app
            .context(
              HttpMethod.post,
              '/api/favorites',
              as: ScenarioHarness.b,
              body: {'shareToken': first.token},
            )
            .context,
      );
      await handleFavoritesCollection(
        app
            .context(
              HttpMethod.post,
              '/api/favorites',
              as: ScenarioHarness.b,
              body: {'shareToken': second.token},
            )
            .context,
      );

      final listed = await handleFavoritesCollection(
        app
            .context(
              HttpMethod.get,
              '/api/favorites',
              as: ScenarioHarness.b,
            )
            .context,
      );
      expect(listed, isOk);
      expect(
        (await jsonList(listed)).map((item) => (item as Map)['id']),
        [first.wl, second.wl],
      );
    });

    test('23. favorites show every wish', () async {
      final shared = await sharedList(visibility: 'public');
      await handleWishlistWishes(
        app
            .context(
              HttpMethod.post,
              '/api/wishlists/${shared.wl}/wishes',
              body: {
                'wish': {'name': 'Public'},
              },
            )
            .context,
        '${shared.wl}',
      );
      await handleWishlistWishes(
        app
            .context(
              HttpMethod.post,
              '/api/wishlists/${shared.wl}/wishes',
              body: {
                'wish': {'name': 'Second'},
              },
            )
            .context,
        '${shared.wl}',
      );
      await handleFavoritesCollection(
        app
            .context(
              HttpMethod.post,
              '/api/favorites',
              as: ScenarioHarness.b,
              body: {'shareToken': shared.token},
            )
            .context,
      );

      final listed = await jsonList(
        await handleFavoritesCollection(
          app
              .context(
                HttpMethod.get,
                '/api/favorites',
                as: ScenarioHarness.b,
              )
              .context,
        ),
      );
      final items = (listed.single as Map)['items'] as List<dynamic>;
      expect(items.map((item) => (item as Map)['name']), ['Public', 'Second']);
    });

    test('24. reorder favorites', () async {
      final first = await sharedList(name: 'WL1');
      final second = await sharedList(name: 'WL2');
      await handleFavoritesCollection(
        app
            .context(
              HttpMethod.post,
              '/api/favorites',
              as: ScenarioHarness.b,
              body: {'shareToken': first.token},
            )
            .context,
      );
      await handleFavoritesCollection(
        app
            .context(
              HttpMethod.post,
              '/api/favorites',
              as: ScenarioHarness.b,
              body: {'shareToken': second.token},
            )
            .context,
      );

      final patched = await handleFavoritesCollection(
        app
            .context(
              HttpMethod.patch,
              '/api/favorites',
              as: ScenarioHarness.b,
              body: {
                'order': [second.wl, first.wl],
              },
            )
            .context,
      );
      expect(patched.statusCode, HttpStatus.noContent);

      final listed = await jsonList(
        await handleFavoritesCollection(
          app
              .context(
                HttpMethod.get,
                '/api/favorites',
                as: ScenarioHarness.b,
              )
              .context,
        ),
      );
      expect(listed.map((item) => (item as Map)['id']), [
        second.wl,
        first.wl,
      ]);

      final incomplete = await handleFavoritesCollection(
        app
            .context(
              HttpMethod.patch,
              '/api/favorites',
              as: ScenarioHarness.b,
              body: {
                'order': [first.wl],
              },
            )
            .context,
      );
      expect(incomplete, isBadRequest);
    });

    test('25. unfavorite does not delete the wishlist', () async {
      final shared = await sharedList();
      await handleFavoritesCollection(
        app
            .context(
              HttpMethod.post,
              '/api/favorites',
              as: ScenarioHarness.b,
              body: {'shareToken': shared.token},
            )
            .context,
      );

      final removed = await handleFavoriteByWishlistId(
        app
            .context(
              HttpMethod.delete,
              '/api/favorites/${shared.wl}',
              as: ScenarioHarness.b,
            )
            .context,
        '${shared.wl}',
      );
      expect(removed.statusCode, HttpStatus.noContent);

      final card = await handleWishlistById(
        app.context(HttpMethod.get, '/api/wishlists/${shared.wl}').context,
        '${shared.wl}',
      );
      expect(card, isOk);

      final listed = await jsonList(
        await handleFavoritesCollection(
          app
              .context(
                HttpMethod.get,
                '/api/favorites',
                as: ScenarioHarness.b,
              )
              .context,
        ),
      );
      expect(listed, isEmpty);

      final again = await handleFavoriteByWishlistId(
        app
            .context(
              HttpMethod.delete,
              '/api/favorites/${shared.wl}',
              as: ScenarioHarness.b,
            )
            .context,
        '${shared.wl}',
      );
      expect(again, isNotFound);
      expect((await jsonMap(again))['error'], 'Wishlist is not in favorites');
    });

    test('26. cannot favorite own wishlist', () async {
      final shared = await sharedList();
      final response = await handleFavoritesCollection(
        app
            .context(
              HttpMethod.post,
              '/api/favorites',
              body: {'shareToken': shared.token},
            )
            .context,
      );
      expect(response, isBadRequest);
      expect(
        (await jsonMap(response))['error'],
        'Cannot favorite your own wishlist',
      );
    });

    test('27. duplicate favorite conflicts', () async {
      final shared = await sharedList();
      await handleFavoritesCollection(
        app
            .context(
              HttpMethod.post,
              '/api/favorites',
              as: ScenarioHarness.b,
              body: {'shareToken': shared.token},
            )
            .context,
      );
      final again = await handleFavoritesCollection(
        app
            .context(
              HttpMethod.post,
              '/api/favorites',
              as: ScenarioHarness.b,
              body: {'shareToken': shared.token},
            )
            .context,
      );
      expect(again, hasStatus(HttpStatus.conflict));
      expect(
        (await jsonMap(again))['error'],
        'Wishlist is already in favorites',
      );
    });
  });
}
