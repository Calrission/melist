/// One versioned schema change, embedded in the binary as a SQL script.
///
/// Migrations live in `lib/src/data/migrations/` and are listed in
/// `allMigrations`. Once a migration has been applied anywhere (dev DB,
/// production) its [sql] must never change — add a new [Migration] with the
/// next [version] instead.
class Migration {
  const Migration({
    required this.version,
    required this.name,
    required this.sql,
  });

  /// Strictly increasing positive integer; stored in `schema_migrations`.
  final int version;

  /// Short `snake_case` label, e.g. `init`, `add_wish_tags`.
  final String name;

  /// Multi-statement SQL, executed in a single transaction through the simple
  /// query protocol. Must be idempotent where PostgreSQL allows it
  /// (`IF NOT EXISTS`), so a partially created schema can be repaired.
  final String sql;

  /// `0001_init` — used in logs and for the `name` column.
  String get id => '${version.toString().padLeft(4, '0')}_$name';

  @override
  String toString() => 'Migration($id)';
}
