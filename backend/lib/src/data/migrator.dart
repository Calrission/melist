import 'package:melist_backend/src/data/database.dart';
import 'package:melist_backend/src/data/migration.dart';
import 'package:melist_backend/src/data/migrations/migrations.dart';

/// Outcome of [Migrator.migrate].
class MigrationReport {
  const MigrationReport({
    required this.applied,
    required this.currentVersion,
    required this.unknownVersions,
  });

  /// Migrations applied during this run, in order. Empty when the schema was
  /// already up to date.
  final List<Migration> applied;

  /// Highest version recorded in `schema_migrations` after the run
  /// (`0` for an empty database with no migrations).
  final int currentVersion;

  /// Versions present in `schema_migrations` that this binary does not know
  /// about — the database was migrated by a newer build.
  final List<int> unknownVersions;

  bool get wasUpToDate => applied.isEmpty;

  @override
  String toString() {
    if (wasUpToDate) {
      return 'schema up to date (version $currentVersion)';
    }
    return 'applied ${applied.map((m) => m.id).join(', ')} '
        '(now at version $currentVersion)';
  }
}

/// Brings the database schema up to the version compiled into the binary.
///
/// Runs on startup from `main.dart`. The whole run happens in one transaction
/// guarded by a transaction-level advisory lock, so several instances
/// starting at once cannot apply the same migration twice, and a failing
/// migration leaves the schema untouched (PostgreSQL DDL is transactional).
class Migrator {
  Migrator(
    this._db, {
    List<Migration> migrations = allMigrations,
    void Function(String message)? log,
  }) : _migrations = _validated(migrations),
       _log = log ?? _noop;

  /// Arbitrary constant; must differ from other advisory locks the app uses.
  static const lockKey = 7264051;

  static const _createTableSql = '''
CREATE TABLE IF NOT EXISTS schema_migrations (
  version     INTEGER PRIMARY KEY,
  name        TEXT NOT NULL,
  applied_at  TIMESTAMPTZ NOT NULL DEFAULT now()
)''';

  final Database _db;
  final List<Migration> _migrations;
  final void Function(String message) _log;

  /// Migrations this instance knows about, sorted by version.
  List<Migration> get migrations => List.unmodifiable(_migrations);

  /// Applies every migration whose version is not yet in `schema_migrations`.
  ///
  /// Throws (and rolls back everything) when a migration fails.
  Future<MigrationReport> migrate() {
    return _db.transaction((tx) async {
      await tx.execute('SELECT pg_advisory_xact_lock($lockKey)');
      await tx.execute(_createTableSql);

      final rows = await tx.query(
        'SELECT version FROM schema_migrations ORDER BY version',
      );
      final appliedVersions = rows.map((r) => r['version'] as int).toSet();
      final knownVersions = _migrations.map((m) => m.version).toSet();

      final unknown = appliedVersions.difference(knownVersions).toList()
        ..sort();
      if (unknown.isNotEmpty) {
        _log(
          'schema_migrations contains versions unknown to this build: '
          '${unknown.join(', ')} — database is ahead of the code',
        );
      }

      final pending = _migrations
          .where((m) => !appliedVersions.contains(m.version))
          .toList();

      for (final migration in pending) {
        _log('applying ${migration.id}');
        await tx.executeScript(migration.sql);
        await tx.execute(
          'INSERT INTO schema_migrations (version, name) '
          'VALUES (@version:int4, @name:text)',
          {'version': migration.version, 'name': migration.name},
        );
      }

      final all = {...appliedVersions, ...pending.map((m) => m.version)};
      return MigrationReport(
        applied: pending,
        currentVersion: all.isEmpty ? 0 : all.reduce((a, b) => a > b ? a : b),
        unknownVersions: unknown,
      );
    });
  }

  static List<Migration> _validated(List<Migration> migrations) {
    final sorted = [...migrations]
      ..sort((a, b) => a.version.compareTo(b.version));
    final seen = <int>{};
    for (final m in sorted) {
      if (m.version <= 0) {
        throw ArgumentError('Migration version must be positive: $m');
      }
      if (!seen.add(m.version)) {
        throw ArgumentError('Duplicate migration version ${m.version}');
      }
      if (m.name.isEmpty || !RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(m.name)) {
        throw ArgumentError('Migration name must be snake_case: $m');
      }
    }
    return sorted;
  }

  static void _noop(String _) {}
}
