import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_swagger/dart_frog_swagger.dart';
import 'package:melist_backend/melist_backend.dart';
import 'package:melist_backend/src/profiles/profile_handlers.dart';

@Route(
  method: HttpMethod.get,
  path: '/api/v1/users/{id}',
  summary: 'Public profile of another user',
  description:
      'Profile and wishlists the viewer may see: every public list, '
      'plus link-only lists they keep in favorites. Drafts are omitted. (25)',
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
