import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:melist_backend/src/auth/auth_session_service.dart';
import 'package:melist_backend/src/auth/init_data_validator.dart';
import 'package:melist_backend/src/auth/refresh_cookie.dart';
import 'package:melist_backend/src/data/user_repository.dart';
import 'package:melist_backend/src/http/app_exception.dart';
import 'package:melist_backend/src/http/responses.dart';

Future<Response> authenticateWithInitData({
  required Request request,
  required InitDataValidator validator,
  required UserRepository users,
  required AuthSessionService sessions,
  required bool cookieSecure,
}) async {
  final initData = await _readInitData(request);
  if (initData == null) {
    return badRequest('initData is required');
  }

  switch (validator.validate(initData)) {
    case InitDataFailure(:final reason):
      return unauthorized(
        switch (reason) {
          InitDataFailureReason.expired => 'Expired initData',
          InitDataFailureReason.invalid => 'Invalid initData',
        },
      );
    case InitDataSuccess(:final user):
      await users.upsertTelegram(user);
      final issued = await sessions.issue(user);
      return authSessionResponse(issued, cookieSecure: cookieSecure);
  }
}

Future<Response> refreshAccessToken({
  required Request request,
  required AuthSessionService sessions,
  required bool cookieSecure,
}) async {
  final raw = RefreshCookie.read(request);
  if (raw == null) {
    return _invalidRefresh(cookieSecure: cookieSecure);
  }

  try {
    final issued = await sessions.rotate(raw);
    return authSessionResponse(issued, cookieSecure: cookieSecure);
  } on UnauthorizedException {
    return _invalidRefresh(cookieSecure: cookieSecure);
  }
}

Future<Response> logoutSession({
  required Request request,
  required AuthSessionService sessions,
  required bool cookieSecure,
}) async {
  await sessions.revoke(RefreshCookie.read(request));
  return Response(
    statusCode: HttpStatus.noContent,
    headers: {
      HttpHeaders.setCookieHeader: RefreshCookie.clear(secure: cookieSecure),
    },
  );
}

Response authSessionResponse(
  IssuedAuthSession issued, {
  required bool cookieSecure,
}) {
  return Response.json(
    body: issued.session.toJson(),
    headers: {
      HttpHeaders.setCookieHeader: RefreshCookie.set(
        token: issued.refreshToken,
        maxAge: issued.refreshTtl,
        secure: cookieSecure,
      ),
    },
  );
}

Response _invalidRefresh({required bool cookieSecure}) {
  return errorResponse(
    HttpStatus.unauthorized,
    'Invalid refresh token',
    headers: {
      HttpHeaders.setCookieHeader: RefreshCookie.clear(secure: cookieSecure),
    },
  );
}

Future<String?> _readInitData(Request request) async {
  try {
    final body = await request.json();
    if (body is! Map<String, dynamic>) {
      return null;
    }

    final initData = body['initData'];
    if (initData is! String || initData.isEmpty) {
      return null;
    }

    return initData;
  } on Object {
    return null;
  }
}
