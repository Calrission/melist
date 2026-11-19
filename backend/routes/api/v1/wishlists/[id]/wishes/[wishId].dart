import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_swagger/dart_frog_swagger.dart';
import 'package:melist_backend/melist_backend.dart';
import 'package:melist_backend/src/wishlists/wishlist_handlers.dart';

@Route(
  method: HttpMethod.delete,
  path: '/api/v1/wishlists/{id}/wishes/{wishId}',
  summary: 'Remove wish from wishlist',
  description: 'Detaches the wish from the wishlist; the wish itself stays.',
  tags: ['Wishlists'],
  responses: [
    noContentResponse,
    forbiddenResponse,
    notFoundResponse,
    unauthorizedResponse,
    methodNotAllowedResponse,
  ],
)
Future<Response> onRequest(
  RequestContext context,
  String id,
  String wishId,
) {
  return handleWishlistWishById(context, id, wishId);
}
