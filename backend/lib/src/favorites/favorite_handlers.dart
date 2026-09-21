import 'package:dart_frog/dart_frog.dart';
import 'package:melist_backend/melist_backend.dart';

Future<Response> handleFavoritesCollection(RequestContext context) async {
  final rejected = rejectUnlessMethod(
    context,
    {HttpMethod.get, HttpMethod.post, HttpMethod.patch},
  );
  if (rejected != null) {
    return rejected;
  }

  final user = context.read<AuthUser>();
  final favorites = context.read<FavoriteService>();

  try {
    return await switch (context.request.method) {
      HttpMethod.get => _list(favorites, user),
      HttpMethod.post => _add(context, favorites, user),
      HttpMethod.patch => _reorder(context, favorites, user),
      _ => Future.value(methodNotAllowed()),
    };
  } on AppException catch (error) {
    return appError(error);
  }
}

Future<Response> handleFavoriteByWishlistId(
  RequestContext context,
  String wishlistId,
) async {
  final rejected = rejectUnlessMethod(context, {HttpMethod.delete});
  if (rejected != null) {
    return rejected;
  }

  final user = context.read<AuthUser>();
  final favorites = context.read<FavoriteService>();

  try {
    await favorites.remove(
      user,
      parsePathId(wishlistId, field: 'wishlistId'),
    );
    return noContent();
  } on AppException catch (error) {
    return appError(error);
  }
}

Future<Response> _list(FavoriteService favorites, AuthUser user) async {
  final items = await favorites.list(user);
  return Response.json(body: [for (final item in items) item.toJson()]);
}

Future<Response> _add(
  RequestContext context,
  FavoriteService favorites,
  AuthUser user,
) async {
  final body = await readJsonMap(context.request);
  if (body == null) {
    return badRequest('Invalid JSON body');
  }

  final added = await favorites.add(
    user,
    optionalJsonString(body['shareToken'], 'shareToken'),
  );
  return created(added.toJson());
}

Future<Response> _reorder(
  RequestContext context,
  FavoriteService favorites,
  AuthUser user,
) async {
  final body = await readJsonMap(context.request);
  if (body == null) {
    return badRequest('Invalid JSON body');
  }
  if (!body.containsKey('order')) {
    return badRequest('order is required');
  }

  await favorites.reorder(user, parseIntList(body['order'], 'order'));
  return noContent();
}
