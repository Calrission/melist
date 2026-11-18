import 'package:melist_backend/src/data/database.dart';
import 'package:melist_core/melist_core.dart';

class FavoriteRepository {
  const FavoriteRepository(this._db);

  static const _wishlistColumns = '''
w.id, w.owner_id, w.name, w.description,
w.visibility::text AS visibility,
w.position, w.share_token, w.created_at, w.updated_at,
COALESCE(
  NULLIF(btrim(owner.nickname), ''),
  btrim(concat_ws(
    ' ',
    NULLIF(btrim(owner.first_name), ''),
    NULLIF(btrim(owner.last_name), '')
  ))
) AS owner_nickname
''';

  final DbExecutor _db;

  Future<List<WishlistModel>> listWishlists(int userId) async {
    final rows = await _db.query(
      '''
SELECT $_wishlistColumns
FROM favorites f
JOIN wishlists w ON w.id = f.wishlist_id
JOIN users owner ON owner.id = w.owner_id
WHERE f.user_id = @userId
ORDER BY f.position, w.id
''',
      {'userId': userId},
    );
    return [for (final row in rows) WishlistModel.fromRow(row)];
  }

  Future<int> maxPosition(int userId) {
    return _db.scalar<int>(
      '''
SELECT COALESCE(MAX(position), -1)::int
FROM favorites
WHERE user_id = @userId
''',
      {'userId': userId},
    );
  }

  Future<int> countByUser(int userId) {
    return _db.scalar<int>(
      'SELECT count(*)::int FROM favorites WHERE user_id = @userId',
      {'userId': userId},
    );
  }

  Future<int> countFavorited({
    required int userId,
    required List<int> ids,
  }) {
    if (ids.isEmpty) {
      return Future.value(0);
    }
    return _db.scalar<int>(
      '''
SELECT count(*)::int FROM favorites
WHERE user_id = @userId AND wishlist_id = ANY(@ids)
''',
      {'userId': userId, 'ids': ids},
    );
  }

  Future<bool> isFavorited({
    required int userId,
    required int wishlistId,
  }) async {
    final count = await _db.scalar<int>(
      '''
SELECT count(*)::int FROM favorites
WHERE user_id = @userId AND wishlist_id = @wishlistId
''',
      {'userId': userId, 'wishlistId': wishlistId},
    );
    return count > 0;
  }

  Future<void> insert({
    required int userId,
    required int wishlistId,
    required int position,
  }) async {
    await _db.execute(
      '''
INSERT INTO favorites (user_id, wishlist_id, position)
VALUES (@userId, @wishlistId, @position)
''',
      {
        'userId': userId,
        'wishlistId': wishlistId,
        'position': position,
      },
    );
  }

  Future<int> delete({
    required int userId,
    required int wishlistId,
  }) {
    return _db.execute(
      '''
DELETE FROM favorites
WHERE user_id = @userId AND wishlist_id = @wishlistId
''',
      {'userId': userId, 'wishlistId': wishlistId},
    );
  }

  Future<void> reorder({
    required int userId,
    required List<int> wishlistIds,
  }) async {
    for (var i = 0; i < wishlistIds.length; i++) {
      await _db.execute(
        '''
UPDATE favorites
SET position = @position
WHERE user_id = @userId AND wishlist_id = @wishlistId
''',
        {
          'position': i,
          'userId': userId,
          'wishlistId': wishlistIds[i],
        },
      );
    }
  }
}
