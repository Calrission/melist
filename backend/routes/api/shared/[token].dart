import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_swagger/dart_frog_swagger.dart';
import 'package:melist_backend/melist_backend.dart';

@Route(
  method: HttpMethod.get,
  path: '/api/shared/{token}',
  summary: 'View wishlist by share link',
  description: 'Resolves a share token to a wishlist regardless of its '
      'visibility. Used before adding to favorites. (7, 8.1)',
  tags: ['Wishlists'],
  responses: [
    ApiResponse(
      statusCode: 200,
      description: 'Shared wishlist.',
      schema: wishlistSchema,
    ),
    notFoundResponse,
    ...protectedStubResponses,
  ],
)
Future<Response> onRequest(RequestContext context, String token) async {
  final rejected = rejectUnlessMethod(context, {HttpMethod.get});
  if (rejected != null) {
    return rejected;
  }

  context.read<AuthUser>();
  return notImplemented();
}
