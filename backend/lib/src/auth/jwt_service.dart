import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:melist_core/melist_core.dart';

class JwtService {
  const JwtService({
    required this.secret,
    this.accessTokenTtl = const Duration(hours: 1),
  });

  final String secret;
  final Duration accessTokenTtl;

  String issueAccessToken(UserDataModel user) {
    final jwt = JWT(
      {
        'firstName': user.firstName,
        'lastName': user.lastName,
        'username': user.username,
      },
      subject: '${user.id}',
    );

    return jwt.sign(SecretKey(secret), expiresIn: accessTokenTtl);
  }

  JWT verify(String token) {
    return JWT.verify(token, SecretKey(secret));
  }
}
