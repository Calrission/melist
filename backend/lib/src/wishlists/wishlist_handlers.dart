import 'package:dart_frog/dart_frog.dart';
import 'package:melist_backend/melist_backend.dart';

Future<Response> handleWishlistsCollection(RequestContext context) async {
  final rejected = rejectUnlessMethod(
    context,
    {HttpMethod.get, HttpMethod.post, HttpMethod.patch, HttpMethod.delete},
  );
  if (rejected != null) {
    return rejected;
  }

  final user = context.read<AuthUser>();
  final wishlists = context.read<WishlistService>();

  try {
    return await switch (context.request.method) {
      HttpMethod.get => _list(wishlists, user),
      HttpMethod.post => _create(context, wishlists, user),
      HttpMethod.delete => _bulkDelete(context, wishlists, user),
      HttpMethod.patch => Future.value(notImplemented()),
      _ => Future.value(methodNotAllowed()),
    };
  } on AppException catch (error) {
    return appError(error);
  }
}

Future<Response> handleWishlistById(
  RequestContext context,
  String id,
) async {
  final rejected = rejectUnlessMethod(
    context,
    {HttpMethod.get, HttpMethod.patch, HttpMethod.delete},
  );
  if (rejected != null) {
    return rejected;
  }

  final user = context.read<AuthUser>();
  final wishlists = context.read<WishlistService>();

  try {
    final wishlistId = parsePathId(id);
    return await switch (context.request.method) {
      HttpMethod.get => _get(wishlists, user, wishlistId),
      HttpMethod.patch => _patch(context, wishlists, user, wishlistId),
      HttpMethod.delete => _delete(wishlists, user, wishlistId),
      _ => Future.value(methodNotAllowed()),
    };
  } on AppException catch (error) {
    return appError(error);
  }
}

Future<Response> _list(WishlistService wishlists, AuthUser user) async {
  final items = await wishlists.listMine(user);
  return Response.json(body: [for (final item in items) item.toJson()]);
}

Future<Response> _create(
  RequestContext context,
  WishlistService wishlists,
  AuthUser user,
) async {
  final body = await readJsonMap(context.request);
  if (body == null) {
    return badRequest('Invalid JSON body');
  }

  final name = body['name'];
  if (name is! String) {
    return badRequest('name is required');
  }

  final wishlist = await wishlists.create(
    user,
    name: name,
    description: optionalJsonString(body['description'], 'description'),
    color: optionalJsonString(body['color'], 'color'),
    visibility: optionalJsonString(body['visibility'], 'visibility'),
    wishIds: parseIntList(body['wishIds'], 'wishIds'),
  );
  return created(wishlist.toJson());
}

Future<Response> _bulkDelete(
  RequestContext context,
  WishlistService wishlists,
  AuthUser user,
) async {
  final body = await readJsonMap(context.request);
  if (body == null) {
    return badRequest('Invalid JSON body');
  }

  await wishlists.deleteMany(user, parseIntList(body['ids'], 'ids'));
  return noContent();
}

Future<Response> _get(
  WishlistService wishlists,
  AuthUser user,
  int id,
) async {
  final wishlist = await wishlists.getById(user, id);
  return Response.json(body: wishlist.toJson());
}

Future<Response> _patch(
  RequestContext context,
  WishlistService wishlists,
  AuthUser user,
  int id,
) async {
  final body = await readJsonMap(context.request);
  if (body == null) {
    return badRequest('Invalid JSON body');
  }

  final updated = await wishlists.update(
    user,
    id,
    name: optionalJsonString(body['name'], 'name'),
    description: body.containsKey('description')
        ? body['description']
        : WishlistService.unsetDescription,
    color: optionalJsonString(body['color'], 'color'),
    visibility: optionalJsonString(body['visibility'], 'visibility'),
  );
  return Response.json(body: updated.toJson());
}

Future<Response> _delete(
  WishlistService wishlists,
  AuthUser user,
  int id,
) async {
  await wishlists.deleteOne(user, id);
  return noContent();
}
