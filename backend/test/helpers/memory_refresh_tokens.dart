import 'package:melist_backend/melist_backend.dart';
import 'package:mocktail/mocktail.dart';

class MemoryRefreshTokenRepository implements RefreshTokenRepository {
  final List<RefreshTokenRecord> rows = <RefreshTokenRecord>[];
  int nextId = 1;

  @override
  Future<int> insert({
    required int userId,
    required String tokenHash,
    required DateTime expiresAt,
  }) async {
    final id = nextId++;
    rows.add(
      RefreshTokenRecord(
        id: id,
        userId: userId,
        tokenHash: tokenHash,
        expiresAt: expiresAt,
      ),
    );
    return id;
  }

  @override
  Future<RefreshTokenRecord?> findByHash(String tokenHash) async {
    for (final row in rows) {
      if (row.tokenHash == tokenHash) {
        return row;
      }
    }
    return null;
  }

  @override
  Future<void> revoke(
    int id, {
    required DateTime revokedAt,
    int? replacedBy,
  }) async {
    final index = rows.indexWhere((row) => row.id == id);
    if (index < 0) {
      return;
    }
    final current = rows[index];
    rows[index] = RefreshTokenRecord(
      id: current.id,
      userId: current.userId,
      tokenHash: current.tokenHash,
      expiresAt: current.expiresAt,
      revokedAt: current.revokedAt ?? revokedAt,
      replacedBy: replacedBy ?? current.replacedBy,
    );
  }

  @override
  Future<void> revokeAllForUser(
    int userId, {
    required DateTime revokedAt,
  }) async {
    final ids = [
      for (final row in rows)
        if (row.userId == userId && !row.isRevoked) row.id,
    ];
    for (final id in ids) {
      await revoke(id, revokedAt: revokedAt);
    }
  }
}

class _UnusedExecutor extends Fake implements DbExecutor {}

AuthSessionService memoryAuthSessionService({
  required JwtService jwtService,
  required UserRepository users,
  required MemoryRefreshTokenRepository tokens,
  Duration refreshTtl = const Duration(days: 7),
  String Function()? newRefreshToken,
  DateTime Function()? clock,
}) {
  return AuthSessionService(
    jwtService: jwtService,
    refreshTtl: refreshTtl,
    db: _UnusedExecutor(),
    tokens: (_) => tokens,
    users: (_) => users,
    newRefreshToken: newRefreshToken,
    clock: clock,
  );
}
