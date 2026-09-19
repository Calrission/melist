import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:melist_backend/src/auth/init_data_validator.dart';
import 'package:melist_backend/src/auth/jwt_service.dart';
import 'package:melist_core/melist_core.dart';

Future<Response> authenticateWithInitData({
  required Request request,
  required InitDataValidator validator,
  required JwtService jwtService,
}) async {
  final initData = await _readInitData(request);
  if (initData == null) {
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: const {'error': 'initData is required'},
    );
  }

  return switch (validator.validate(initData)) {
    InitDataFailure(:final reason) => Response.json(
        statusCode: HttpStatus.unauthorized,
        body: {
          'error': switch (reason) {
            InitDataFailureReason.expired => 'Expired initData',
            InitDataFailureReason.invalid => 'Invalid initData',
          },
        },
      ),
    InitDataSuccess(:final user) => Response.json(
        body: {
          'accessToken': jwtService.issueAccessToken(user),
          'tokenType': 'Bearer',
          'expiresIn': jwtService.accessTokenTtl.inSeconds,
          'user': _userJson(user),
        },
      ),
  };
}

Future<String?> _readInitData(Request request) async {
  try {
    final body = await request.json();
    if (body is! Map<String, dynamic>) {
      return null;
    }

    final initData = body['initData'];
    if (initData is! String || initData.isEmpty) {
      return null;
    }

    return initData;
  } on Object {
    return null;
  }
}

Map<String, Object?> _userJson(UserModel user) {
  return {
    'id': user.id,
    'firstName': user.firstName,
    'lastName': user.lastName,
    'username': user.username,
    'avatarUrl': user.avatarUrl,
  };
}
