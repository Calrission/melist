import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_swagger/dart_frog_swagger.dart';
import 'package:melist_backend/melist_backend.dart';

@Route(
  method: HttpMethod.get,
  path: '/api/subscriptions/wishlists',
  summary: 'List wishlist subscriptions',
  description: 'Wishlists the current user follows. (31)',
  tags: ['Subscriptions'],
  responses: [
    ApiResponse(
      statusCode: 200,
      description: 'Followed wishlists.',
      schema: {
        'type': 'array',
        'items': wishlistSchema,
      },
    ),
    ...protectedStubResponses,
  ],
)
@Route(
  method: HttpMethod.post,
  path: '/api/subscriptions/wishlists',
  summary: 'Subscribe to wishlist',
  description: 'Start following changes of a wishlist. (30)',
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
    ApiResponse(statusCode: 201, description: 'Subscribed.'),
    badRequestResponse,
    notFoundResponse,
    ...protectedStubResponses,
  ],
)
Future<Response> onRequest(RequestContext context) async {
  final rejected = rejectUnlessMethod(
    context,
    {HttpMethod.get, HttpMethod.post},
  );
  if (rejected != null) {
    return rejected;
  }

  context.read<AuthUser>();
  return notImplemented();
}
