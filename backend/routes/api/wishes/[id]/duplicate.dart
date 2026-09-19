import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_swagger/dart_frog_swagger.dart';
import 'package:melist_backend/melist_backend.dart';

@Route(
  method: HttpMethod.post,
  path: '/api/wishes/{id}/duplicate',
  summary: 'Duplicate wish',
  description: 'Creates a copy of an own wish. (13)',
  tags: ['Wishes'],
  responses: [
    ApiResponse(
      statusCode: 201,
      description: 'The new copy.',
      schema: wishSchema,
    ),
    forbiddenResponse,
    notFoundResponse,
    ...protectedStubResponses,
  ],
)
Future<Response> onRequest(RequestContext context, String id) async {
  final rejected = rejectUnlessMethod(context, {HttpMethod.post});
  if (rejected != null) {
    return rejected;
  }

  context.read<AuthUser>();
  return notImplemented();
}
