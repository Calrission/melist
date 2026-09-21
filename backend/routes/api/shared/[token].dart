import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_swagger/dart_frog_swagger.dart';
import 'package:melist_backend/melist_backend.dart';
import 'package:melist_backend/src/wishlists/wishlist_handlers.dart';

@Route(
  method: HttpMethod.get,
  path: '/api/shared/{token}',
  summary: 'View wishlist by share link',
  description:
      'Resolves a share token to a public or link wishlist. '
      'Drafts are owner-only. Used before adding to favorites. (7, 8.1)',
  tags: ['Wishlists'],
  responses: [
    ApiResponse(
      statusCode: 200,
      description: 'Shared wishlist.',
      schema: wishlistSchema,
    ),
    notFoundResponse,
    unauthorizedResponse,
    methodNotAllowedResponse,
  ],
)
Future<Response> onRequest(RequestContext context, String token) {
  return handleSharedWishlist(context, token);
}
