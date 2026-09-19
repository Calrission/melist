import 'package:mocktail/mocktail.dart';
import 'package:postgres/postgres.dart';

/// One recorded `execute` call.
typedef ExecuteCall = ({Object query, Object? parameters, bool ignoreRows});

/// Produces a [Result] for a recorded call; may throw to simulate errors.
typedef ExecuteHandler = Result Function(Object query, Object? parameters);

/// Records every `execute` call and answers via [onExecute]
/// (empty result when unset).
mixin RecordingSession on Fake implements Session {
  final calls = <ExecuteCall>[];
  ExecuteHandler? onExecute;

  /// SQL text of recorded calls; `Sql` objects (parameterised queries) are
  /// reported as `<Sql>` because the driver does not expose their text.
  List<String> get sqlTexts => [
    for (final c in calls)
      if (c.query case final String text) text else '<Sql>',
  ];

  @override
  Future<Result> execute(
    Object query, {
    Object? parameters,
    bool ignoreRows = false,
    QueryMode? queryMode,
    Duration? timeout,
  }) async {
    calls.add((query: query, parameters: parameters, ignoreRows: ignoreRows));
    final handler = onExecute;
    if (handler == null) {
      return makeResult(rows: const []);
    }
    return handler(query, parameters);
  }
}

class FakeTxSession extends Fake with RecordingSession implements TxSession {
  bool rolledBack = false;

  @override
  Future<void> rollback() async => rolledBack = true;
}

/// In-memory stand-in for a postgres [Pool]: no network, deterministic.
class FakePool extends Fake with RecordingSession implements Pool<Object?> {
  final tx = FakeTxSession();
  var _open = true;
  bool? closedWithForce;
  int transactions = 0;

  @override
  bool get isOpen => _open;

  @override
  Future<R> runTx<R>(
    Future<R> Function(TxSession session) fn, {
    TransactionSettings? settings,
    Object? locality,
  }) async {
    transactions++;
    try {
      return await fn(tx);
    } on Object {
      await tx.rollback();
      rethrow;
    }
  }

  @override
  Future<void> close({bool force = false}) async {
    _open = false;
    closedWithForce = force;
  }
}

/// Builds a [Result] with text-typed columns.
Result makeResult({
  required List<List<Object?>> rows,
  List<String> columns = const ['id', 'name'],
  int? affectedRows,
}) {
  final schema = ResultSchema([
    for (final name in columns)
      ResultSchemaColumn(typeOid: 25, type: Type.text, columnName: name),
  ]);
  return Result(
    rows: [
      for (final values in rows) ResultRow(values: values, schema: schema),
    ],
    affectedRows: affectedRows ?? rows.length,
    schema: schema,
  );
}
