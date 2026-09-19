import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_swagger/dart_frog_swagger.dart';
import 'package:melist_backend/melist_backend.dart';

@Route(
  method: HttpMethod.delete,
  path: '/api/subscriptions/wishlists/{wishlistId}',
  summary: 'Unsubscribe from wishlist',
  description: 'Stop following the wishlist. (32)',
  tags: ['Subscriptions'],
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
