import 'package:melist_core/melist_core.dart';

abstract class IAuthRepository {
  Future<AuthSessionModel> login(AuthValidateBody body);

  /// Issues a new access JWT from the HttpOnly refresh cookie.
  Future<AuthSessionModel> refresh();

  Future<void> logout();

  /// Cookie refresh, then Telegram `initData`, then optional debug Bearer.
  Future<AuthSessionModel?> restoreSession({
    required String initData,
    bool allowDebug = false,
  });
}
