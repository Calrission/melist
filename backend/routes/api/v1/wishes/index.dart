import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_swagger/dart_frog_swagger.dart';
import 'package:melist_backend/melist_backend.dart';
import 'package:melist_backend/src/wishes/wish_handlers.dart';

@Route(
  method: HttpMethod.get,
  path: '/api/v1/wishes',
  summary: 'List and search wishes',
  description:
      'Own wishes. Query params: query (name search, 17.1), '
      'mine=true (17.2), limit, offset. (16)',
  tags: ['Wishes'],
  responses: [
    ApiResponse(
      statusCode: 200,
      description: 'Wishes.',
      schema: {
        'type': 'array',
        'items': wishSchema,
      },
    ),
    badRequestResponse,
    unauthorizedResponse,
    methodNotAllowedResponse,
  ],
)
@Route(
  method: HttpMethod.post,
  path: '/api/v1/wishes',
  summary: 'Create wish',
  description: 'Only name is required. (12)',
  tags: ['Wishes'],
  requestBody: ApiRequestBody(
    required: true,
    schema: wishInputSchema,
    example: {
      'name': 'Headphones',
      'price': 12000,
      'url': 'https://example.com/item',
      'status': 'free',
    },
  ),
  responses: [
    ApiResponse(
      statusCode: 201,
      description: 'Created wish.',
      schema: wishSchema,
    ),
    badRequestResponse,
    unauthorizedResponse,
    methodNotAllowedResponse,
  ],
)
@Route(
  method: HttpMethod.delete,
  path: '/api/v1/wishes',
  summary: 'Bulk delete wishes',
  description: 'Delete several own wishes at once. (21.2)',
  tags: ['Wishes'],
  requestBody: idsRequestBody,
  responses: [
    noContentResponse,
    badRequestResponse,
    notFoundResponse,
    unauthorizedResponse,
    methodNotAllowedResponse,
  ],
)
Future<Response> onRequest(RequestContext context) {
  return handleWishesCollection(context);
}
