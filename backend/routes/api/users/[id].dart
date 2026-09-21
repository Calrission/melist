import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_swagger/dart_frog_swagger.dart';
import 'package:melist_backend/melist_backend.dart';
import 'package:melist_backend/src/profiles/profile_handlers.dart';

@Route(
  method: HttpMethod.get,
  path: '/api/users/{id}',
  summary: 'Public profile of another user',
  description: 'Profile data and public wishlists of the given user. (25)',
  tags: ['Profile'],
  responses: [
    ApiResponse(
      statusCode: 200,
      description: 'Public profile.',
      schema: {
        'type': 'object',
        'properties': {
          'user': userSchema,
          'wishlists': {
            'type': 'array',
            'items': wishlistSchema,
          },
        },
      },
    ),
    badRequestResponse,
    notFoundResponse,
    unauthorizedResponse,
    methodNotAllowedResponse,
  ],
)
Future<Response> onRequest(RequestContext context, String id) {
  return handlePublicUser(context, id);
}
