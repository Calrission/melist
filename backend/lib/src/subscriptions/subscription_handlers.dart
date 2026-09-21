import 'package:dart_frog/dart_frog.dart';
import 'package:melist_backend/melist_backend.dart';

Future<Response> handleWishlistSubscriptions(RequestContext context) async {
  final rejected = rejectUnlessMethod(
    context,
    {HttpMethod.get, HttpMethod.post},
  );
  if (rejected != null) {
    return rejected;
  }

  final user = context.read<AuthUser>();
  final subscriptions = context.read<SubscriptionService>();

  try {
    return await switch (context.request.method) {
      HttpMethod.get => _listWishlists(subscriptions, user),
      HttpMethod.post => _subscribeWishlist(context, subscriptions, user),
      _ => Future.value(methodNotAllowed()),
    };
  } on AppException catch (error) {
    return appError(error);
  }
}

Future<Response> handleWishlistUnsubscribe(
  RequestContext context,
  String wishlistId,
) async {
  final rejected = rejectUnlessMethod(context, {HttpMethod.delete});
  if (rejected != null) {
    return rejected;
  }

  final user = context.read<AuthUser>();
  final subscriptions = context.read<SubscriptionService>();

  try {
    await subscriptions.unsubscribeWishlist(
      user,
      parsePathId(wishlistId, field: 'wishlistId'),
    );
    return noContent();
  } on AppException catch (error) {
    return appError(error);
  }
}

Future<Response> handleUserSubscriptions(RequestContext context) async {
  final rejected = rejectUnlessMethod(
    context,
    {HttpMethod.get, HttpMethod.post},
  );
  if (rejected != null) {
    return rejected;
  }

  final user = context.read<AuthUser>();
  final subscriptions = context.read<SubscriptionService>();

  try {
    return await switch (context.request.method) {
      HttpMethod.get => _listUsers(subscriptions, user),
      HttpMethod.post => _subscribeUser(context, subscriptions, user),
      _ => Future.value(methodNotAllowed()),
    };
  } on AppException catch (error) {
    return appError(error);
  }
}

Future<Response> handleUserUnsubscribe(
  RequestContext context,
  String userId,
) async {
  final rejected = rejectUnlessMethod(context, {HttpMethod.delete});
  if (rejected != null) {
    return rejected;
  }

  final user = context.read<AuthUser>();
  final subscriptions = context.read<SubscriptionService>();

  try {
    await subscriptions.unsubscribeUser(
      user,
      parsePathId(userId, field: 'userId'),
    );
    return noContent();
  } on AppException catch (error) {
    return appError(error);
  }
}

Future<Response> _listWishlists(
  SubscriptionService subscriptions,
  AuthUser user,
) async {
  final items = await subscriptions.listWishlists(user);
  return Response.json(body: [for (final item in items) item.toJson()]);
}

Future<Response> _subscribeWishlist(
  RequestContext context,
  SubscriptionService subscriptions,
  AuthUser user,
) async {
  final body = await readJsonMap(context.request);
  if (body == null) {
    return badRequest('Invalid JSON body');
  }

  final wishlist = await subscriptions.subscribeWishlist(
    user,
    optionalJsonPositiveInt(body['wishlistId'], 'wishlistId'),
  );
  return created(wishlist.toJson());
}

Future<Response> _listUsers(
  SubscriptionService subscriptions,
  AuthUser user,
) async {
  final items = await subscriptions.listUsers(user);
  return Response.json(body: [for (final item in items) item.toJson()]);
}

Future<Response> _subscribeUser(
  RequestContext context,
  SubscriptionService subscriptions,
  AuthUser user,
) async {
  final body = await readJsonMap(context.request);
  if (body == null) {
    return badRequest('Invalid JSON body');
  }

  final followee = await subscriptions.subscribeUser(
    user,
    optionalJsonPositiveInt(body['userId'], 'userId'),
  );
  return created(followee.toJson());
}
