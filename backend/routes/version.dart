import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_swagger/dart_frog_swagger.dart';
import 'package:melist_backend/melist_backend.dart';

@Route(
  method: HttpMethod.get,
  path: '/version',
  summary: 'Backend version',
  description:
      'Returns the version from backend/pubspec.yaml. '
      'Public, no authentication.',
  tags: ['Meta'],
  responses: [
    ApiResponse(
      statusCode: 200,
      description: 'Running backend version.',
      schema: {
        'type': 'object',
        'properties': {
          'version': {'type': 'string', 'example': '0.1.2'},
        },
        'required': ['version'],
      },
    ),
    methodNotAllowedResponse,
  ],
)
Response onRequest(RequestContext context) {
  final rejected = rejectUnlessMethod(context, {HttpMethod.get});
  if (rejected != null) {
    return rejected;
  }
  return Response.json(body: {'version': packageVersion()});
}
