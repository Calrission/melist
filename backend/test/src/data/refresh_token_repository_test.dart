import 'package:melist_backend/melist_backend.dart';
import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

import '../../helpers/fake_pool.dart';

void main() {
  late FakePool pool;
  late RefreshTokenRepository repo;
  final expiresAt = DateTime.utc(2026, 9, 29, 12);

  setUp(() {
    pool = FakePool();
    repo = RefreshTokenRepository(Database(pool));
  });

  test('insert returns the new id', () async {
    pool.onExecute = (_, _) => makeResult(
      rows: [
        [11],
      ],
      columns: ['id'],
    );

    final id = await repo.insert(
      userId: 7,
      tokenHash: 'abc',
      expiresAt: expiresAt,
    );

    expect(id, 11);
    expect(pool.calls.single.parameters, {
      'userId': 7,
      'tokenHash': 'abc',
      'expiresAt': expiresAt,
    });
  });

  test('findByHash maps a row', () async {
    pool.onExecute = (_, _) => makeResult(
      rows: [
        [1, 7, 'abc', expiresAt, null, null],
      ],
      columns: [
        'id',
        'user_id',
        'token_hash',
        'expires_at',
        'revoked_at',
        'replaced_by',
      ],
    );

    final row = await repo.findByHash('abc');

    expect(row, isNotNull);
    expect(row!.id, 1);
    expect(row.userId, 7);
    expect(row.tokenHash, 'abc');
    expect(row.expiresAt, expiresAt);
    expect(row.isRevoked, isFalse);
    expect(pool.calls.single.parameters, {'tokenHash': 'abc'});
  });

  test('findByHash returns null when missing', () async {
    expect(await repo.findByHash('nope'), isNull);
  });

  test('revoke passes replacedBy', () async {
    await repo.revoke(
      3,
      revokedAt: expiresAt,
      replacedBy: 9,
    );

    expect(pool.calls.single.parameters, {
      'id': 3,
      'revokedAt': expiresAt,
      'replacedBy': 9,
    });
  });

  test('revokeAllForUser targets active rows of that user', () async {
    await repo.revokeAllForUser(7, revokedAt: expiresAt);

    expect(pool.calls.single.parameters, {
      'userId': 7,
      'revokedAt': expiresAt,
    });
    expect(pool.calls.single.query, isA<Sql>());
  });
}
