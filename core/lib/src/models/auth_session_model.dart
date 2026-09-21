import 'model_codec.dart';
import 'user_model.dart';

/// Response of `POST /auth/validate`.
class AuthSessionModel {
  const AuthSessionModel({
    required this.accessToken,
    required this.expiresIn,
    required this.user,
    this.tokenType = bearer,
  });

  factory AuthSessionModel.fromJson(Map<String, dynamic> json) {
    final rawUser = json['user'];
    if (rawUser is! Map<String, dynamic>) {
      throw FormatException('Expected object for user, got $rawUser');
    }

    return AuthSessionModel(
      accessToken: requireString(json['accessToken'], 'accessToken'),
      tokenType: requireString(json['tokenType'], 'tokenType'),
      expiresIn: requireInt(json['expiresIn'], 'expiresIn'),
      user: UserModel.fromJson(rawUser),
    );
  }

  static const bearer = 'Bearer';

  final String accessToken;
  final String tokenType;
  final int expiresIn;
  final UserModel user;

  Duration get ttl => Duration(seconds: expiresIn);

  Map<String, Object?> toJson() => {
    'accessToken': accessToken,
    'tokenType': tokenType,
    'expiresIn': expiresIn,
    'user': {
      'id': user.id,
      'firstName': user.firstName,
      'lastName': user.lastName,
      'username': user.username,
      'avatarUrl': user.avatarUrl,
    },
  };
}
