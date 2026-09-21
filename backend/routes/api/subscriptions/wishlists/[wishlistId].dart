import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_swagger/dart_frog_swagger.dart';
import 'package:melist_backend/melist_backend.dart';
import 'package:melist_backend/src/subscriptions/subscription_handlers.dart';

@Route(
  method: HttpMethod.delete,
  path: '/api/subscriptions/wishlists/{wishlistId}',
  summary: 'Unsubscribe from wishlist',
  description: 'Stop following the wishlist. (32)',
  tags: ['Subscriptions'],
  responses: [
    noContentResponse,
    notFoundResponse,
    unauthorizedResponse,
    methodNotAllowedResponse,
  ],
)
Future<Response> onRequest(RequestContext context, String wishlistId) {
  return handleWishlistUnsubscribe(context, wishlistId);
}
