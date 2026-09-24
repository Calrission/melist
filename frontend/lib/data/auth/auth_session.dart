/// In-memory access JWT. Survives neither F5 nor a new tab.
class AuthSession {
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
}
