import 'package:dio/dio.dart';
import 'package:melist/domain/interfaces/i_auth_repository.dart';
import 'package:melist_core/melist_core.dart';

/// In-memory access JWT plus the only place that writes it.
///
/// The token survives neither F5 nor a new tab. Refresh lives in an HttpOnly cookie.
class AuthSession {
  AuthSession({required this._repository});

  final IAuthRepository _repository;
  String? _accessToken;

  String? get accessToken {
    final token = _accessToken;
    if (token == null || token.isEmpty) {
      return null;
    }
    return token;
  }

  bool get hasAccessToken => accessToken != null;

  void setAccessToken(String token) {
    _accessToken = token;
  }

  void clear() {
    _accessToken = null;
  }

  Future<AuthSessionModel> login(AuthValidateBody body) async {
    final issued = await _repository.login(body);
    setAccessToken(issued.accessToken);
    return issued;
  }

  /// Stores the new access JWT, or clears memory when refresh fails.
  Future<AuthSessionModel> refresh() async {
    try {
      final issued = await _repository.refresh();
      setAccessToken(issued.accessToken);
      return issued;
    } catch (error) {
      clear();
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      await _repository.logout();
    } finally {
      clear();
    }
  }

  /// Cookie refresh, then Telegram `initData`, then optional debug Bearer.
  Future<AuthSessionModel?> restoreSession({
    required String initData,
    bool allowDebug = false,
  }) async {
    try {
      return await refresh();
    } on DioException {
      // Refresh already cleared the in-memory token.
    }

    if (initData.isNotEmpty) {
      try {
        return await login(AuthValidateBody(initData: initData));
      } on DioException {
        // Fall through to debug Bearer when enabled.
      }
    }

    if (allowDebug) {
      try {
        final issued = await _repository.loginDebug();
        setAccessToken(issued.accessToken);
        return issued;
      } on DioException {
        return null;
      }
    }

    return null;
  }
}
