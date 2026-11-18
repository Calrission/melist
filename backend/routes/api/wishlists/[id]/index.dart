import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_swagger/dart_frog_swagger.dart';
import 'package:melist_backend/melist_backend.dart';
import 'package:melist_backend/src/wishlists/wishlist_handlers.dart';

@Route(
  method: HttpMethod.get,
  path: '/api/wishlists/{id}',
  summary: 'Wishlist details',
  description: 'Wishlist with its wishes ordered by position. (2.2)',
  tags: ['Wishlists'],
  responses: [
    ApiResponse(
      statusCode: 200,
      description: 'Wishlist.',
      schema: wishlistSchema,
    ),
    forbiddenResponse,
    notFoundResponse,
    unauthorizedResponse,
    methodNotAllowedResponse,
  ],
)
@Route(
  method: HttpMethod.patch,
  path: '/api/wishlists/{id}',
  summary: 'Edit wishlist',
  description: 'Change name or visibility. (3)',
  tags: ['Wishlists'],
  requestBody: ApiRequestBody(
    required: true,
    schema: {
      'type': 'object',
      'properties': {
        'name': {'type': 'string'},
        'description': {'type': 'string'},
        'visibility': {
          'type': 'string',
          'enum': ['public', 'draft', 'link'],
        },
      },
    },
    example: {'name': 'New year', 'visibility': 'draft'},
  ),
  responses: [
    ApiResponse(
      statusCode: 200,
      description: 'Updated wishlist.',
      schema: wishlistSchema,
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
  path: '/api/wishlists/{id}',
  summary: 'Delete wishlist',
  description: 'Delete a single own wishlist. (6.1)',
  tags: ['Wishlists'],
  responses: [
    noContentResponse,
    forbiddenResponse,
    notFoundResponse,
    unauthorizedResponse,
    methodNotAllowedResponse,
  ],
)
Future<Response> onRequest(RequestContext context, String id) {
  return handleWishlistById(context, id);
}
