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
