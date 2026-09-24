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
}

ResponseBody _json(int status, Map<String, Object?> body) {
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
