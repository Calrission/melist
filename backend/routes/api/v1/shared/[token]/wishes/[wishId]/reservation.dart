import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_swagger/dart_frog_swagger.dart';
import 'package:melist_backend/melist_backend.dart';
import 'package:melist_backend/src/wishlists/wishlist_handlers.dart';

@Route(
  method: HttpMethod.post,
  path: '/api/v1/shared/{token}/wishes/{wishId}/reservation',
  summary: 'Reserve a wish on a shared wishlist',
  description:
      'The caller reserves a free wish. The response says only whether '
      'this caller holds the reservation.',
  tags: ['Wishlists'],
  responses: [
    ApiResponse(
      statusCode: 200,
      description: 'The wish, with reservedByMe for the caller.',
      schema: wishSchema,
    ),
    forbiddenResponse,
    conflictResponse,
    notFoundResponse,
    unauthorizedResponse,
    methodNotAllowedResponse,
  ],
)
@Route(
  method: HttpMethod.delete,
  path: '/api/v1/shared/{token}/wishes/{wishId}/reservation',
  summary: 'Cancel the caller reservation',
  description:
      'Releases a reservation held by the caller. '
      'Does not identify anyone else.',
  tags: ['Wishlists'],
  responses: [
    ApiResponse(
      statusCode: 200,
      description: 'The wish, with reservedByMe false.',
      schema: wishSchema,
    ),
    forbiddenResponse,
    conflictResponse,
    notFoundResponse,
    unauthorizedResponse,
    methodNotAllowedResponse,
  ],
)
Future<Response> onRequest(
  RequestContext context,
  String token,
  String wishId,
) {
  return handleSharedWishReservation(context, token, wishId);
}
