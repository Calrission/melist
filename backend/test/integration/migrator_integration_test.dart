@Tags(['integration'])
library;

import 'dart:io';

import 'package:melist_backend/melist_backend.dart';
import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

/// Runs the real migrations against a throw-away database.
///
/// Needs `TEST_DATABASE_URL` pointing at a PostgreSQL where the user may
/// `CREATE DATABASE` (the docker-compose `melist` user is a superuser):
///
/// ```powershell
/// $env:TEST_DATABASE_URL = 'postgres://melist:melist@localhost:5433/melist?sslmode=disable'
/// dart test test/integration
/// ```
///
/// Skipped when the variable is not set, so `dart test` stays green offline.
void main() {
  final adminUrl = Platform.environment['TEST_DATABASE_URL'];

  group(
    'Migrator on PostgreSQL',
    skip: adminUrl == null || adminUrl.isEmpty
        ? 'TEST_DATABASE_URL is not set'
        : null,
    () {
      late Database admin;
      late Database db;
      late String dbName;

      setUpAll(() async {
        final adminConfig = DatabaseConfig.parse(adminUrl!);
        admin = Database.fromConfig(adminConfig);
        dbName =
            'melist_migrator_test_${DateTime.now().millisecondsSinceEpoch}';
        await admin.executeScript('CREATE DATABASE $dbName');

        final endpoint = adminConfig.endpoint;
        db = Database.fromConfig(
          DatabaseConfig(
            endpoint: Endpoint(
              host: endpoint.host,
              port: endpoint.port,
              database: dbName,
              username: endpoint.username,
              password: endpoint.password,
            ),
            sslMode: adminConfig.sslMode,
            maxConnections: 2,
          ),
        );
      });

      tearDownAll(() async {
        await db.close(force: true);
        await admin.executeScript(
          'DROP DATABASE IF EXISTS $dbName WITH (FORCE)',
        );
        await admin.close();
      });

      test('creates the full schema on an empty database', () async {
        final report = await Migrator(db).migrate();

        expect(report.wasUpToDate, isFalse);
        expect(
          report.applied.map((m) => m.id),
          equals(['0001_init', '0002_refresh_tokens']),
        );
        expect(report.currentVersion, equals(allMigrations.last.version));

        final tables = await db.query('''
          SELECT table_name FROM information_schema.tables
          WHERE table_schema = 'public' ORDER BY table_name
        ''');
        expect(
          tables.map((r) => r['table_name']),
          containsAll([
            'schema_migrations',
            'users',
            'refresh_tokens',
            'wishlists',
            'wishes',
            'wishlist_wishes',
            'favorites',
            'wishlist_subscriptions',
            'user_subscriptions',
            'entitlements',
            'donations',
          ]),
        );

        final types = await db.query(
          "SELECT typname FROM pg_type WHERE typtype = 'e' ORDER BY typname",
        );
        expect(
          types.map((r) => r['typname']),
          containsAll([
            'wishlist_visibility',
            'wish_status',
            'ui_theme',
            'entitlement_source',
          ]),
        );
        expect(
          types.map((r) => r['typname']),
          isNot(contains('wish_visibility')),
        );

        final visibilityLabels = await db.query('''
          SELECT e.enumlabel
          FROM pg_enum e
          JOIN pg_type t ON t.oid = e.enumtypid
          WHERE t.typname = 'wishlist_visibility'
          ORDER BY e.enumsortorder
        ''');
        expect(
          visibilityLabels.map((r) => r['enumlabel']),
          equals(['public', 'draft', 'link']),
        );

        final wishColumns = await db.query('''
          SELECT column_name FROM information_schema.columns
          WHERE table_schema = 'public' AND table_name = 'wishes'
        ''');
        expect(
          wishColumns.map((r) => r['column_name']),
          isNot(contains('visibility')),
        );

        final versions = await db.query(
          'SELECT version, name FROM schema_migrations ORDER BY version',
        );
        expect(versions.first, containsPair('version', 1));
        expect(versions.first, containsPair('name', 'init'));
      });

      test('second run is a no-op', () async {
        final report = await Migrator(db).migrate();

        expect(report.wasUpToDate, isTrue);
        expect(report.currentVersion, equals(allMigrations.last.version));
      });

      test('schema accepts a basic insert chain', () async {
        final id = await db.transaction((tx) async {
          await tx.execute(
            'INSERT INTO users (id, first_name) VALUES (@id:int8, @name:text)',
            {'id': 1, 'name': 'Test'},
          );
          final wishlist = await tx.querySingle(
            'INSERT INTO wishlists (owner_id, name, color) '
            "VALUES (1, 'Birthday', '#ff0000') RETURNING id",
          );
          return wishlist!['id'] as int;
        });

        expect(id, greaterThan(0));
        expect(
          await db.scalar<int>('SELECT count(*)::int FROM wishlists'),
          equals(1),
        );
      });
    },
  );
}
