import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_test/dart_frog_test.dart';
import 'package:melist_backend/melist_backend.dart';

import 'memory_wishlists.dart';

/// Shared in-memory app for [docs/scenarios.md](docs/scenarios.md) tests.
class ScenarioHarness {
  ScenarioHarness() {
    data = MemoryWishlistData();
    wishlists = memoryWishlistService(data);
    wishes = memoryWishServiceFromLists(data);
    favorites = memoryFavoriteService(data);
    profiles = memoryProfileService(data);
    subscriptions = memorySubscriptionService(data);
  }

  static const a = AuthUser(
    id: 1,
    firstName: 'Ann',
    username: 'ann',
  );
  static const b = AuthUser(
    id: 2,
    firstName: 'Bob',
    username: 'bob',
  );
  static const config = AppConfig(
    botToken: 'token',
    jwtSecret: 'secret',
    databaseUrl: 'postgres://melist@localhost/melist',
  );

  late final MemoryWishlistData data;
  late final WishlistService wishlists;
  late final WishService wishes;
  late final FavoriteService favorites;
  late final ProfileService profiles;
  late final SubscriptionService subscriptions;

  TestRequestContext context(
    HttpMethod method,
    String path, {
    AuthUser as = a,
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
      ..provide<AuthUser>(as)
      ..provide<WishlistService>(wishlists)
      ..provide<WishService>(wishes)
      ..provide<FavoriteService>(favorites)
      ..provide<ProfileService>(profiles)
      ..provide<SubscriptionService>(subscriptions)
      ..provide<AppConfig>(config);
  }
}

Future<Map<String, dynamic>> jsonMap(Response response) async {
  return jsonDecode(await response.body()) as Map<String, dynamic>;
}

Future<List<dynamic>> jsonList(Response response) async {
  return jsonDecode(await response.body()) as List<dynamic>;
}

int idOf(Map<String, dynamic> body) => body['id'] as int;
