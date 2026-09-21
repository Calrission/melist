import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_swagger/dart_frog_swagger.dart';
import 'package:melist_backend/melist_backend.dart';
import 'package:melist_backend/src/subscriptions/subscription_handlers.dart';

@Route(
  method: HttpMethod.get,
  path: '/api/subscriptions/wishlists',
  summary: 'List wishlist subscriptions',
  description: 'Wishlists the current user follows. (31)',
  tags: ['Subscriptions'],
  responses: [
    ApiResponse(
      statusCode: 200,
      description: 'Followed public wishlists, newest first.',
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
  path: '/api/subscriptions/wishlists',
  summary: 'Subscribe to wishlist',
  description: 'Start following changes of a public wishlist. (30)',
  tags: ['Subscriptions'],
  requestBody: ApiRequestBody(
    required: true,
    schema: {
      'type': 'object',
      'properties': {
        'wishlistId': {'type': 'integer'},
      },
      'required': ['wishlistId'],
    },
    example: {'wishlistId': 1},
  ),
  responses: [
    ApiResponse(
      statusCode: 201,
      description: 'Subscribed wishlist.',
      schema: wishlistSchema,
    ),
    badRequestResponse,
    notFoundResponse,
    conflictResponse,
    unauthorizedResponse,
    methodNotAllowedResponse,
  ],
)
Future<Response> onRequest(RequestContext context) {
  return handleWishlistSubscriptions(context);
}
