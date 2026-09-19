import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_swagger/dart_frog_swagger.dart';
import 'package:melist_backend/melist_backend.dart';

@Route(
  method: HttpMethod.get,
  path: '/api/favorites',
  summary: 'List favorite wishlists',
  description: "Other users' wishlists saved by the current user. (9)",
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
    ...protectedStubResponses,
  ],
)
@Route(
  method: HttpMethod.post,
  path: '/api/favorites',
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
    ...protectedStubResponses,
  ],
)
@Route(
  method: HttpMethod.patch,
  path: '/api/favorites',
  summary: 'Reorder favorites',
  description: 'Full list of wishlist ids in the new order. (10)',
  tags: ['Favorites'],
  requestBody: orderRequestBody,
  responses: [
    noContentResponse,
    badRequestResponse,
    ...protectedStubResponses,
  ],
)
Future<Response> onRequest(RequestContext context) async {
  final rejected = rejectUnlessMethod(
    context,
    {HttpMethod.get, HttpMethod.post, HttpMethod.patch},
  );
  if (rejected != null) {
    return rejected;
  }

  context.read<AuthUser>();
  return notImplemented();
}
