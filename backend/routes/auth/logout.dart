import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_swagger/dart_frog_swagger.dart';
import 'package:melist_backend/melist_backend.dart';
import 'package:melist_backend/src/openapi/auth_docs.dart';

@Route(
  method: HttpMethod.post,
  path: '/auth/logout',
  summary: 'Revoke the refresh cookie',
  description:
      'Revokes the current refresh token (if present) and clears the '
      'HttpOnly cookie. Always returns 204.',
  tags: ['Auth'],
  responses: authLogoutResponses,
)
Future<Response> onRequest(RequestContext context) async {
  final rejected = rejectUnlessMethod(context, {HttpMethod.post});
  if (rejected != null) {
    return rejected;
  }

  final config = context.read<AppConfig>();
  return logoutSession(
    request: context.request,
    sessions: context.read<AuthSessionService>(),
    cookieSecure: config.cookieSecure,
  );
}
