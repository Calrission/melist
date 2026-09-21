import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_swagger/dart_frog_swagger.dart';
import 'package:melist_backend/melist_backend.dart';
import 'package:melist_backend/src/wishes/wish_handlers.dart';

@Route(
  method: HttpMethod.get,
  path: '/api/wishes/{id}',
  summary: 'Wish details',
  description: 'Single own wish.',
  tags: ['Wishes'],
  responses: [
    ApiResponse(
      statusCode: 200,
      description: 'Wish.',
      schema: wishSchema,
    ),
    badRequestResponse,
    forbiddenResponse,
    notFoundResponse,
    unauthorizedResponse,
    methodNotAllowedResponse,
  ],
)
@Route(
  method: HttpMethod.patch,
  path: '/api/wishes/{id}',
  summary: 'Edit wish',
  description: 'Any wish field, including status (20). (18)',
  tags: ['Wishes'],
  requestBody: ApiRequestBody(
    required: true,
    schema: wishInputSchema,
    example: {'status': 'reserved'},
  ),
  responses: [
    ApiResponse(
      statusCode: 200,
      description: 'Updated wish.',
      schema: wishSchema,
    ),
    badRequestResponse,
    forbiddenResponse,
    notFoundResponse,
    unauthorizedResponse,
    methodNotAllowedResponse,
  ],
)
@Route(
  method: HttpMethod.delete,
  path: '/api/wishes/{id}',
  summary: 'Delete wish',
  description: 'Delete a single own wish. (21.1)',
  tags: ['Wishes'],
  responses: [
    noContentResponse,
    badRequestResponse,
    forbiddenResponse,
    notFoundResponse,
    unauthorizedResponse,
    methodNotAllowedResponse,
  ],
)
Future<Response> onRequest(RequestContext context, String id) {
  return handleWishById(context, id);
}
