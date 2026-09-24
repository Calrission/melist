import 'dart:async';

import 'package:dio/dio.dart';
import 'package:melist/data/auth/auth_session.dart';

const _retryExtra = 'authRetry';

/// Attaches the in-memory access JWT and silently refreshes it on 401.
///
/// `/auth/*` is left alone: refresh/logout/validate use the HttpOnly cookie
/// and must not trigger another refresh.
class SessionInterceptor extends Interceptor {
  SessionInterceptor({required this.session, required this.dio});

  final AuthSession session;
  final Dio dio;

  Completer<void>? _refreshing;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (!isAuthSessionPath(options.path)) {
      final token = session.accessToken;
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (!_shouldRefresh(err)) {
      handler.next(err);
      return;
    }

    try {
      await _refreshOnce();
      final options = err.requestOptions;
      options.extra[_retryExtra] = true;
      final response = await dio.fetch(options);
      handler.resolve(response);
    } on DioException catch (refreshError) {
      handler.next(refreshError);
    } on Object {
      handler.next(err);
    }
  }

  bool _shouldRefresh(DioException err) {
    if (err.response?.statusCode != 401) {
      return false;
    }
    if (err.requestOptions.extra[_retryExtra] == true) {
      return false;
    }
    return !isAuthSessionPath(err.requestOptions.path);
  }

  Future<void> _refreshOnce() {
    final inFlight = _refreshing;
    if (inFlight != null) {
      return inFlight.future;
    }

    final next = Completer<void>();
    _refreshing = next;
    () async {
      try {
        await session.refresh();
        next.complete();
      } on Object catch (error, stack) {
        next.completeError(error, stack);
      } finally {
        if (identical(_refreshing, next)) {
          _refreshing = null;
        }
      }
    }();
    return next.future;
  }
}

bool isAuthSessionPath(String path) {
  final normalized = path.contains('://') ? Uri.parse(path).path : path;
  return normalized.endsWith('/auth/refresh') ||
      normalized.endsWith('/auth/logout') ||
      normalized.endsWith('/auth/validate') ||
      normalized.endsWith('/auth/debug');
}
