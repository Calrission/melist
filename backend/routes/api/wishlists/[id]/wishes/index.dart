import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_swagger/dart_frog_swagger.dart';
import 'package:melist_backend/melist_backend.dart';
import 'package:melist_backend/src/wishlists/wishlist_handlers.dart';

@Route(
  method: HttpMethod.post,
  path: '/api/wishlists/{id}/wishes',
  summary: 'Add wish to wishlist',
  description:
      'Exactly one of: new wish payload (4.1), own existing '
      'wishId (4.2), copyFromWishId from another wishlist (4.3).',
  tags: ['Wishlists'],
  requestBody: ApiRequestBody(
    required: true,
    schema: {
      'type': 'object',
      'properties': {
        'wish': wishInputSchema,
        'wishId': {'type': 'integer'},
        'copyFromWishId': {'type': 'integer'},
      },
    },
    example: {'wishId': 10},
  ),
  responses: [
    ApiResponse(
      statusCode: 201,
      description: 'Wish that was added to the wishlist.',
      schema: wishSchema,
    ),
    badRequestResponse,
    forbiddenResponse,
    notFoundResponse,
    conflictResponse,
    unauthorizedResponse,
    methodNotAllowedResponse,
  ],
)
@Route(
  method: HttpMethod.patch,
  path: '/api/wishlists/{id}/wishes',
  summary: 'Reorder wishes inside wishlist',
  description: 'Full list of wish ids in the new order. (5.2)',
  tags: ['Wishlists'],
  requestBody: orderRequestBody,
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
  return handleWishlistWishes(context, id);
}
