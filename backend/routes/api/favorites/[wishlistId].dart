import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_swagger/dart_frog_swagger.dart';
import 'package:melist_backend/melist_backend.dart';

@Route(
  method: HttpMethod.delete,
  path: '/api/favorites/{wishlistId}',
  summary: 'Remove wishlist from favorites',
  description: 'Stops showing the wishlist in favorites. (11)',
  tags: ['Favorites'],
  responses: [
    noContentResponse,
    notFoundResponse,
    ...protectedStubResponses,
  ],
)
Future<Response> onRequest(RequestContext context, String wishlistId) async {
  final rejected = rejectUnlessMethod(context, {HttpMethod.delete});
  if (rejected != null) {
    return rejected;
  }

  context.read<AuthUser>();
  return notImplemented();
}
