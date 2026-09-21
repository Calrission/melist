import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_swagger/dart_frog_swagger.dart';
import 'package:melist_backend/melist_backend.dart';
import 'package:melist_backend/src/wishes/wish_handlers.dart';

@Route(
  method: HttpMethod.post,
  path: '/api/wishes/{id}/duplicate',
  summary: 'Duplicate wish',
  description: 'Creates a copy of an own wish. (13)',
  tags: ['Wishes'],
  responses: [
    ApiResponse(
      statusCode: 201,
      description: 'The new copy.',
      schema: wishSchema,
    ),
    badRequestResponse,
    forbiddenResponse,
    notFoundResponse,
    unauthorizedResponse,
    methodNotAllowedResponse,
  ],
)
Future<Response> onRequest(RequestContext context, String id) {
  return handleWishDuplicate(context, id);
}
