import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_swagger/dart_frog_swagger.dart';
import 'package:melist_backend/melist_backend.dart';
import 'package:melist_backend/src/openapi/auth_docs.dart';

@Route(
  method: HttpMethod.get,
  path: '/auth/debug',
  summary: 'Return the local debug Bearer token',
  description:
      'Available only when DEBUG_AUTH=true. Use the token as '
      '`Authorization: Bearer <accessToken>` on `/api/**`.',
  tags: ['Auth'],
  responses: debugAuthResponses,
)
Future<Response> onRequest(RequestContext context) async {
  final rejected = rejectUnlessMethod(context, {HttpMethod.get});
  if (rejected != null) {
    return rejected;
  }

  final payload = context.read<DebugAuth>().tokenPayload();
  if (payload == null) {
    return notFound('Debug auth is disabled');
  }
  return Response.json(body: payload);
}
