import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_swagger/dart_frog_swagger.dart';
import 'package:melist_backend/melist_backend.dart';
import 'package:melist_backend/src/wishlists/wishlist_handlers.dart';

@Route(
  method: HttpMethod.get,
  path: '/api/wishlists',
  summary: 'List own wishlists',
  description: 'All wishlists of the current user ordered by position. (2.1)',
  tags: ['Wishlists'],
  responses: [
    ApiResponse(
      statusCode: 200,
      description: 'Wishlists.',
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
  path: '/api/wishlists',
  summary: 'Create wishlist',
  description: 'Name, visibility, color and optional existing wishes. (1)',
  tags: ['Wishlists'],
  requestBody: ApiRequestBody(
    required: true,
    schema: wishlistInputSchema,
    example: {
      'name': 'Birthday',
      'visibility': 'public',
      'color': '#FFB74D',
      'wishIds': [1, 2],
    },
  ),
  responses: [
    ApiResponse(
      statusCode: 201,
      description: 'Created wishlist.',
      schema: wishlistSchema,
    ),
    badRequestResponse,
    unauthorizedResponse,
    methodNotAllowedResponse,
  ],
)
@Route(
  method: HttpMethod.patch,
  path: '/api/wishlists',
  summary: 'Reorder wishlists',
  description: 'Full list of wishlist ids in the new order. (5.1)',
  tags: ['Wishlists'],
  requestBody: orderRequestBody,
  responses: [
    noContentResponse,
    badRequestResponse,
    ...protectedStubResponses,
  ],
)
@Route(
  method: HttpMethod.delete,
  path: '/api/wishlists',
  summary: 'Bulk delete wishlists',
  description: 'Delete several own wishlists at once. (6.2)',
  tags: ['Wishlists'],
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
  return handleWishlistsCollection(context);
}
