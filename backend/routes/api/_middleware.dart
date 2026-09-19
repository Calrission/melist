import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_auth/dart_frog_auth.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:melist_backend/melist_backend.dart';

/// Protects every route under `/api` with `Authorization: Bearer <jwt>`.
/// On success the decoded [AuthUser] is available via
/// `context.read<AuthUser>()`.
Handler middleware(Handler handler) {
  return handler.use(
    bearerAuthentication<AuthUser>(
      authenticator: (context, token) async {
        final jwtService = context.read<JwtService>();
        try {
          return AuthUser.fromJwt(jwtService.verify(token));
        } on JWTException {
          return null;
        }
      },
    ),
  );
}
