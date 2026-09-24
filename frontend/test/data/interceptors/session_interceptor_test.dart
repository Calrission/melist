import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:melist/data/auth/auth_session.dart';
import 'package:melist/data/interceptors/session_interceptor.dart';

void main() {
  late AuthSession session;
  late Dio dio;
  late _ScriptedAdapter adapter;
  late int refreshCalls;

  setUp(() {
    session = AuthSession();
    refreshCalls = 0;
    adapter = _ScriptedAdapter();
    dio = Dio(BaseOptions(baseUrl: 'http://localhost:8080'));
    dio.httpClientAdapter = adapter;
    dio.interceptors.add(
      SessionInterceptor(
        session: session,
        dio: dio,
        refresh: () async {
          refreshCalls += 1;
          session.setAccessToken('refreshed');
        },
      ),
    );
  });

  test('adds a Bearer header from memory', () async {
    session.setAccessToken('access');
    adapter.enqueue(_json(200, {'ok': true}));

    await dio.get('/api/me');

    expect(
      adapter.requests.single.headers['Authorization'],
      'Bearer access',
    );
  });

  test('does not attach Bearer to auth cookie routes', () async {
    session.setAccessToken('access');
    adapter.enqueue(_json(200, {'accessToken': 'x'}));

    await dio.post('/auth/refresh');

    expect(
      adapter.requests.single.headers['Authorization'],
      isNull,
    );
  });

  test('refreshes once and retries a 401', () async {
    session.setAccessToken('stale');
    adapter.enqueue(_json(401, {'error': 'Unauthorized'}));
    adapter.enqueue(_json(200, {'id': 1}));

    final response = await dio.get('/api/me');

    expect(refreshCalls, 1);
    expect(response.statusCode, 200);
    expect(adapter.requests, hasLength(2));
    expect(
      adapter.requests.last.headers['Authorization'],
      'Bearer refreshed',
    );
  });

  test('does not refresh a 401 from /auth/refresh', () async {
    adapter.enqueue(_json(401, {'error': 'Invalid refresh token'}));

    await expectLater(dio.post('/auth/refresh'), throwsA(isA<DioException>()));
    expect(refreshCalls, 0);
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
