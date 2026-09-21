import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_swagger/dart_frog_swagger.dart';
import 'package:melist_backend/melist_backend.dart';
import 'package:melist_backend/src/profiles/profile_handlers.dart';

@Route(
  method: HttpMethod.get,
  path: '/api/me',
  summary: 'Current user profile',
  description: 'Telegram profile data plus settings (birthday, theme). (22)',
  tags: ['Profile'],
  responses: [
    ApiResponse(
      statusCode: 200,
      description: 'Profile.',
      schema: userSchema,
    ),
    unauthorizedResponse,
    methodNotAllowedResponse,
  ],
)
@Route(
  method: HttpMethod.patch,
  path: '/api/me',
  summary: 'Update profile settings',
  description: 'Set or change birthday and UI theme. (23, 26)',
  tags: ['Profile'],
  requestBody: ApiRequestBody(
    required: true,
    schema: {
      'type': 'object',
      'properties': {
        'birthday': {'type': 'string', 'format': 'date', 'nullable': true},
        'theme': {
          'type': 'string',
          'enum': ['system', 'light', 'dark'],
        },
      },
    },
    example: {'birthday': '1990-05-12', 'theme': 'dark'},
  ),
  responses: [
    ApiResponse(
      statusCode: 200,
      description: 'Updated profile.',
      schema: userSchema,
    ),
    badRequestResponse,
    unauthorizedResponse,
    methodNotAllowedResponse,
  ],
)
Future<Response> onRequest(RequestContext context) {
  return handleMe(context);
}
