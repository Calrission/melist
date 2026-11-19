import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_swagger/dart_frog_swagger.dart';
import 'package:melist_backend/melist_backend.dart';
import 'package:melist_backend/src/subscriptions/subscription_handlers.dart';

@Route(
  method: HttpMethod.delete,
  path: '/api/v1/subscriptions/users/{userId}',
  summary: 'Unsubscribe from profile',
  description: 'Stop following the user. (35)',
  tags: ['Subscriptions'],
  responses: [
    noContentResponse,
    notFoundResponse,
    unauthorizedResponse,
    methodNotAllowedResponse,
  ],
)
Future<Response> onRequest(RequestContext context, String userId) {
  return handleUserUnsubscribe(context, userId);
}
