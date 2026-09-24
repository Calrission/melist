import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_test/dart_frog_test.dart';
import 'package:melist_backend/melist_backend.dart';
import 'package:melist_backend/src/profiles/profile_handlers.dart';
import 'package:melist_backend/src/subscriptions/subscription_handlers.dart';
import 'package:melist_backend/src/wishlists/wishlist_handlers.dart';
import 'package:melist_core/melist_core.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../../routes/api/_middleware.dart' as api;
import '../../routes/auth/refresh.dart' as refresh;
import '../../routes/auth/validate.dart' as validate;
import '../helpers/init_data.dart';
import '../helpers/memory_refresh_tokens.dart';
import '../helpers/memory_wishlists.dart';
import '../helpers/scenario_harness.dart';

class _MockRequestContext extends Mock implements RequestContext {}

void main() {
  late ScenarioHarness app;

  setUpAll(() {
    registerFallbackValue(() => const AuthUser(id: 0));
  });

  setUp(() {
    app = ScenarioHarness();
  });

  group('docs/scenarios.md profile', () {
    test('37. validate then GET /api/me; missing Bearer is 401', () async {
      final now = DateTime.utc(2026, 9, 19, 8, 13);
      final validator = InitDataValidator(
        botToken: testBotToken,
        clock: () => now,
      );
      const jwtService = JwtService(secret: 'test-secret');
      final users = MemoryUserRepository(app.data);
      final tokens = MemoryRefreshTokenRepository();
      final sessions = memoryAuthSessionService(
        jwtService: jwtService,
        users: users,
        tokens: tokens,
      );

      final authContext = _MockRequestContext();
      when(() => authContext.request).thenReturn(
        Request.post(
          Uri.parse('http://localhost/auth/validate'),
          headers: {HttpHeaders.contentTypeHeader: 'application/json'},
          body: jsonEncode({
            'initData': signInitData(authDate: unixSeconds(now)),
          }),
        ),
      );
      when(() => authContext.read<InitDataValidator>()).thenReturn(validator);
      when(() => authContext.read<UserRepository>()).thenReturn(users);
      when(() => authContext.read<AuthSessionService>()).thenReturn(sessions);
      when(
        () => authContext.read<AppConfig>(),
      ).thenReturn(ScenarioHarness.config);

      final issued = await validate.onRequest(authContext);
      expect(issued, isOk);
      final issuedBody = await jsonMap(issued);
      final issuedUser = issuedBody['user'] as Map<String, dynamic>;
      expect(issuedUser['firstName'], 'Vladislav');
      expect(
        issuedUser['avatarUrl'],
        'https://t.me/i/userpic/320/test.svg',
      );

      final jwtUser = AuthUser.fromJwt(
        jwtService.verify(issuedBody['accessToken'] as String),
      )!;
      final me = await handleMe(
        app.context(HttpMethod.get, '/api/me', as: jwtUser).context,
      );
      expect(me, isOk);
      final meBody = await jsonMap(me);
      expect(meBody['id'], 279058397);
      expect(meBody['firstName'], 'Vladislav');
      expect(meBody['avatarUrl'], 'https://t.me/i/userpic/320/test.svg');
      expect(meBody['theme'], 'system');

      final mwContext = _MockRequestContext();
      when(() => mwContext.request).thenReturn(
        Request.get(Uri.parse('http://localhost/api/me')),
      );
      when(() => mwContext.read<JwtService>()).thenReturn(jwtService);
      when(() => mwContext.read<DebugAuth>()).thenReturn(
        const DebugAuth.disabled(),
      );
      when(() => mwContext.provide<AuthUser>(any())).thenReturn(mwContext);
      final unauthorized = await api.middleware((_) => Response(body: 'ok'))(
        mwContext,
      );
      expect(unauthorized.statusCode, HttpStatus.unauthorized);
    });

    test('37b. silent refresh rotates the cookie; reuse is 401', () async {
      const jwtService = JwtService(secret: 'test-secret');
      final users = MemoryUserRepository(app.data);
      final tokens = MemoryRefreshTokenRepository();
      final sessions = memoryAuthSessionService(
        jwtService: jwtService,
        users: users,
        tokens: tokens,
      );
      await users.upsertTelegram(
        const UserModel(id: 1, firstName: 'Ann', username: 'ann'),
      );
      final issued = await sessions.issue(
        const UserModel(id: 1, firstName: 'Ann', username: 'ann'),
      );

      RequestContext refreshContext(String? cookie) {
        final context = _MockRequestContext();
        when(() => context.request).thenReturn(
          Request.post(
            Uri.parse('http://localhost/auth/refresh'),
            headers: {
              if (cookie != null) HttpHeaders.cookieHeader: cookie,
            },
          ),
        );
        when(() => context.read<AuthSessionService>()).thenReturn(sessions);
        when(
          () => context.read<AppConfig>(),
        ).thenReturn(ScenarioHarness.config);
        return context;
      }

      final first = await refresh.onRequest(
        refreshContext('${RefreshCookie.name}=${issued.refreshToken}'),
      );
      expect(first, isOk);
      final firstBody = await jsonMap(first);
      expect(firstBody['accessToken'], isA<String>());
      expect(firstBody.containsKey('refreshToken'), isFalse);

      final reused = await refresh.onRequest(
        refreshContext('${RefreshCookie.name}=${issued.refreshToken}'),
      );
      expect(reused.statusCode, HttpStatus.unauthorized);

      final missing = await refresh.onRequest(refreshContext(null));
      expect(missing.statusCode, HttpStatus.unauthorized);
    });

    test('38. set, change and clear birthday', () async {
      Future<Response> patch(Object? birthday) {
        return handleMe(
          app
              .context(
                HttpMethod.patch,
                '/api/me',
                body: {'birthday': birthday},
              )
              .context,
        );
      }

      final first = await patch('1990-05-12');
      expect(first, isOk);
      expect((await jsonMap(first))['birthday'], '1990-05-12');

      final second = await patch('1991-01-01');
      expect((await jsonMap(second))['birthday'], '1991-01-01');

      final cleared = await patch(null);
      expect(cleared, isOk);
      expect((await jsonMap(cleared))['birthday'], isNull);

      final invalid = await patch('12-05-1990');
      expect(invalid, isBadRequest);
    });

    test('39. switch theme; reject unknown and empty patch', () async {
      for (final theme in ['dark', 'light', 'system']) {
        final patched = await handleMe(
          app
              .context(
                HttpMethod.patch,
                '/api/me',
                body: {'theme': theme},
              )
              .context,
        );
        expect(patched, isOk);
        expect((await jsonMap(patched))['theme'], theme);
      }

      final neon = await handleMe(
        app
            .context(
              HttpMethod.patch,
              '/api/me',
              body: {'theme': 'neon'},
            )
            .context,
      );
      expect(neon, isBadRequest);
      expect(
        (await jsonMap(neon))['error'],
        'theme must be system, light or dark',
      );

      final empty = await handleMe(
        app
            .context(
              HttpMethod.patch,
              '/api/me',
              body: <String, Object?>{},
            )
            .context,
      );
      expect(empty, isBadRequest);
      expect((await jsonMap(empty))['error'], 'No fields to update');
    });

    test('40. public profile lists only public wishlists', () async {
      final pub = await jsonMap(
        await handleWishlistsCollection(
          app
              .context(
                HttpMethod.post,
                '/api/wishlists',
                body: {'name': 'Public', 'visibility': 'public'},
              )
              .context,
        ),
      );
      final draft = await jsonMap(
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
      final body = await jsonMap(profile);
      final publicUser = body['user'] as Map<String, dynamic>;
      expect(publicUser['id'], ScenarioHarness.a.id);
      final ids = (body['wishlists'] as List<dynamic>).map(
        (item) => (item as Map)['id'],
      );
      expect(ids, contains(pub['id']));
      expect(ids, isNot(contains(draft['id'])));

      final missing = await handlePublicUser(
        app
            .context(
              HttpMethod.get,
              '/api/users/404',
              as: ScenarioHarness.b,
            )
            .context,
        '404',
      );
      expect(missing, isNotFound);
      expect((await jsonMap(missing))['error'], 'User not found');

      final invalid = await handlePublicUser(
        app
            .context(
              HttpMethod.get,
              '/api/users/abc',
              as: ScenarioHarness.b,
            )
            .context,
        'abc',
      );
      expect(invalid, isBadRequest);
    });

    test('41. turning a list into a draft hides it on the profile', () async {
      final pub = await jsonMap(
        await handleWishlistsCollection(
          app
              .context(
                HttpMethod.post,
                '/api/wishlists',
                body: {'name': 'Public', 'visibility': 'public'},
              )
              .context,
        ),
      );
      await handleWishlistById(
        app
            .context(
              HttpMethod.patch,
              '/api/wishlists/${pub['id']}',
              body: {'visibility': 'draft'},
            )
            .context,
        '${pub['id']}',
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
        isNot(contains(pub['id'])),
      );
    });
  });

  group('docs/scenarios.md subscriptions', () {
    test('42. subscribe to a public wishlist', () async {
      final list = await jsonMap(
        await handleWishlistsCollection(
          app
              .context(
                HttpMethod.post,
                '/api/wishlists',
                body: {'name': 'Public', 'visibility': 'public'},
              )
              .context,
        ),
      );

      final created = await handleWishlistSubscriptions(
        app
            .context(
              HttpMethod.post,
              '/api/subscriptions/wishlists',
              as: ScenarioHarness.b,
              body: {'wishlistId': list['id']},
            )
            .context,
      );
      expect(created, isCreated);
      expect(idOf(await jsonMap(created)), list['id']);

      final listed = await handleWishlistSubscriptions(
        app
            .context(
              HttpMethod.get,
              '/api/subscriptions/wishlists',
              as: ScenarioHarness.b,
            )
            .context,
      );
      expect(listed, isOk);
      expect(
        ((await jsonList(listed)).first as Map)['id'],
        list['id'],
      );

      final missing = await handleWishlistSubscriptions(
        app
            .context(
              HttpMethod.post,
              '/api/subscriptions/wishlists',
              as: ScenarioHarness.b,
              body: <String, Object?>{},
            )
            .context,
      );
      expect(missing, isBadRequest);
    });

    test('43. cannot subscribe to a draft', () async {
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

      final response = await handleWishlistSubscriptions(
        app
            .context(
              HttpMethod.post,
              '/api/subscriptions/wishlists',
              as: ScenarioHarness.b,
              body: {'wishlistId': list['id']},
            )
            .context,
      );
      expect(response, isNotFound);
      expect((await jsonMap(response))['error'], 'Wishlist not found');
      expect(
        await jsonList(
          await handleWishlistSubscriptions(
            app
                .context(
                  HttpMethod.get,
                  '/api/subscriptions/wishlists',
                  as: ScenarioHarness.b,
                )
                .context,
          ),
        ),
        isEmpty,
      );
    });

    test('44. unsubscribe from a wishlist', () async {
      final list = await jsonMap(
        await handleWishlistsCollection(
          app
              .context(
                HttpMethod.post,
                '/api/wishlists',
                body: {'name': 'Public', 'visibility': 'public'},
              )
              .context,
        ),
      );
      await handleWishlistSubscriptions(
        app
            .context(
              HttpMethod.post,
              '/api/subscriptions/wishlists',
              as: ScenarioHarness.b,
              body: {'wishlistId': list['id']},
            )
            .context,
      );

      final deleted = await handleWishlistUnsubscribe(
        app
            .context(
              HttpMethod.delete,
              '/api/subscriptions/wishlists/${list['id']}',
              as: ScenarioHarness.b,
            )
            .context,
        '${list['id']}',
      );
      expect(deleted.statusCode, HttpStatus.noContent);
      expect(
        await jsonList(
          await handleWishlistSubscriptions(
            app
                .context(
                  HttpMethod.get,
                  '/api/subscriptions/wishlists',
                  as: ScenarioHarness.b,
                )
                .context,
          ),
        ),
        isEmpty,
      );

      final again = await handleWishlistUnsubscribe(
        app
            .context(
              HttpMethod.delete,
              '/api/subscriptions/wishlists/${list['id']}',
              as: ScenarioHarness.b,
            )
            .context,
        '${list['id']}',
      );
      expect(again, isNotFound);
      expect(
        (await jsonMap(again))['error'],
        'Wishlist subscription not found',
      );
    });

    test('45. subscribe to a profile', () async {
      await handleWishlistsCollection(
        app
            .context(
              HttpMethod.post,
              '/api/wishlists',
              body: {'name': 'Mine'},
            )
            .context,
      );

      final created = await handleUserSubscriptions(
        app
            .context(
              HttpMethod.post,
              '/api/subscriptions/users',
              as: ScenarioHarness.b,
              body: {'userId': ScenarioHarness.a.id},
            )
            .context,
      );
      expect(created, isCreated);
      expect(idOf(await jsonMap(created)), ScenarioHarness.a.id);

      final listed = await jsonList(
        await handleUserSubscriptions(
          app
              .context(
                HttpMethod.get,
                '/api/subscriptions/users',
                as: ScenarioHarness.b,
              )
              .context,
        ),
      );
      expect((listed.first as Map)['id'], ScenarioHarness.a.id);

      final missingField = await handleUserSubscriptions(
        app
            .context(
              HttpMethod.post,
              '/api/subscriptions/users',
              as: ScenarioHarness.b,
              body: <String, Object?>{},
            )
            .context,
      );
      expect(missingField, isBadRequest);

      final missingUser = await handleUserSubscriptions(
        app
            .context(
              HttpMethod.post,
              '/api/subscriptions/users',
              as: ScenarioHarness.b,
              body: {'userId': 404},
            )
            .context,
      );
      expect(missingUser, isNotFound);
      expect((await jsonMap(missingUser))['error'], 'User not found');
    });

    test('46. unsubscribe from a profile', () async {
      await handleWishlistsCollection(
        app
            .context(
              HttpMethod.post,
              '/api/wishlists',
              body: {'name': 'Mine'},
            )
            .context,
      );
      await handleUserSubscriptions(
        app
            .context(
              HttpMethod.post,
              '/api/subscriptions/users',
              as: ScenarioHarness.b,
              body: {'userId': ScenarioHarness.a.id},
            )
            .context,
      );

      final deleted = await handleUserUnsubscribe(
        app
            .context(
              HttpMethod.delete,
              '/api/subscriptions/users/${ScenarioHarness.a.id}',
              as: ScenarioHarness.b,
            )
            .context,
        '${ScenarioHarness.a.id}',
      );
      expect(deleted.statusCode, HttpStatus.noContent);

      final again = await handleUserUnsubscribe(
        app
            .context(
              HttpMethod.delete,
              '/api/subscriptions/users/${ScenarioHarness.a.id}',
              as: ScenarioHarness.b,
            )
            .context,
        '${ScenarioHarness.a.id}',
      );
      expect(again, isNotFound);
      expect((await jsonMap(again))['error'], 'User subscription not found');
    });

    test('47. cannot subscribe to own wishlist or profile', () async {
      final list = await jsonMap(
        await handleWishlistsCollection(
          app
              .context(
                HttpMethod.post,
                '/api/wishlists',
                body: {'name': 'Public', 'visibility': 'public'},
              )
              .context,
        ),
      );

      final ownList = await handleWishlistSubscriptions(
        app
            .context(
              HttpMethod.post,
              '/api/subscriptions/wishlists',
              body: {'wishlistId': list['id']},
            )
            .context,
      );
      expect(ownList, isBadRequest);
      expect(
        (await jsonMap(ownList))['error'],
        'Cannot subscribe to your own wishlist',
      );

      final ownUser = await handleUserSubscriptions(
        app
            .context(
              HttpMethod.post,
              '/api/subscriptions/users',
              body: {'userId': ScenarioHarness.a.id},
            )
            .context,
      );
      expect(ownUser, isBadRequest);
      expect(
        (await jsonMap(ownUser))['error'],
        'Cannot subscribe to yourself',
      );
    });

    test('48. duplicate subscription conflicts', () async {
      final list = await jsonMap(
        await handleWishlistsCollection(
          app
              .context(
                HttpMethod.post,
                '/api/wishlists',
                body: {'name': 'Public', 'visibility': 'public'},
              )
              .context,
        ),
      );
      await handleWishlistSubscriptions(
        app
            .context(
              HttpMethod.post,
              '/api/subscriptions/wishlists',
              as: ScenarioHarness.b,
              body: {'wishlistId': list['id']},
            )
            .context,
      );
      await handleUserSubscriptions(
        app
            .context(
              HttpMethod.post,
              '/api/subscriptions/users',
              as: ScenarioHarness.b,
              body: {'userId': ScenarioHarness.a.id},
            )
            .context,
      );

      final listAgain = await handleWishlistSubscriptions(
        app
            .context(
              HttpMethod.post,
              '/api/subscriptions/wishlists',
              as: ScenarioHarness.b,
              body: {'wishlistId': list['id']},
            )
            .context,
      );
      expect(listAgain, hasStatus(HttpStatus.conflict));
      expect(
        (await jsonMap(listAgain))['error'],
        'Already subscribed to this wishlist',
      );

      final userAgain = await handleUserSubscriptions(
        app
            .context(
              HttpMethod.post,
              '/api/subscriptions/users',
              as: ScenarioHarness.b,
              body: {'userId': ScenarioHarness.a.id},
            )
            .context,
      );
      expect(userAgain, hasStatus(HttpStatus.conflict));
      expect(
        (await jsonMap(userAgain))['error'],
        'Already subscribed to this user',
      );
    });

    test('49. draft wishlist disappears from subscription list', () async {
      final list = await jsonMap(
        await handleWishlistsCollection(
          app
              .context(
                HttpMethod.post,
                '/api/wishlists',
                body: {'name': 'Public', 'visibility': 'public'},
              )
              .context,
        ),
      );
      await handleWishlistSubscriptions(
        app
            .context(
              HttpMethod.post,
              '/api/subscriptions/wishlists',
              as: ScenarioHarness.b,
              body: {'wishlistId': list['id']},
            )
            .context,
      );

      await handleWishlistById(
        app
            .context(
              HttpMethod.patch,
              '/api/wishlists/${list['id']}',
              body: {'visibility': 'draft'},
            )
            .context,
        '${list['id']}',
      );

      final listed = await jsonList(
        await handleWishlistSubscriptions(
          app
              .context(
                HttpMethod.get,
                '/api/subscriptions/wishlists',
                as: ScenarioHarness.b,
              )
              .context,
        ),
      );
      expect(listed, isEmpty);

      final deleted = await handleWishlistUnsubscribe(
        app
            .context(
              HttpMethod.delete,
              '/api/subscriptions/wishlists/${list['id']}',
              as: ScenarioHarness.b,
            )
            .context,
        '${list['id']}',
      );
      expect(deleted.statusCode, HttpStatus.noContent);
    });
  });
}
