import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_swagger/dart_frog_swagger.dart';
import 'package:melist_backend/melist_backend.dart';
import 'package:melist_backend/src/openapi/auth_docs.dart';

@Route(
  method: HttpMethod.post,
  path: '/auth/validate',
  summary: 'Issue a JWT from Telegram initData',
  description:
      'Validates Mini App initData HMAC and returns an access token.',
  tags: ['Auth'],
  requestBody: initDataRequestBody,
  responses: authInitDataResponses,
)
Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  return authenticateWithInitData(
    request: context.request,
    validator: context.read<InitDataValidator>(),
    jwtService: context.read<JwtService>(),
  );
}
