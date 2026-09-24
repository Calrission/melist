import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_swagger/dart_frog_swagger.dart';
import 'package:melist_backend/melist_backend.dart';
import 'package:melist_backend/src/openapi/auth_docs.dart';

@Route(
  method: HttpMethod.post,
  path: '/auth/refresh',
  summary: 'Issue a new access token from the refresh cookie',
  description:
      'Reads the HttpOnly refresh_token cookie, rotates it, and returns '
      'a new access JWT. The cookie is never present in the JSON body.',
  tags: ['Auth'],
  responses: authRefreshResponses,
)
Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  final config = context.read<AppConfig>();
  return refreshAccessToken(
    request: context.request,
    sessions: context.read<AuthSessionService>(),
    cookieSecure: config.cookieSecure,
  );
}
