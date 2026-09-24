import 'package:melist_backend/src/data/database.dart';

class RefreshTokenRecord {
  const RefreshTokenRecord({
    required this.id,
    required this.userId,
    required this.tokenHash,
    required this.expiresAt,
    this.revokedAt,
    this.replacedBy,
  });

  factory RefreshTokenRecord.fromRow(Row row) {
    return RefreshTokenRecord(
      id: row['id'] as int,
      userId: row['user_id'] as int,
      tokenHash: row['token_hash'] as String,
      expiresAt: row['expires_at'] as DateTime,
      revokedAt: row['revoked_at'] as DateTime?,
      replacedBy: row['replaced_by'] as int?,
    );
  }

  final int id;
  final int userId;
  final String tokenHash;
  final DateTime expiresAt;
  final DateTime? revokedAt;
  final int? replacedBy;

  bool get isRevoked => revokedAt != null;
}

class RefreshTokenRepository {
  const RefreshTokenRepository(this._db);

  final DbExecutor _db;

  Future<int> insert({
    required int userId,
    required String tokenHash,
    required DateTime expiresAt,
  }) {
    return _db.scalar<int>(
      '''
INSERT INTO refresh_tokens (user_id, token_hash, expires_at)
VALUES (@userId, @tokenHash, @expiresAt)
RETURNING id
''',
      {
        'userId': userId,
        'tokenHash': tokenHash,
        'expiresAt': expiresAt,
      },
    );
  }

  Future<RefreshTokenRecord?> findByHash(String tokenHash) async {
    final row = await _db.querySingle(
      '''
SELECT id, user_id, token_hash, expires_at, revoked_at, replaced_by
FROM refresh_tokens
WHERE token_hash = @tokenHash
''',
      {'tokenHash': tokenHash},
    );
    return row == null ? null : RefreshTokenRecord.fromRow(row);
  }

  Future<void> revoke(
    int id, {
    required DateTime revokedAt,
    int? replacedBy,
  }) {
    return _db.execute(
      '''
UPDATE refresh_tokens
SET revoked_at = COALESCE(revoked_at, @revokedAt),
    replaced_by = COALESCE(@replacedBy, replaced_by)
WHERE id = @id
''',
      {
        'id': id,
        'revokedAt': revokedAt,
        'replacedBy': replacedBy,
      },
    );
  }

  Future<void> revokeAllForUser(int userId, {required DateTime revokedAt}) {
    return _db.execute(
      '''
UPDATE refresh_tokens
SET revoked_at = COALESCE(revoked_at, @revokedAt)
WHERE user_id = @userId AND revoked_at IS NULL
''',
      {'userId': userId, 'revokedAt': revokedAt},
    );
  }
}
