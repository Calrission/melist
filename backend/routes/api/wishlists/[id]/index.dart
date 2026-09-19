import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_swagger/dart_frog_swagger.dart';
import 'package:melist_backend/melist_backend.dart';

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
    ...protectedStubResponses,
  ],
)
@Route(
  method: HttpMethod.patch,
  path: '/api/wishlists/{id}',
  summary: 'Edit wishlist',
  description: 'Change name, visibility or color. (3)',
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
          'enum': ['public', 'draft'],
        },
        'color': {'type': 'string'},
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
    ...protectedStubResponses,
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
    ...protectedStubResponses,
  ],
)
Future<Response> onRequest(RequestContext context, String id) async {
  final rejected = rejectUnlessMethod(
    context,
    {HttpMethod.get, HttpMethod.patch, HttpMethod.delete},
  );
  if (rejected != null) {
    return rejected;
  }

  context.read<AuthUser>();
  return notImplemented();
}
