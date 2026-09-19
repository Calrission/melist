import 'dart:async';

import 'package:melist_backend/src/data/database_config.dart';
import 'package:postgres/postgres.dart';

/// Row returned by [DbExecutor.query]: column name to decoded value.
typedef Row = Map<String, dynamic>;

/// Something that can run SQL: the shared [Database] pool or a transaction
/// handed to a `Database.transaction` callback.
///
/// Repositories in `lib/src/data/` depend on this interface, so the same code
/// works inside and outside transactions. SQL uses named parameters:
///
/// ```dart
/// final rows = await db.query(
///   'SELECT * FROM wishlists WHERE owner_id = @ownerId ORDER BY position',
///   {'ownerId': user.id},
/// );
/// ```
abstract interface class DbExecutor {
  /// Runs [sql] and returns all rows as column maps.
  Future<List<Row>> query(
    String sql, [
    Map<String, Object?> parameters = const {},
  ]);

  /// Runs [sql] and returns the first row or `null` when nothing matched.
  Future<Row?> querySingle(
    String sql, [
    Map<String, Object?> parameters = const {},
  ]);

  /// Runs [sql] and returns the first column of the first row.
  /// Throws [StateError] when no rows are returned.
  Future<T> scalar<T>(
    String sql, [
    Map<String, Object?> parameters = const {},
  ]);

  /// Runs [sql] ignoring returned rows; returns the number of affected rows.
  Future<int> execute(
    String sql, [
    Map<String, Object?> parameters = const {},
  ]);

  /// Runs a multi-statement SQL script (DDL, migrations) through the simple
  /// query protocol. Statements are separated by `;`; parameters are not
  /// supported, so never interpolate user input here.
  Future<void> executeScript(String sql);
}

/// Application-wide PostgreSQL access point backed by a connection [Pool].
///
/// Created once per process in `main.dart`, verified with [connect] before the
/// server starts listening, and exposed to handlers via
/// `context.read<Database>()`. Constructing the object itself never touches
/// the network; the pool opens connections on demand up to
/// `DatabaseConfig.maxConnections`.
class Database implements DbExecutor {
  /// Wraps an existing [Pool]. Useful in tests to inject a mock.
  Database(this._pool);

  /// Creates a pool from a parsed [DatabaseConfig].
  Database.fromConfig(DatabaseConfig config)
    : this(
        Pool.withEndpoints(
          [config.endpoint],
          settings: config.toPoolSettings(),
        ),
      );

  /// Creates a pool from a `DATABASE_URL` string, see [DatabaseConfig.parse].
  factory Database.fromUrl(String url) =>
      Database.fromConfig(DatabaseConfig.parse(url));

  final Pool<Object?> _pool;

  /// Whether the pool still accepts new sessions.
  bool get isOpen => _pool.isOpen;

  @override
  Future<List<Row>> query(
    String sql, [
    Map<String, Object?> parameters = const {},
  ]) => _query(_pool, sql, parameters);

  @override
  Future<Row?> querySingle(
    String sql, [
    Map<String, Object?> parameters = const {},
  ]) => _querySingle(_pool, sql, parameters);

  @override
  Future<T> scalar<T>(
    String sql, [
    Map<String, Object?> parameters = const {},
  ]) => _scalar<T>(_pool, sql, parameters);

  @override
  Future<int> execute(
    String sql, [
    Map<String, Object?> parameters = const {},
  ]) => _execute(_pool, sql, parameters);

  @override
  Future<void> executeScript(String sql) => _executeScript(_pool, sql);

  /// Runs [action] inside a single transaction on one connection.
  ///
  /// The transaction is committed when [action] completes and rolled back if
  /// it throws; the error is rethrown to the caller.
  Future<R> transaction<R>(
    Future<R> Function(DbExecutor tx) action, {
    TransactionSettings? settings,
  }) {
    return _pool.runTx(
      (session) => action(_TransactionExecutor(session)),
      settings: settings,
    );
  }

  /// Opens a connection and runs `SELECT 1`.
  ///
  /// Throws (`SocketException`, `ServerException`, `TimeoutException`, …)
  /// when the server is unreachable or credentials are wrong. Call it once on
  /// startup so a misconfigured `DATABASE_URL` stops the process immediately
  /// instead of failing on the first real request.
  Future<void> connect({Duration timeout = const Duration(seconds: 5)}) {
    return _pool.execute('SELECT 1', ignoreRows: true, timeout: timeout);
  }

  /// Returns `true` when the database answers `SELECT 1`.
  /// Never throws; intended for health checks.
  Future<bool> ping({Duration timeout = const Duration(seconds: 2)}) async {
    try {
      await connect(timeout: timeout);
      return true;
    } on Object {
      return false;
    }
  }

  /// Closes all pooled connections. With [force] pending queries are aborted.
  Future<void> close({bool force = false}) => _pool.close(force: force);
}

class _TransactionExecutor implements DbExecutor {
  _TransactionExecutor(this._session);

  final TxSession _session;

  @override
  Future<List<Row>> query(
    String sql, [
    Map<String, Object?> parameters = const {},
  ]) => _query(_session, sql, parameters);

  @override
  Future<Row?> querySingle(
    String sql, [
    Map<String, Object?> parameters = const {},
  ]) => _querySingle(_session, sql, parameters);

  @override
  Future<T> scalar<T>(
    String sql, [
    Map<String, Object?> parameters = const {},
  ]) => _scalar<T>(_session, sql, parameters);

  @override
  Future<int> execute(
    String sql, [
    Map<String, Object?> parameters = const {},
  ]) => _execute(_session, sql, parameters);

  @override
  Future<void> executeScript(String sql) => _executeScript(_session, sql);
}

Future<Result> _run(
  Session session,
  String sql,
  Map<String, Object?> parameters, {
  bool ignoreRows = false,
}) {
  // A plain String is passed through unchanged; Sql.named desugars `@name`.
  return session.execute(
    parameters.isEmpty ? sql : Sql.named(sql),
    parameters: parameters.isEmpty ? null : parameters,
    ignoreRows: ignoreRows,
  );
}

Future<void> _executeScript(Session session, String sql) {
  return session.execute(
    sql,
    ignoreRows: true,
    queryMode: QueryMode.simple,
  );
}

Future<List<Row>> _query(
  Session session,
  String sql,
  Map<String, Object?> parameters,
) async {
  final result = await _run(session, sql, parameters);
  return result.map((row) => row.toColumnMap()).toList(growable: false);
}

Future<Row?> _querySingle(
  Session session,
  String sql,
  Map<String, Object?> parameters,
) async {
  final result = await _run(session, sql, parameters);
  return result.isEmpty ? null : result.first.toColumnMap();
}

Future<T> _scalar<T>(
  Session session,
  String sql,
  Map<String, Object?> parameters,
) async {
  final result = await _run(session, sql, parameters);
  if (result.isEmpty || result.first.isEmpty) {
    throw StateError('Query returned no rows: $sql');
  }
  return result.first.first as T;
}

Future<int> _execute(
  Session session,
  String sql,
  Map<String, Object?> parameters,
) async {
  final result = await _run(session, sql, parameters, ignoreRows: true);
  return result.affectedRows;
}
