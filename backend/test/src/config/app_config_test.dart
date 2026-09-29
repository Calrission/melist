import 'dart:io';

import 'package:melist_backend/melist_backend.dart';
import 'package:test/test.dart';

void main() {
  late Directory tmp;
  late String envFile;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('melist_app_config_');
    envFile = '${tmp.path}${Platform.pathSeparator}.env';
    File(envFile).writeAsStringSync('''
BOT_TOKEN=file-bot
JWT_SECRET=file-jwt
DATABASE_URL=postgres://file@localhost/melist
''');
  });

  tearDown(() => tmp.deleteSync(recursive: true));

  group('AppConfig.load', () {
    test('reads values from the .env file', () {
      final config = AppConfig.load(files: [envFile], environment: const {});

      expect(config.botToken, equals('file-bot'));
      expect(config.jwtSecret, equals('file-jwt'));
      expect(config.databaseUrl, equals('postgres://file@localhost/melist'));
    });

    test('process environment overrides the file', () {
      final config = AppConfig.load(
        files: [envFile],
        environment: const {
          'DATABASE_URL': 'postgres://env@db:5432/melist',
          'JWT_SECRET': 'env-jwt',
        },
      );

      expect(config.databaseUrl, equals('postgres://env@db:5432/melist'));
      expect(config.jwtSecret, equals('env-jwt'));
      expect(config.botToken, equals('file-bot'), reason: 'not overridden');
    });

    test('works without a file when everything is in the environment', () {
      final config = AppConfig.load(
        files: ['${tmp.path}${Platform.pathSeparator}missing.env'],
        environment: const {
          'BOT_TOKEN': 'env-bot',
          'JWT_SECRET': 'env-jwt',
          'DATABASE_URL': 'postgres://env@db/melist',
        },
      );

      expect(config.botToken, equals('env-bot'));
    });

    test('debug auth is off unless DEBUG_AUTH is set', () {
      final config = AppConfig.load(files: [envFile], environment: const {});

      expect(config.debugAuth, isFalse);
      expect(config.debugToken, isNull);
      expect(config.debugUserId, equals(1));
      expect(config.botUsername, equals('melist_bot'));
    });

    test('reads optional debug auth settings', () {
      File(envFile).writeAsStringSync('''
BOT_TOKEN=file-bot
JWT_SECRET=file-jwt
DATABASE_URL=postgres://file@localhost/melist
DEBUG_AUTH=true
DEBUG_TOKEN=local-admin
DEBUG_USER_ID=42
''');

      final config = AppConfig.load(files: [envFile], environment: const {});

      expect(config.debugAuth, isTrue);
      expect(config.debugToken, equals('local-admin'));
      expect(config.debugUserId, equals(42));
    });

    test('reads BOT_USERNAME and strips a leading @', () {
      File(envFile).writeAsStringSync('''
BOT_TOKEN=file-bot
JWT_SECRET=file-jwt
DATABASE_URL=postgres://file@localhost/melist
BOT_USERNAME=@custom_bot
''');

      final config = AppConfig.load(files: [envFile], environment: const {});

      expect(config.botUsername, equals('custom_bot'));
    });

    test('treats 1 and yes as DEBUG_AUTH enabled', () {
      File(envFile).writeAsStringSync('''
BOT_TOKEN=file-bot
JWT_SECRET=file-jwt
DATABASE_URL=postgres://file@localhost/melist
DEBUG_AUTH=yes
''');

      expect(
        AppConfig.load(files: [envFile], environment: const {}).debugAuth,
        isTrue,
      );
    });

    test('fails when DEBUG_USER_ID is not a positive integer', () {
      File(envFile).writeAsStringSync('''
BOT_TOKEN=file-bot
JWT_SECRET=file-jwt
DATABASE_URL=postgres://file@localhost/melist
DEBUG_USER_ID=0
''');

      expect(
        () => AppConfig.load(files: [envFile], environment: const {}),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('DEBUG_USER_ID'),
          ),
        ),
      );
    });

    test('fails when ACCESS_TOKEN_TTL_SECONDS is not a positive integer', () {
      File(envFile).writeAsStringSync('''
BOT_TOKEN=file-bot
JWT_SECRET=file-jwt
DATABASE_URL=postgres://file@localhost/melist
ACCESS_TOKEN_TTL_SECONDS=0
''');

      expect(
        () => AppConfig.load(files: [envFile], environment: const {}),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('ACCESS_TOKEN_TTL_SECONDS'),
          ),
        ),
      );
    });

    test('reads token TTLs, cookie Secure, and CORS origins', () {
      File(envFile).writeAsStringSync('''
BOT_TOKEN=file-bot
JWT_SECRET=file-jwt
DATABASE_URL=postgres://file@localhost/melist
ACCESS_TOKEN_TTL_SECONDS=600
REFRESH_TOKEN_TTL_SECONDS=1209600
COOKIE_SECURE=true
CORS_ORIGINS=http://localhost:8081, https://app.example
WEB_ROOT=C:/web
''');

      final config = AppConfig.load(files: [envFile], environment: const {});

      expect(config.accessTokenTtl, const Duration(seconds: 600));
      expect(config.refreshTokenTtl, const Duration(days: 14));
      expect(config.cookieSecure, isTrue);
      expect(
        config.corsOrigins,
        equals(['http://localhost:8081', 'https://app.example']),
      );
      expect(config.webRoot, equals('C:/web'));
    });

    test('defaults TTLs and empty CORS when unset', () {
      final config = AppConfig.load(files: [envFile], environment: const {});

      expect(config.accessTokenTtl, const Duration(minutes: 15));
      expect(config.refreshTokenTtl, const Duration(days: 7));
      expect(config.cookieSecure, isFalse);
      expect(config.corsOrigins, isEmpty);
      expect(config.webRoot, isNull);
    });

    test('fails when a required variable is missing or empty', () {
      File(envFile).writeAsStringSync('BOT_TOKEN=x\nJWT_SECRET=\n');

      expect(
        () => AppConfig.load(files: [envFile], environment: const {}),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('JWT_SECRET'),
          ),
        ),
      );
    });
  });
}
