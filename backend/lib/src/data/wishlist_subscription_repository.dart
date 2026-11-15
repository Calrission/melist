import 'package:melist_backend/src/data/database.dart';
import 'package:melist_core/melist_core.dart';

class WishlistSubscriptionRepository {
  const WishlistSubscriptionRepository(this._db);

  static const _wishlistColumns = '''
w.id, w.owner_id, w.name, w.description, w.cover_url,
w.visibility::text AS visibility,
w.position, w.share_token, w.created_at, w.updated_at
''';

  final DbExecutor _db;

  Future<List<WishlistModel>> listWishlists(int userId) async {
    final rows = await _db.query(
      '''
SELECT $_wishlistColumns
FROM wishlist_subscriptions s
JOIN wishlists w ON w.id = s.wishlist_id
WHERE s.user_id = @userId
  AND w.visibility = CAST('public' AS wishlist_visibility)
ORDER BY s.created_at DESC, w.id
''',
      {'userId': userId},
    );
    return [for (final row in rows) WishlistModel.fromRow(row)];
  }

  Future<bool> exists({
    required int userId,
    required int wishlistId,
  }) async {
    final count = await _db.scalar<int>(
      '''
SELECT count(*)::int FROM wishlist_subscriptions
WHERE user_id = @userId AND wishlist_id = @wishlistId
''',
      {'userId': userId, 'wishlistId': wishlistId},
    );
    return count > 0;
  }

  Future<void> insert({
    required int userId,
    required int wishlistId,
  }) {
    return _db.execute(
      '''
INSERT INTO wishlist_subscriptions (user_id, wishlist_id)
VALUES (@userId, @wishlistId)
''',
      {'userId': userId, 'wishlistId': wishlistId},
    );
  }

  Future<int> delete({
    required int userId,
    required int wishlistId,
  }) {
    return _db.execute(
      '''
DELETE FROM wishlist_subscriptions
WHERE user_id = @userId AND wishlist_id = @wishlistId
''',
      {'userId': userId, 'wishlistId': wishlistId},
    );
  }
}
