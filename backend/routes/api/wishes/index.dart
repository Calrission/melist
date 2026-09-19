import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_swagger/dart_frog_swagger.dart';
import 'package:melist_backend/melist_backend.dart';

@Route(
  method: HttpMethod.get,
  path: '/api/wishes',
  summary: 'List and search wishes',
  description: 'Query params: query (name search, 17.1), mine=true '
      '(only own wishes, 17.2), limit, offset. (16)',
  tags: ['Wishes'],
  responses: [
    ApiResponse(
      statusCode: 200,
      description: 'Wishes.',
      schema: {
        'type': 'array',
        'items': wishSchema,
      },
    ),
    ...protectedStubResponses,
  ],
)
@Route(
  method: HttpMethod.post,
  path: '/api/wishes',
  summary: 'Create wish',
  description: 'Only name is required. (12)',
  tags: ['Wishes'],
  requestBody: ApiRequestBody(
    required: true,
    schema: wishInputSchema,
    example: {
      'name': 'Headphones',
      'price': 12000,
      'url': 'https://example.com/item',
      'visibility': 'public',
      'status': 'free',
    },
  ),
  responses: [
    ApiResponse(
      statusCode: 201,
      description: 'Created wish.',
      schema: wishSchema,
    ),
    badRequestResponse,
    ...protectedStubResponses,
  ],
)
@Route(
  method: HttpMethod.delete,
  path: '/api/wishes',
  summary: 'Bulk delete wishes',
  description: 'Delete several own wishes at once. (21.2)',
  tags: ['Wishes'],
  requestBody: idsRequestBody,
  responses: [
    noContentResponse,
    badRequestResponse,
    ...protectedStubResponses,
  ],
)
Future<Response> onRequest(RequestContext context) async {
  final rejected = rejectUnlessMethod(
    context,
    {HttpMethod.get, HttpMethod.post, HttpMethod.delete},
  );
  if (rejected != null) {
    return rejected;
  }

  context.read<AuthUser>();
  return notImplemented();
}
