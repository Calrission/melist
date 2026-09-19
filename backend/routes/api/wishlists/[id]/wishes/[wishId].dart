import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_swagger/dart_frog_swagger.dart';
import 'package:melist_backend/melist_backend.dart';

@Route(
  method: HttpMethod.delete,
  path: '/api/wishlists/{id}/wishes/{wishId}',
  summary: 'Remove wish from wishlist',
  description: 'Detaches the wish from the wishlist; the wish itself stays.',
  tags: ['Wishlists'],
  responses: [
    noContentResponse,
    forbiddenResponse,
    notFoundResponse,
    ...protectedStubResponses,
  ],
)
Future<Response> onRequest(
  RequestContext context,
  String id,
  String wishId,
) async {
  final rejected = rejectUnlessMethod(context, {HttpMethod.delete});
  if (rejected != null) {
    return rejected;
  }

  context.read<AuthUser>();
  return notImplemented();
}
