import 'package:flutter_test/flutter_test.dart';
import 'package:melist/data/auth/auth_session.dart';

void main() {
  test('holds an access token only in memory', () {
    final session = AuthSession();

    expect(session.hasAccessToken, isFalse);
    session.setAccessToken('jwt');
    expect(session.accessToken, 'jwt');
    expect(session.hasAccessToken, isTrue);

    session.clear();
    expect(session.accessToken, isNull);
    expect(session.hasAccessToken, isFalse);
  });

  test('treats an empty token as missing', () {
    final session = AuthSession()..setAccessToken('');
    expect(session.accessToken, isNull);
  });
}
