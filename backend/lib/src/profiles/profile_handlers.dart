import 'package:dart_frog/dart_frog.dart';
import 'package:melist_backend/melist_backend.dart';

Future<Response> handleMe(RequestContext context) async {
  final rejected = rejectUnlessMethod(
    context,
    {HttpMethod.get, HttpMethod.patch},
  );
  if (rejected != null) {
    return rejected;
  }

  final user = context.read<AuthUser>();
  final profiles = context.read<ProfileService>();

  try {
    return await switch (context.request.method) {
      HttpMethod.get => _getMe(profiles, user),
      HttpMethod.patch => _patchMe(context, profiles, user),
      _ => Future.value(methodNotAllowed()),
    };
  } on AppException catch (error) {
    return appError(error);
  }
}

Future<Response> handlePublicUser(RequestContext context, String id) async {
  final rejected = rejectUnlessMethod(context, {HttpMethod.get});
  if (rejected != null) {
    return rejected;
  }

  context.read<AuthUser>();
  final profiles = context.read<ProfileService>();

  try {
    final profile = await profiles.getPublic(parsePathId(id));
    return Response.json(body: profile.toJson());
  } on AppException catch (error) {
    return appError(error);
  }
}

Future<Response> handleProfileShare(RequestContext context, String id) async {
  final rejected = rejectUnlessMethod(context, {HttpMethod.get});
  if (rejected != null) {
    return rejected;
  }

  context.read<AuthUser>();
  final profiles = context.read<ProfileService>();
  final config = context.read<AppConfig>();

  try {
    final userId = parsePathId(id);
    await profiles.getPublic(userId);
    return Response.json(
      body: {
        'url': telegramProfileUrl(
          botUsername: config.botUsername,
          userId: userId,
        ),
      },
    );
  } on AppException catch (error) {
    return appError(error);
  }
}

Future<Response> _getMe(ProfileService profiles, AuthUser user) async {
  final profile = await profiles.me(user);
  return Response.json(body: profile.toJson());
}

Future<Response> _patchMe(
  RequestContext context,
  ProfileService profiles,
  AuthUser user,
) async {
  final body = await readJsonMap(context.request);
  if (body == null) {
    return badRequest('Invalid JSON body');
  }

  final updated = await profiles.update(
    user,
    birthday: body.containsKey('birthday')
        ? body['birthday']
        : ProfileService.unset,
    nickname: body.containsKey('nickname')
        ? body['nickname']
        : ProfileService.unset,
    theme: optionalJsonString(body['theme'], 'theme'),
  );
  return Response.json(body: updated.toJson());
}
