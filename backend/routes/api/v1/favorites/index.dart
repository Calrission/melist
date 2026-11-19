import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_swagger/dart_frog_swagger.dart';
import 'package:melist_backend/melist_backend.dart';
import 'package:melist_backend/src/favorites/favorite_handlers.dart';

@Route(
  method: HttpMethod.get,
  path: '/api/v1/favorites',
  summary: 'List favorite wishlists',
  description:
      "Other users' wishlists saved by the current user. "
      'Each item includes ownerNickname. (9)',
  tags: ['Favorites'],
  responses: [
    ApiResponse(
      statusCode: 200,
      description: 'Favorite wishlists ordered by position.',
      schema: {
        'type': 'array',
        'items': wishlistSchema,
      },
    ),
    unauthorizedResponse,
    methodNotAllowedResponse,
  ],
)
@Route(
  method: HttpMethod.post,
  path: '/api/v1/favorites',
  summary: 'Add wishlist to favorites',
  description: 'Adds a wishlist by its share token. (8.1)',
  tags: ['Favorites'],
  requestBody: ApiRequestBody(
    required: true,
    schema: {
      'type': 'object',
      'properties': {
        'shareToken': {'type': 'string'},
      },
      'required': ['shareToken'],
    },
    example: {'shareToken': 'k3Jd9s'},
  ),
  responses: [
    ApiResponse(
      statusCode: 201,
      description: 'Added wishlist.',
      schema: wishlistSchema,
    ),
    badRequestResponse,
    notFoundResponse,
    conflictResponse,
    unauthorizedResponse,
    methodNotAllowedResponse,
  ],
)
@Route(
  method: HttpMethod.patch,
  path: '/api/v1/favorites',
  summary: 'Reorder favorites',
  description: 'Full list of wishlist ids in the new order. (10)',
  tags: ['Favorites'],
  requestBody: orderRequestBody,
  responses: [
    noContentResponse,
    badRequestResponse,
    unauthorizedResponse,
    methodNotAllowedResponse,
  ],
)
Future<Response> onRequest(RequestContext context) {
  return handleFavoritesCollection(context);
}
