import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_swagger/dart_frog_swagger.dart';
import 'package:melist_backend/melist_backend.dart';

@Route(
  method: HttpMethod.post,
  path: '/api/donations',
  summary: 'Create donation invoice',
  description: 'Creates a Telegram Stars invoice link to support the project. '
      'Successful payment grants an entitlement. (28, 29.2)',
  tags: ['Monetization'],
  requestBody: ApiRequestBody(
    required: true,
    schema: {
      'type': 'object',
      'properties': {
        'amount': {'type': 'integer', 'description': 'Amount in Stars.'},
      },
      'required': ['amount'],
    },
    example: {'amount': 100},
  ),
  responses: [
    ApiResponse(
      statusCode: 201,
      description: 'Invoice created.',
      schema: {
        'type': 'object',
        'properties': {
          'invoiceLink': {'type': 'string'},
        },
        'required': ['invoiceLink'],
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
