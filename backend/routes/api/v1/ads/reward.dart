import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_swagger/dart_frog_swagger.dart';
import 'package:melist_backend/melist_backend.dart';

@Route(
  method: HttpMethod.post,
  path: '/api/v1/ads/reward',
  summary: 'Confirm rewarded ad view',
  description:
      'Validates the ad provider payload and grants a temporary '
      'entitlement. Ad display itself happens on the client. (27, 29.1)',
  tags: ['Monetization'],
  requestBody: ApiRequestBody(
    required: true,
    schema: {
      'type': 'object',
      'properties': {
        'provider': {'type': 'string', 'example': 'adsgram'},
        'payload': {'type': 'string'},
      },
      'required': ['provider', 'payload'],
    },
  ),
  responses: [
    ApiResponse(
      statusCode: 200,
      description: 'Updated entitlements.',
      schema: {
        'type': 'object',
        'properties': {
          'premiumUntil': {'type': 'string', 'format': 'date-time'},
        },
      },
    ),
    badRequestResponse,
    ...protectedStubResponses,
  ],
)
Future<Response> onRequest(RequestContext context) async {
  final rejected = rejectUnlessMethod(context, {HttpMethod.post});
  if (rejected != null) {
    return rejected;
  }

  context.read<AuthUser>();
  return notImplemented();
}
