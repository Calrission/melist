import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_swagger/dart_frog_swagger.dart';
import 'package:melist_backend/melist_backend.dart';

@Route(
  method: HttpMethod.get,
  path: '/api/me/entitlements',
  summary: 'Premium entitlements',
  description: 'Access to extra features earned via ads or donations. (29)',
  tags: ['Profile'],
  responses: [
    ApiResponse(
      statusCode: 200,
      description: 'Entitlements.',
      schema: {
        'type': 'object',
        'properties': {
          'premiumUntil': {
            'type': 'string',
            'format': 'date-time',
            'nullable': true,
          },
          'sources': {
            'type': 'array',
            'items': {
              'type': 'string',
              'enum': ['ad', 'donation'],
            },
          },
        },
      },
    ),
    ...protectedStubResponses,
  ],
)
Future<Response> onRequest(RequestContext context) async {
  final rejected = rejectUnlessMethod(context, {HttpMethod.get});
  if (rejected != null) {
    return rejected;
  }

  context.read<AuthUser>();
  return notImplemented();
}
