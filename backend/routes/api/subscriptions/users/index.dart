import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_swagger/dart_frog_swagger.dart';
import 'package:melist_backend/melist_backend.dart';

@Route(
  method: HttpMethod.get,
  path: '/api/subscriptions/users',
  summary: 'List profile subscriptions',
  description: 'Users the current user follows. (34)',
  tags: ['Subscriptions'],
  responses: [
    ApiResponse(
      statusCode: 200,
      description: 'Followed users.',
      schema: {
        'type': 'array',
        'items': userSchema,
      },
    ),
    ...protectedStubResponses,
  ],
)
@Route(
  method: HttpMethod.post,
  path: '/api/subscriptions/users',
  summary: 'Subscribe to profile',
  description: "Start following another user's activity. (33)",
  tags: ['Subscriptions'],
  requestBody: ApiRequestBody(
    required: true,
    schema: {
      'type': 'object',
      'properties': {
        'userId': {'type': 'integer'},
      },
      'required': ['userId'],
    },
    example: {'userId': 42},
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
