import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_swagger/dart_frog_swagger.dart';
import 'package:melist_backend/melist_backend.dart';
import 'package:melist_backend/src/wishlists/wishlist_handlers.dart';

@Route(
  method: HttpMethod.post,
  path: '/api/wishlists/{id}/share',
  summary: 'Create or get share link',
  description: 'Returns the share token and a Mini App deep link. (7.1)',
  tags: ['Wishlists'],
  responses: [
    ApiResponse(
      statusCode: 200,
      description: 'Share link.',
      schema: {
        'type': 'object',
        'properties': {
          'shareToken': {'type': 'string'},
          'url': {'type': 'string'},
        },
        'required': ['shareToken', 'url'],
      },
      example: {
        'shareToken': 'k3Jd9s',
        'url': 'https://t.me/melist_bot?startapp=wl_k3Jd9s',
      },
    ),
    forbiddenResponse,
    notFoundResponse,
    unauthorizedResponse,
    methodNotAllowedResponse,
  ],
)
Future<Response> onRequest(RequestContext context, String id) {
  return handleWishlistShare(context, id);
}
