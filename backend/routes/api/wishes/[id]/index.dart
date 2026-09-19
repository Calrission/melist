import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_swagger/dart_frog_swagger.dart';
import 'package:melist_backend/melist_backend.dart';

@Route(
  method: HttpMethod.get,
  path: '/api/wishes/{id}',
  summary: 'Wish details',
  description: 'Single wish.',
  tags: ['Wishes'],
  responses: [
    ApiResponse(
      statusCode: 200,
      description: 'Wish.',
      schema: wishSchema,
    ),
    forbiddenResponse,
    notFoundResponse,
    ...protectedStubResponses,
  ],
)
@Route(
  method: HttpMethod.patch,
  path: '/api/wishes/{id}',
  summary: 'Edit wish',
  description: 'Any wish field, including visibility (19) and status (20). '
      '(18)',
  tags: ['Wishes'],
  requestBody: ApiRequestBody(
    required: true,
    schema: wishInputSchema,
    example: {'status': 'reserved'},
  ),
  responses: [
    ApiResponse(
      statusCode: 200,
      description: 'Updated wish.',
      schema: wishSchema,
    ),
    badRequestResponse,
    forbiddenResponse,
    notFoundResponse,
    ...protectedStubResponses,
  ],
)
@Route(
  method: HttpMethod.delete,
  path: '/api/wishes/{id}',
  summary: 'Delete wish',
  description: 'Delete a single own wish. (21.1)',
  tags: ['Wishes'],
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
