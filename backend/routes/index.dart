import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_swagger/dart_frog_swagger.dart';

/// JSON welcome. While a Flutter web `index.html` exists, `GET /`
/// is the Mini App instead (`withFrontend` in `main.dart`).
@Route(
  method: HttpMethod.get,
  path: '/',
  summary: 'Service info',
  description:
      'Returns basic service metadata. '
      'Not served when the Flutter web build is present: GET / is the Mini App.',
  tags: ['Meta'],
  responses: [
    ApiResponse(
      statusCode: 200,
      description: 'Service metadata.',
      schema: {
        'type': 'object',
        'properties': {
          'service': {'type': 'string', 'example': 'melist'},
          'message': {'type': 'string'},
        },
      },
    ),
  ],
)
Response onRequest(RequestContext context) {
  return Response.json(
    body: {
      'service': 'melist',
      'message': 'Welcome to Dart Frog!',
    },
  );
}
