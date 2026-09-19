import 'package:melist_backend/melist_backend.dart';
import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

import '../../helpers/fake_pool.dart';

void main() {
  late FakePool pool;
  late Database db;

  setUp(() {
    pool = FakePool();
    db = Database(pool);
  });

  group('Database', () {
    test('query returns rows as column maps', () async {
      pool.onExecute = (_, _) => makeResult(
        rows: [
          [1, 'Birthday'],
          [2, 'New Year'],
        ],
      );

      final rows = await db.query(
        'SELECT id, name FROM wishlists WHERE owner_id = @ownerId',
        {'ownerId': 7},
      );

      expect(rows, [
        {'id': 1, 'name': 'Birthday'},
        {'id': 2, 'name': 'New Year'},
      ]);
      expect(pool.calls, hasLength(1));
      expect(pool.calls.single.query, isA<Sql>());
      expect(pool.calls.single.parameters, equals({'ownerId': 7}));
      expect(pool.calls.single.ignoreRows, isFalse);
    });

    test('query without parameters passes the raw string', () async {
      await db.query('SELECT 1');

      expect(pool.calls.single.query, equals('SELECT 1'));
      expect(pool.calls.single.parameters, isNull);
    });

    test('querySingle returns first row or null', () async {
      pool.onExecute = (_, _) => makeResult(
        rows: [
          [1, 'Birthday'],
        ],
      );
      expect(
        await db.querySingle('SELECT ... WHERE id = @id', {'id': 1}),
        equals({'id': 1, 'name': 'Birthday'}),
      );

      pool.onExecute = (_, _) => makeResult(rows: const []);
      expect(
        await db.querySingle('SELECT ... WHERE id = @id', {'id': 404}),
        isNull,
      );
    });

    test('scalar returns the first column of the first row', () async {
      pool.onExecute = (_, _) => makeResult(
        rows: [
          [3],
        ],
        columns: ['count'],
      );

      expect(await db.scalar<int>('SELECT count(*) FROM wishes'), equals(3));
    });

    test('scalar throws when nothing is returned', () async {
      pool.onExecute = (_, _) => makeResult(rows: const []);

      expect(
        () => db.scalar<int>('SELECT id FROM wishes WHERE false'),
        throwsStateError,
      );
    });

    test('execute ignores rows and reports affected count', () async {
      pool.onExecute = (_, _) => makeResult(rows: const [], affectedRows: 2);

      final affected = await db.execute(
        'DELETE FROM wishes WHERE owner_id = @ownerId',
        {'ownerId': 7},
      );

      expect(affected, equals(2));
      expect(pool.calls.single.ignoreRows, isTrue);
    });

    test('executeScript passes the script through unchanged', () async {
      const script = 'CREATE TABLE a (id int); CREATE TABLE b (id int);';

      await db.executeScript(script);

      expect(pool.calls.single.query, equals(script));
      expect(pool.calls.single.parameters, isNull);
      expect(pool.calls.single.ignoreRows, isTrue);
    });

    test('transaction runs statements on the transaction session', () async {
      pool.tx.onExecute = (_, _) => makeResult(
        rows: [
          [10],
        ],
        columns: ['id'],
      );

      final id = await db.transaction((tx) async {
        await tx.execute('INSERT INTO wishes (name) VALUES (@name)', {
          'name': 'Book',
        });
        return tx.scalar<int>('SELECT lastval()');
      });

      expect(id, equals(10));
      expect(pool.tx.calls, hasLength(2));
      expect(pool.calls, isEmpty, reason: 'nothing runs outside the tx');
      expect(pool.tx.rolledBack, isFalse);
    });

    test('transaction rolls back and rethrows on failure', () async {
      await expectLater(
        db.transaction<void>((tx) async {
          await tx.execute('UPDATE wishes SET name = @n', {'n': 'x'});
          throw StateError('boom');
        }),
        throwsStateError,
      );

      expect(pool.tx.rolledBack, isTrue);
    });

    test('connect runs SELECT 1 and rethrows connection errors', () async {
      await db.connect();
      expect(pool.calls.single.query, equals('SELECT 1'));

      pool.onExecute = (_, _) => throw PgException('connection refused');
      await expectLater(db.connect(), throwsA(isA<PgException>()));
    });

    test('ping returns true on success and false on error', () async {
      expect(await db.ping(), isTrue);
      expect(pool.calls.single.ignoreRows, isTrue);

      pool.onExecute = (_, _) => throw PgException('connection refused');
      expect(await db.ping(), isFalse);
    });

    test('close delegates to the pool', () async {
      expect(db.isOpen, isTrue);

      await db.close(force: true);

      expect(db.isOpen, isFalse);
      expect(pool.closedWithForce, isTrue);
    });
  });

  group('Database.fromUrl', () {
    test('builds a pool without opening connections', () {
      final database = Database.fromUrl('postgres://localhost/melist');

      expect(database.isOpen, isTrue);
    });

    test('rejects malformed urls eagerly', () {
      expect(
        () => Database.fromUrl('postgres://localhost'),
        throwsFormatException,
      );
    });
  });
}
