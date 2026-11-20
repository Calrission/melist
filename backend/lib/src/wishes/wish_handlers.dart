import 'package:dart_frog/dart_frog.dart';
import 'package:melist_backend/melist_backend.dart';

Future<Response> handleReservations(RequestContext context) async {
  final rejected = rejectUnlessMethod(context, {HttpMethod.get});
  if (rejected != null) {
    return rejected;
  }

  final user = context.read<AuthUser>();
  final wishes = context.read<WishService>();

  try {
    final items = await wishes.listReservations(user);
    return Response.json(body: [for (final item in items) item.toJson()]);
  } on AppException catch (error) {
    return appError(error);
  }
}

Future<Response> handleWishesCollection(RequestContext context) async {
  final rejected = rejectUnlessMethod(
    context,
    {HttpMethod.get, HttpMethod.post, HttpMethod.delete},
  );
  if (rejected != null) {
    return rejected;
  }

  final user = context.read<AuthUser>();
  final wishes = context.read<WishService>();

  try {
    return await switch (context.request.method) {
      HttpMethod.get => _list(context, wishes, user),
      HttpMethod.post => _create(context, wishes, user),
      HttpMethod.delete => _bulkDelete(context, wishes, user),
      _ => Future.value(methodNotAllowed()),
    };
  } on AppException catch (error) {
    return appError(error);
  }
}

Future<Response> handleWishById(RequestContext context, String id) async {
  final rejected = rejectUnlessMethod(
    context,
    {HttpMethod.get, HttpMethod.patch, HttpMethod.delete},
  );
  if (rejected != null) {
    return rejected;
  }

  final user = context.read<AuthUser>();
  final wishes = context.read<WishService>();

  try {
    final wishId = parsePathId(id);
    return await switch (context.request.method) {
      HttpMethod.get => _get(wishes, user, wishId),
      HttpMethod.patch => _patch(context, wishes, user, wishId),
      HttpMethod.delete => _delete(wishes, user, wishId),
      _ => Future.value(methodNotAllowed()),
    };
  } on AppException catch (error) {
    return appError(error);
  }
}

Future<Response> handleWishDuplicate(
  RequestContext context,
  String id,
) async {
  final rejected = rejectUnlessMethod(context, {HttpMethod.post});
  if (rejected != null) {
    return rejected;
  }

  final user = context.read<AuthUser>();
  final wishes = context.read<WishService>();

  try {
    final copied = await wishes.duplicate(user, parsePathId(id));
    return created(copied.toJson());
  } on AppException catch (error) {
    return appError(error);
  }
}

Future<Response> _list(
  RequestContext context,
  WishService wishes,
  AuthUser user,
) async {
  final params = context.request.uri.queryParameters;
  requireMineTrue(params['mine']);

  final items = await wishes.listMine(
    user,
    query: params['query'],
    limit: parseQueryInt(
      params['limit'],
      'limit',
      fallback: WishService.defaultLimit,
      min: 1,
      max: WishService.maxLimit,
    ),
    offset: parseQueryInt(params['offset'], 'offset', fallback: 0),
  );
  return Response.json(body: [for (final item in items) item.toJson()]);
}

Future<Response> _create(
  RequestContext context,
  WishService wishes,
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

  final wish = await wishes.create(
    user,
    name: name,
    price: optionalJsonNumber(body['price'], 'price'),
    url: optionalJsonString(body['url'], 'url'),
    description: optionalJsonString(body['description'], 'description'),
    coverUrl: optionalJsonString(body['coverUrl'], 'coverUrl'),
    status: optionalJsonString(body['status'], 'status'),
  );
  return created(wish.toJson());
}

Future<Response> _bulkDelete(
  RequestContext context,
  WishService wishes,
  AuthUser user,
) async {
  final body = await readJsonMap(context.request);
  if (body == null) {
    return badRequest('Invalid JSON body');
  }

  await wishes.deleteMany(user, parseIntList(body['ids'], 'ids'));
  return noContent();
}

Future<Response> _get(WishService wishes, AuthUser user, int id) async {
  final wish = await wishes.getById(user, id);
  return Response.json(body: wish.toJson());
}

Future<Response> _patch(
  RequestContext context,
  WishService wishes,
  AuthUser user,
  int id,
) async {
  final body = await readJsonMap(context.request);
  if (body == null) {
    return badRequest('Invalid JSON body');
  }

  final updated = await wishes.update(
    user,
    id,
    name: optionalJsonString(body['name'], 'name'),
    price: body.containsKey('price') ? body['price'] : WishService.unset,
    url: body.containsKey('url') ? body['url'] : WishService.unset,
    description: body.containsKey('description')
        ? body['description']
        : WishService.unset,
    coverUrl: body.containsKey('coverUrl')
        ? body['coverUrl']
        : WishService.unset,
    status: optionalJsonString(body['status'], 'status'),
  );
  return Response.json(body: updated.toJson());
}

Future<Response> _delete(WishService wishes, AuthUser user, int id) async {
  await wishes.deleteOne(user, id);
  return noContent();
}
