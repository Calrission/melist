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
      HttpMethod.patch => _reorder(context, wishlists, user),
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

Future<Response> _reorder(
  RequestContext context,
  WishlistService wishlists,
  AuthUser user,
) async {
  final body = await readJsonMap(context.request);
  if (body == null) {
    return badRequest('Invalid JSON body');
  }
  if (!body.containsKey('order')) {
    return badRequest('order is required');
  }

  await wishlists.reorder(user, parseIntList(body['order'], 'order'));
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
    visibility: optionalJsonString(body['visibility'], 'visibility'),
  );
  return Response.json(body: updated.toJson());
}

Future<Response> handleWishlistWishes(
  RequestContext context,
  String id,
) async {
  final rejected = rejectUnlessMethod(
    context,
    {HttpMethod.post, HttpMethod.patch},
  );
  if (rejected != null) {
    return rejected;
  }

  final user = context.read<AuthUser>();
  final wishlists = context.read<WishlistService>();

  try {
    final wishlistId = parsePathId(id);
    return await switch (context.request.method) {
      HttpMethod.post => _addWish(context, wishlists, user, wishlistId),
      HttpMethod.patch => _reorderWishes(context, wishlists, user, wishlistId),
      _ => Future.value(methodNotAllowed()),
    };
  } on AppException catch (error) {
    return appError(error);
  }
}

Future<Response> handleWishlistWishById(
  RequestContext context,
  String id,
  String wishId,
) async {
  final rejected = rejectUnlessMethod(context, {HttpMethod.delete});
  if (rejected != null) {
    return rejected;
  }

  final user = context.read<AuthUser>();
  final wishlists = context.read<WishlistService>();

  try {
    await wishlists.removeWish(
      user,
      parsePathId(id),
      parsePathId(wishId, field: 'wishId'),
    );
    return noContent();
  } on AppException catch (error) {
    return appError(error);
  }
}

Future<Response> _delete(
  WishlistService wishlists,
  AuthUser user,
  int id,
) async {
  await wishlists.deleteOne(user, id);
  return noContent();
}

Future<Response> _addWish(
  RequestContext context,
  WishlistService wishlists,
  AuthUser user,
  int wishlistId,
) async {
  final body = await readJsonMap(context.request);
  if (body == null) {
    return badRequest('Invalid JSON body');
  }

  Map<String, dynamic>? wish;
  if (body['wish'] != null) {
    final raw = body['wish'];
    if (raw is! Map) {
      return badRequest('wish must be an object');
    }
    wish = Map<String, dynamic>.from(raw);
  }

  final added = await wishlists.addWish(
    user,
    wishlistId,
    wish: wish,
    wishId: optionalJsonPositiveInt(body['wishId'], 'wishId'),
    copyFromWishId: optionalJsonPositiveInt(
      body['copyFromWishId'],
      'copyFromWishId',
    ),
  );
  return created(added.toJson());
}

Future<Response> _reorderWishes(
  RequestContext context,
  WishlistService wishlists,
  AuthUser user,
  int wishlistId,
) async {
  final body = await readJsonMap(context.request);
  if (body == null) {
    return badRequest('Invalid JSON body');
  }
  if (!body.containsKey('order')) {
    return badRequest('order is required');
  }

  await wishlists.reorderWishes(
    user,
    wishlistId,
    parseIntList(body['order'], 'order'),
  );
  return noContent();
}

Future<Response> handleWishlistShare(
  RequestContext context,
  String id,
) async {
  final rejected = rejectUnlessMethod(context, {HttpMethod.post});
  if (rejected != null) {
    return rejected;
  }

  final user = context.read<AuthUser>();
  final wishlists = context.read<WishlistService>();
  final config = context.read<AppConfig>();

  try {
    final token = await wishlists.share(user, parsePathId(id));
    return Response.json(
      body: {
        'shareToken': token,
        'url': telegramShareUrl(
          botUsername: config.botUsername,
          token: token,
        ),
      },
    );
  } on AppException catch (error) {
    return appError(error);
  }
}

Future<Response> handleSharedWishlist(
  RequestContext context,
  String token,
) async {
  final rejected = rejectUnlessMethod(context, {HttpMethod.get});
  if (rejected != null) {
    return rejected;
  }

  final user = context.read<AuthUser>();
  final wishlists = context.read<WishlistService>();

  try {
    final wishlist = await wishlists.getShared(user, token);
    return Response.json(body: wishlist.toJson());
  } on AppException catch (error) {
    return appError(error);
  }
}

Future<Response> handleSharedWishReservation(
  RequestContext context,
  String token,
  String wishId,
) async {
  final rejected = rejectUnlessMethod(context, {
    HttpMethod.post,
    HttpMethod.delete,
  });
  if (rejected != null) {
    return rejected;
  }

  final user = context.read<AuthUser>();
  final wishlists = context.read<WishlistService>();

  try {
    final id = parsePathId(wishId, field: 'wishId');
    final wish = context.request.method == HttpMethod.delete
        ? await wishlists.cancelSharedReservation(user, token, id)
        : await wishlists.reserveSharedWish(user, token, id);
    return Response.json(body: wish.toJson());
  } on AppException catch (error) {
    return appError(error);
  }
}
