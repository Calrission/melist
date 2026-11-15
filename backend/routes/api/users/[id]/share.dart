import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_swagger/dart_frog_swagger.dart';
import 'package:melist_backend/melist_backend.dart';
import 'package:melist_backend/src/profiles/profile_handlers.dart';

@Route(
  method: HttpMethod.get,
  path: '/api/users/{id}/share',
  summary: 'Get public profile share link',
  description: 'Returns a Telegram Mini App deep link to the public profile.',
  tags: ['Profile'],
  responses: [
    ApiResponse(
      statusCode: 200,
      description: 'Telegram Mini App profile link.',
      schema: {
        'type': 'object',
        'properties': {
          'url': {'type': 'string'},
        },
        'required': ['url'],
      },
    ),
    badRequestResponse,
    notFoundResponse,
    unauthorizedResponse,
    methodNotAllowedResponse,
  ],
)
Future<Response> onRequest(RequestContext context, String id) {
  return handleProfileShare(context, id);
}
