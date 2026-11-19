import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_swagger/dart_frog_swagger.dart';
import 'package:melist_backend/melist_backend.dart';
import 'package:melist_backend/src/favorites/favorite_handlers.dart';

@Route(
  method: HttpMethod.delete,
  path: '/api/v1/favorites/{wishlistId}',
  summary: 'Remove wishlist from favorites',
  description: 'Stops showing the wishlist in favorites. (11)',
  tags: ['Favorites'],
  responses: [
    noContentResponse,
    notFoundResponse,
    unauthorizedResponse,
    methodNotAllowedResponse,
  ],
)
Future<Response> onRequest(RequestContext context, String wishlistId) {
  return handleFavoriteByWishlistId(context, wishlistId);
}
