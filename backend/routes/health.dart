import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_swagger/dart_frog_swagger.dart';

@Route(
  method: HttpMethod.get,
  path: '/health',
  summary: 'Health check',
  description: 'Returns ok when the server is running.',
  tags: ['Meta'],
  responses: [
    ApiResponse(
      statusCode: 200,
      description: 'Server is healthy.',
      contentType: 'text/plain',
      schema: {'type': 'string', 'example': 'ok'},
    ),
  ],
)
Response onRequest(RequestContext context) {
  return Response(body: 'ok');
}
