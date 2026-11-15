import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:melist/data/repository/api_repository.dart';
import 'package:melist_core/melist_core.dart';

void main() {
  late Dio dio;
  late _ScriptedAdapter adapter;
  late ApiRepository auth;

  setUp(() {
    adapter = _ScriptedAdapter();
    dio = Dio(BaseOptions(baseUrl: 'http://localhost:8080'));
    dio.httpClientAdapter = adapter;
    auth = ApiRepository(dio: dio);
  });

  test('login returns the access token from JSON', () async {
    adapter.enqueue(
      _json(200, {
        'accessToken': 'jwt',
        'tokenType': 'Bearer',
        'expiresIn': 900,
        'user': {'id': 1, 'firstName': 'Ann'},
      }),
    );

    final issued = await auth.login(const AuthValidateBody(initData: 'raw'));

    expect(issued.accessToken, 'jwt');
    expect(adapter.requests.single.path, '/auth/validate');
  });

  test('refresh hits /auth/refresh', () async {
    adapter.enqueue(
      _json(200, {
        'accessToken': 'new-jwt',
        'tokenType': 'Bearer',
        'expiresIn': 900,
        'user': {'id': 1},
      }),
    );

    final issued = await auth.refresh();

    expect(issued.accessToken, 'new-jwt');
    expect(adapter.requests.single.path, '/auth/refresh');
  });

  test('logout posts /auth/logout and rethrows failures', () async {
    adapter.enqueue(_json(500, {'error': 'boom'}));

    await expectLater(auth.logout(), throwsA(isA<DioException>()));
    expect(adapter.requests.single.path, '/auth/logout');
  });

  test('loginDebug parses a bearer without expiresIn', () async {
    adapter.enqueue(
      _json(200, {
        'accessToken': 'dev-admin',
        'tokenType': 'Bearer',
        'user': {'id': 1, 'firstName': 'Debug', 'username': 'debug_admin'},
      }),
    );

    final issued = await auth.loginDebug();

    expect(issued.accessToken, 'dev-admin');
    expect(adapter.requests.single.path, '/auth/debug');
  });

  test('profile share URL uses the Telegram endpoint', () async {
    adapter.enqueue(
      _json(200, {'url': 'https://t.me/test_bot?startapp=profile_42'}),
    );

    final url = await auth.getProfileShareUrl(42);

    expect(url, 'https://t.me/test_bot?startapp=profile_42');
    expect(adapter.requests.single.path, '/api/users/42/share');
  });

  test('favorites, wishes and subscriptions hit their routes', () async {
    adapter
      ..enqueue(_json(201, _wishlist))
      ..enqueue(_json(200, [_wishlist]))
      ..enqueue(_json(204, {}))
      ..enqueue(_json(204, {}))
      ..enqueue(_json(201, _wish))
      ..enqueue(_json(201, _wish))
      ..enqueue(_json(200, [_wish]))
      ..enqueue(_json(200, _wish))
      ..enqueue(_json(200, _wish))
      ..enqueue(_json(204, {}))
      ..enqueue(_json(204, {}))
      ..enqueue(_json(201, _wish))
      ..enqueue(_json(204, {}))
      ..enqueue(_json(201, {'id': 2}))
      ..enqueue(_json(201, _wishlist))
      ..enqueue(
        _json(200, [
          {'id': 2},
        ]),
      )
      ..enqueue(_json(200, [_wishlist]))
      ..enqueue(_json(204, {}))
      ..enqueue(_json(204, {}));

    await auth.addWishlistToFavorites(const AddFavoriteBody(shareToken: 'k3'));
    await auth.getMyFavoriteWishlists();
    await auth.reorderFavorites(const ReorderIdsBody(order: [1]));
    await auth.deleteFavoriteById(1);
    await auth.createWish(const CreateWishBody(name: 'Headphones'));
    await auth.duplicateWishById(10);
    await auth.getMyWishes();
    await auth.getMyWishById(10);
    await auth.patchWishById(10, const PatchWishBody(name: 'Cans'));
    await auth.deleteBulkWishesByIds([10]);
    await auth.deleteWishById(10);
    await auth.addWishToWishlist(4, const AddWishlistWishBody.attach(10));
    await auth.reorderWishesInWishlist(4, const ReorderIdsBody(order: [10]));
    await auth.subscribeToProfile(const SubscribeUserBody(userId: 2));
    await auth.subscribeToWishlist(const SubscribeWishlistBody(wishlistId: 1));
    await auth.getMyProfileSubscriptions();
    await auth.getMyWishlistSubscriptions();
    await auth.unsubscribeProfile(2);
    await auth.unsubscribeWishlist(1);

    expect(
      adapter.requests.map((request) => '${request.method} ${request.path}'),
      [
        'POST /api/favorites',
        'GET /api/favorites',
        'PATCH /api/favorites',
        'DELETE /api/favorites/1',
        'POST /api/wishes',
        'POST /api/wishes/10/duplicate',
        'GET /api/wishes',
        'GET /api/wishes/10',
        'PATCH /api/wishes/10',
        'DELETE /api/wishes',
        'DELETE /api/wishes/10',
        'POST /api/wishlists/4/wishes',
        'PATCH /api/wishlists/4/wishes',
        'POST /api/subscriptions/users',
        'POST /api/subscriptions/wishlists',
        'GET /api/subscriptions/users',
        'GET /api/subscriptions/wishlists',
        'DELETE /api/subscriptions/users/2',
        'DELETE /api/subscriptions/wishlists/1',
      ],
    );
    expect(adapter.requests[6].queryParameters, {'mine': 'true'});
    expect(adapter.requests[11].data, {'wishId': 10});
  });
}

const _wishlist = {'id': 1, 'ownerId': 1, 'name': 'Gifts', 'color': '#fff'};

const _wish = {'id': 10, 'ownerId': 1, 'name': 'Headphones'};

ResponseBody _json(int status, Object? body) {
  return ResponseBody.fromString(
    jsonEncode(body),
    status,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
}

class _ScriptedAdapter implements HttpClientAdapter {
  final List<RequestOptions> requests = [];
  final List<ResponseBody> _responses = [];

  void enqueue(ResponseBody response) => _responses.add(response);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    if (_responses.isEmpty) {
      throw StateError('No scripted response for ${options.uri}');
    }
    return _responses.removeAt(0);
  }

  @override
  void close({bool force = false}) {}
}
