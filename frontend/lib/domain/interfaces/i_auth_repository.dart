import 'package:melist_core/melist_core.dart';

abstract class IAuthRepository {
  Future<AuthSessionModel> login(AuthValidateBody body);

  /// Issues a new access JWT from the HttpOnly refresh cookie.
  Future<AuthSessionModel> refresh();

  Future<void> logout();

  /// Debug Bearer from `GET /auth/debug`. Does not touch the in-memory token.
  Future<AuthSessionModel> loginDebug();
}
