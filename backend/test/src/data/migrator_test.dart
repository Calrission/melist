import 'package:melist_backend/melist_backend.dart';
import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

import '../../helpers/fake_pool.dart';

const _m1 = Migration(version: 1, name: 'init', sql: 'CREATE TABLE a ();');
const _m2 = Migration(version: 2, name: 'add_b', sql: 'CREATE TABLE b ();');
const _m3 = Migration(version: 3, name: 'add_c', sql: 'CREATE TABLE c ();');

void main() {
  late FakePool pool;
  late Database db;
  late List<String> log;

  /// Makes the fake transaction report [applied] versions from
  /// `schema_migrations` and answer everything else with an empty result.
  void schemaHas(List<int> applied) {
    pool.tx.onExecute = (query, _) {
      if (query is String && query.contains('FROM schema_migrations')) {
        return makeResult(
          rows: [for (final v in applied) [v]],
          columns: ['version'],
        );
      }
      return makeResult(rows: const []);
    };
  }

  setUp(() {
    pool = FakePool();
    db = Database(pool);
    log = [];
  });

  Migrator migrator(List<Migration> migrations) =>
      Migrator(db, migrations: migrations, log: log.add);

  group('Migrator.migrate', () {
    test('creates schema_migrations and applies everything on an empty db',
        () async {
      schemaHas([]);

      final report = await migrator([_m1, _m2]).migrate();

      expect(report.applied, equals([_m1, _m2]));
      expect(report.currentVersion, equals(2));
      expect(report.wasUpToDate, isFalse);
      expect(report.unknownVersions, isEmpty);

      final sql = pool.tx.sqlTexts;
      expect(sql[0], contains('pg_advisory_xact_lock(${Migrator.lockKey})'));
      expect(sql[1], contains('CREATE TABLE IF NOT EXISTS schema_migrations'));
      expect(sql[2], contains('SELECT version FROM schema_migrations'));
      expect(sql[3], equals(_m1.sql));
      expect(sql[4], equals('<Sql>'), reason: 'INSERT into schema_migrations');
      expect(sql[5], equals(_m2.sql));
      expect(sql[6], equals('<Sql>'));
      expect(sql, hasLength(7));

      expect(
        pool.tx.calls[4].parameters,
        equals({'version': 1, 'name': 'init'}),
      );
      expect(pool.transactions, equals(1), reason: 'single transaction');
      expect(pool.calls, isEmpty, reason: 'nothing outside the transaction');
      expect(log, equals(['applying 0001_init', 'applying 0002_add_b']));
    });

    test('applies only pending migrations', () async {
      schemaHas([1]);

      final report = await migrator([_m1, _m2, _m3]).migrate();

      expect(report.applied, equals([_m2, _m3]));
      expect(report.currentVersion, equals(3));
      expect(pool.tx.sqlTexts, isNot(contains(_m1.sql)));
    });

    test('is a no-op when the schema is up to date', () async {
      schemaHas([1, 2]);

      final report = await migrator([_m1, _m2]).migrate();

      expect(report.wasUpToDate, isTrue);
      expect(report.currentVersion, equals(2));
      expect(pool.tx.sqlTexts, hasLength(3), reason: 'lock, create, select');
      expect(log, isEmpty);
      expect(report.toString(), equals('schema up to date (version 2)'));
    });

    test('reports versions the build does not know about', () async {
      schemaHas([1, 2, 5]);

      final report = await migrator([_m1, _m2]).migrate();

      expect(report.unknownVersions, equals([5]));
      expect(report.currentVersion, equals(5));
      expect(log.single, contains('unknown to this build: 5'));
    });

    test('sorts migrations by version regardless of list order', () async {
      schemaHas([]);

      final report = await migrator([_m3, _m1, _m2]).migrate();

      expect(report.applied, equals([_m1, _m2, _m3]));
    });

    test('rolls back and rethrows when a migration fails', () async {
      pool.tx.onExecute = (query, _) {
        if (query is String && query.contains('FROM schema_migrations')) {
          return makeResult(rows: const [], columns: ['version']);
        }
        if (query == _m2.sql) {
          throw PgException('syntax error at or near "TABL"');
        }
        return makeResult(rows: const []);
      };

      await expectLater(
        migrator([_m1, _m2]).migrate(),
        throwsA(isA<PgException>()),
      );

      expect(pool.tx.rolledBack, isTrue);
      expect(log, equals(['applying 0001_init', 'applying 0002_add_b']));
    });
  });

  group('Migrator validation', () {
    test('rejects duplicate versions', () {
      expect(
        () => migrator([
          _m1,
          const Migration(version: 1, name: 'again', sql: ''),
        ]),
        throwsArgumentError,
      );
    });

    test('rejects non-positive versions', () {
      expect(
        () => migrator([const Migration(version: 0, name: 'zero', sql: '')]),
        throwsArgumentError,
      );
    });

    test('rejects names that are not snake_case', () {
      expect(
        () => migrator([const Migration(version: 1, name: 'Init-1', sql: '')]),
        throwsArgumentError,
      );
    });
  });

  group('allMigrations', () {
    test('is valid and starts with 0001_init', () {
      final list = Migrator(db).migrations;

      expect(list.first.id, equals('0001_init'));
      expect(list.first.sql, contains('CREATE TABLE IF NOT EXISTS users'));
      expect(
        list.map((m) => m.version),
        equals(List.generate(list.length, (i) => i + 1)),
        reason: 'versions are contiguous',
      );
    });
  });
}
