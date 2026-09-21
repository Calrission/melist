import 'package:melist_backend/melist_backend.dart';
import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

void main() {
  group('DatabaseConfig.parse', () {
    test('parses a full url', () {
      final config = DatabaseConfig.parse(
        'postgres://melist:s3cret@db.internal:6543/melist'
        '?sslmode=require&max_connections=20&connect_timeout=5'
        '&query_timeout=30&application_name=api',
      );

      expect(config.endpoint.host, equals('db.internal'));
      expect(config.endpoint.port, equals(6543));
      expect(config.endpoint.database, equals('melist'));
      expect(config.endpoint.username, equals('melist'));
      expect(config.endpoint.password, equals('s3cret'));
      expect(config.sslMode, equals(SslMode.require));
      expect(config.maxConnections, equals(20));
      expect(config.connectTimeout, equals(const Duration(seconds: 5)));
      expect(config.queryTimeout, equals(const Duration(seconds: 30)));
      expect(config.applicationName, equals('api'));
    });

    test('applies defaults', () {
      final config = DatabaseConfig.parse('postgresql://localhost/melist');

      expect(config.endpoint.host, equals('localhost'));
      expect(config.endpoint.port, equals(5432));
      expect(config.endpoint.username, isNull);
      expect(config.endpoint.password, isNull);
      expect(config.sslMode, equals(SslMode.disable));
      expect(
        config.maxConnections,
        equals(DatabaseConfig.defaultMaxConnections),
      );
      expect(config.connectTimeout, isNull);
      expect(config.queryTimeout, isNull);
      expect(
        config.applicationName,
        equals(DatabaseConfig.defaultApplicationName),
      );
    });

    test('decodes percent-encoded credentials', () {
      final config = DatabaseConfig.parse(
        'postgres://user%40corp:p%40ss%3Aword@localhost/melist',
      );

      expect(config.endpoint.username, equals('user@corp'));
      expect(config.endpoint.password, equals('p@ss:word'));
    });

    test('lets query parameters override user, password, port, database', () {
      final config = DatabaseConfig.parse(
        'postgres://a:b@localhost:1111/x'
        '?user=u&password=p&port=2222&database=melist',
      );

      expect(config.endpoint.username, equals('u'));
      expect(config.endpoint.password, equals('p'));
      expect(config.endpoint.port, equals(2222));
      expect(config.endpoint.database, equals('melist'));
    });

    test('maps libpq sslmode aliases', () {
      SslMode modeOf(String value) =>
          DatabaseConfig.parse('postgres://h/db?sslmode=$value').sslMode;

      expect(modeOf('disable'), equals(SslMode.disable));
      expect(modeOf('prefer'), equals(SslMode.require));
      expect(modeOf('verify-ca'), equals(SslMode.verifyFull));
      expect(modeOf('verify-full'), equals(SslMode.verifyFull));
    });

    test('produces pool settings', () {
      final settings = DatabaseConfig.parse(
        'postgres://h/db?max_connections=3&sslmode=require',
      ).toPoolSettings();

      expect(settings.maxConnectionCount, equals(3));
      expect(settings.sslMode, equals(SslMode.require));
      expect(
        settings.applicationName,
        equals(DatabaseConfig.defaultApplicationName),
      );
    });

    group('rejects', () {
      void expectRejected(String url, String fragment) {
        expect(
          () => DatabaseConfig.parse(url),
          throwsA(
            isA<FormatException>().having(
              (e) => e.message,
              'message',
              contains(fragment),
            ),
          ),
        );
      }

      test('empty url', () => expectRejected('  ', 'empty'));
      test('wrong scheme', () => expectRejected('mysql://h/db', 'postgres://'));
      test(
        'missing database',
        () => expectRejected('postgres://h', 'database'),
      );
      test(
        'unknown parameter',
        () => expectRejected('postgres://h/db?foo=1', 'unknown parameter'),
      );
      test(
        'invalid sslmode',
        () => expectRejected('postgres://h/db?sslmode=maybe', 'sslmode'),
      );
      test(
        'non-positive max_connections',
        () => expectRejected(
          'postgres://h/db?max_connections=0',
          'max_connections',
        ),
      );
      test(
        'invalid port parameter',
        () => expectRejected('postgres://h/db?port=99999', 'port'),
      );
    });
  });
}
