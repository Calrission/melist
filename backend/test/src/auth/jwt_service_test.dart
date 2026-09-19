import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:melist_backend/melist_backend.dart';
import 'package:melist_core/melist_core.dart';
import 'package:test/test.dart';

void main() {
  const service = JwtService(secret: 'test-secret');

  const user = UserModel(
    id: 279058397,
    firstName: 'Vladislav',
    lastName: 'Kibenko',
    username: 'vdkfrost',
    avatarUrl: 'https://t.me/i/userpic/320/test.svg',
  );

  test('issues a verifiable access token with Telegram user claims', () {
    final token = service.issueAccessToken(user);
    final jwt = service.verify(token);

    final payload = jwt.payload as Map<String, dynamic>;
    expect(jwt.subject, equals('279058397'));
    expect(payload['username'], equals('vdkfrost'));
    expect(payload['firstName'], equals('Vladislav'));
  });

  test('rejects a token signed with a different secret', () {
    final token = service.issueAccessToken(user);

    expect(
      () => const JwtService(secret: 'other-secret').verify(token),
      throwsA(isA<JWTException>()),
    );
  });
}
