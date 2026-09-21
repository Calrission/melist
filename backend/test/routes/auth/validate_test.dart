import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:melist_backend/melist_backend.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../../../routes/auth/validate.dart' as route;
import '../../helpers/init_data.dart';
import '../../helpers/memory_wishlists.dart';

class _MockRequestContext extends Mock implements RequestContext {}

void main() {
  final now = DateTime.utc(2026, 9, 19, 8, 13);
  final validator = InitDataValidator(
    botToken: testBotToken,
    clock: () => now,
  );
  const jwtService = JwtService(secret: 'test-secret');

  late MemoryWishlistData usersData;
  late MemoryUserRepository users;

  RequestContext contextWith(Request request) {
    final context = _MockRequestContext();
    when(() => context.request).thenReturn(request);
    when(() => context.read<InitDataValidator>()).thenReturn(validator);
    when(() => context.read<JwtService>()).thenReturn(jwtService);
    when(() => context.read<UserRepository>()).thenReturn(users);
    return context;
  }

  setUp(() {
    usersData = MemoryWishlistData();
    users = MemoryUserRepository(usersData);
  });

  group('POST /auth/validate', () {
    test('responds with 405 when the method is not POST', () async {
      final context = contextWith(
        Request.get(Uri.parse('http://localhost/auth/validate')),
      );

      final response = await route.onRequest(context);

      expect(response.statusCode, equals(HttpStatus.methodNotAllowed));
    });

    test('responds with 400 when initData is missing', () async {
      final context = contextWith(
        Request.post(
          Uri.parse('http://localhost/auth/validate'),
          headers: {HttpHeaders.contentTypeHeader: 'application/json'},
          body: jsonEncode({'initData': ''}),
        ),
      );

      final response = await route.onRequest(context);
      final body = jsonDecode(await response.body()) as Map<String, dynamic>;

      expect(response.statusCode, equals(HttpStatus.badRequest));
      expect(body['error'], equals('initData is required'));
    });

    test('responds with 401 when the hash is invalid', () async {
      final context = contextWith(
        Request.post(
          Uri.parse('http://localhost/auth/validate'),
          headers: {HttpHeaders.contentTypeHeader: 'application/json'},
          body: jsonEncode({
            'initData': signInitData(
              authDate: unixSeconds(now),
              hashOverride: '0' * 64,
            ),
          }),
        ),
      );

      final response = await route.onRequest(context);
      final body = jsonDecode(await response.body()) as Map<String, dynamic>;

      expect(response.statusCode, equals(HttpStatus.unauthorized));
      expect(body['error'], equals('Invalid initData'));
    });

    test('responds with 401 when auth_date is older than 24 hours', () async {
      final context = contextWith(
        Request.post(
          Uri.parse('http://localhost/auth/validate'),
          headers: {HttpHeaders.contentTypeHeader: 'application/json'},
          body: jsonEncode({
            'initData': signInitData(
              authDate: unixSeconds(now.subtract(const Duration(hours: 25))),
            ),
          }),
        ),
      );

      final response = await route.onRequest(context);
      final body = jsonDecode(await response.body()) as Map<String, dynamic>;

      expect(response.statusCode, equals(HttpStatus.unauthorized));
      expect(body['error'], equals('Expired initData'));
    });

    test('responds with a JWT and user when initData is valid', () async {
      final context = contextWith(
        Request.post(
          Uri.parse('http://localhost/auth/validate'),
          headers: {HttpHeaders.contentTypeHeader: 'application/json'},
          body: jsonEncode({
            'initData': signInitData(authDate: unixSeconds(now)),
          }),
        ),
      );

      final response = await route.onRequest(context);
      final body = jsonDecode(await response.body()) as Map<String, dynamic>;
      final token = body['accessToken'] as String;
      final jwt = jwtService.verify(token);

      expect(response.statusCode, equals(HttpStatus.ok));
      expect(body['tokenType'], equals('Bearer'));
      expect(body['expiresIn'], equals(3600));
      expect(body['user'], equals({
        'id': 279058397,
        'firstName': 'Vladislav',
        'lastName': 'Kibenko',
        'username': 'vdkfrost',
        'avatarUrl': 'https://t.me/i/userpic/320/test.svg',
      }));
      expect(jwt.subject, equals('279058397'));
      expect(usersData.users[279058397]?.avatarUrl, equals(
        'https://t.me/i/userpic/320/test.svg',
      ));
    });
  });
}
