import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_swagger/dart_frog_swagger.dart';
import 'package:melist_backend/melist_backend.dart';
import 'package:melist_backend/src/wishes/wish_handlers.dart';

@Route(
  method: HttpMethod.get,
  path: '/api/v1/reservations',
  summary: 'List wishes reserved by the caller',
  description:
      'Wishes of other users that the caller reserved, newest first. '
      'Each item includes the owner display name and reservedByMe.',
  tags: ['Wishes'],
  responses: [
    ApiResponse(
      statusCode: 200,
      description: 'Reserved wishes.',
      schema: {
        'type': 'array',
        'items': wishSchema,
      },
    ),
    unauthorizedResponse,
    methodNotAllowedResponse,
  ],
)
Future<Response> onRequest(RequestContext context) {
  return handleReservations(context);
}
