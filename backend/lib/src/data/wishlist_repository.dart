import 'package:melist_backend/src/data/database.dart';
import 'package:melist_core/melist_core.dart';
import 'package:postgres/postgres.dart';

class WishlistRepository {
  const WishlistRepository(this._db);

  static const _columns = '''
id, owner_id, name, description, color,
visibility::text AS visibility,
position, share_token, created_at, updated_at
''';

  static const _wishColumns = '''
w.id, w.owner_id, w.name, w.price, w.url, w.description, w.cover_url,
w.status::text AS status,
w.copied_from, w.created_at, w.updated_at
''';

  final DbExecutor _db;

  Future<List<WishlistModel>> listByOwner(int ownerId) async {
    final rows = await _db.query(
      '''
SELECT $_columns FROM wishlists
WHERE owner_id = @ownerId
ORDER BY position, id
''',
      {'ownerId': ownerId},
    );
    return [for (final row in rows) WishlistModel.fromRow(row)];
  }

  Future<List<WishlistModel>> listPublicByOwner(int ownerId) async {
    final rows = await _db.query(
      '''
SELECT $_columns FROM wishlists
WHERE owner_id = @ownerId
  AND visibility = CAST('public' AS wishlist_visibility)
ORDER BY position, id
''',
      {'ownerId': ownerId},
    );
    return [for (final row in rows) WishlistModel.fromRow(row)];
  }

  Future<WishlistModel?> findById(int id) async {
    final row = await _db.querySingle(
      'SELECT $_columns FROM wishlists WHERE id = @id',
      {'id': id},
    );
    return row == null ? null : WishlistModel.fromRow(row);
  }

  Future<WishlistModel?> findByShareToken(String token) async {
    final row = await _db.querySingle(
      'SELECT $_columns FROM wishlists WHERE share_token = @token',
      {'token': token},
    );
    return row == null ? null : WishlistModel.fromRow(row);
  }

  Future<int> maxPosition(int ownerId) {
    return _db.scalar<int>(
      '''
SELECT COALESCE(MAX(position), -1)::int
FROM wishlists
WHERE owner_id = @ownerId
''',
      {'ownerId': ownerId},
    );
  }

  Future<WishlistModel> insert({
    required int ownerId,
    required String name,
    required String color,
    required WishlistVisibility visibility,
    required int position,
    String? description,
  }) async {
    final row = await _db.querySingle(
      '''
INSERT INTO wishlists (
  owner_id, name, description, color, visibility, position
) VALUES (
  @ownerId,
  @name,
  @description,
  @color,
  CAST(@visibility AS wishlist_visibility),
  @position
)
RETURNING $_columns
''',
      {
        'ownerId': ownerId,
        'name': name,
        'description': description,
        'color': color,
        'visibility': visibility.name,
        'position': position,
      },
    );
    return WishlistModel.fromRow(row!);
  }

  /// Returns the updated row, or `null` when no owned row matched.
  Future<WishlistModel?> update({
    required int id,
    required int ownerId,
    String? name,
    String? description,
    bool clearDescription = false,
    String? color,
    WishlistVisibility? visibility,
  }) async {
    final sets = <String>['updated_at = now()'];
    final params = <String, Object?>{'id': id, 'ownerId': ownerId};

    if (name != null) {
      sets.add('name = @name');
      params['name'] = name;
    }
    if (clearDescription) {
      sets.add('description = NULL');
    } else if (description != null) {
      sets.add('description = @description');
      params['description'] = description;
    }
    if (color != null) {
      sets.add('color = @color');
      params['color'] = color;
    }
    if (visibility != null) {
      sets.add('visibility = CAST(@visibility AS wishlist_visibility)');
      params['visibility'] = visibility.name;
    }

    final row = await _db.querySingle(
      '''
UPDATE wishlists
SET ${sets.join(', ')}
WHERE id = @id AND owner_id = @ownerId
RETURNING $_columns
''',
      params,
    );
    return row == null ? null : WishlistModel.fromRow(row);
  }

  Future<int> delete({required int id, required int ownerId}) {
    return _db.execute(
      '''
DELETE FROM wishlists
WHERE id = @id AND owner_id = @ownerId
''',
      {'id': id, 'ownerId': ownerId},
    );
  }

  Future<int> deleteMany({
    required List<int> ids,
    required int ownerId,
  }) {
    if (ids.isEmpty) {
      return Future.value(0);
    }
    return _db.execute(
      '''
DELETE FROM wishlists
WHERE owner_id = @ownerId AND id = ANY(@ids)
''',
      {'ownerId': ownerId, 'ids': ids},
    );
  }

  Future<int> countByOwner(int ownerId) {
    return _db.scalar<int>(
      'SELECT count(*)::int FROM wishlists WHERE owner_id = @ownerId',
      {'ownerId': ownerId},
    );
  }

  Future<int> countOwnedWishlists({
    required int ownerId,
    required List<int> ids,
  }) {
    if (ids.isEmpty) {
      return Future.value(0);
    }
    return _db.scalar<int>(
      '''
SELECT count(*)::int FROM wishlists
WHERE owner_id = @ownerId AND id = ANY(@ids)
''',
      {'ownerId': ownerId, 'ids': ids},
    );
  }

  Future<void> reorder({
    required int ownerId,
    required List<int> ids,
  }) async {
    for (var i = 0; i < ids.length; i++) {
      await _db.execute(
        '''
UPDATE wishlists
SET position = @position, updated_at = now()
WHERE id = @id AND owner_id = @ownerId
''',
        {
          'position': i,
          'id': ids[i],
          'ownerId': ownerId,
        },
      );
    }
  }

  Future<String?> ensureShareToken({
    required int id,
    required int ownerId,
    required String Function() nextToken,
  }) async {
    for (var attempt = 0; attempt < 8; attempt++) {
      try {
        final row = await _db.querySingle(
          '''
UPDATE wishlists
SET share_token = COALESCE(share_token, @token),
    updated_at = now()
WHERE id = @id AND owner_id = @ownerId
RETURNING share_token
''',
          {
            'id': id,
            'ownerId': ownerId,
            'token': nextToken(),
          },
        );
        final token = row?['share_token'];
        return token is String ? token : null;
      } on UniqueViolationException {
        continue;
      }
    }
    throw StateError('Could not allocate a share token');
  }

  Future<int> countOwnedWishes({
    required int ownerId,
    required List<int> ids,
  }) {
    if (ids.isEmpty) {
      return Future.value(0);
    }
    return _db.scalar<int>(
      '''
SELECT count(*)::int FROM wishes
WHERE owner_id = @ownerId AND id = ANY(@ids)
''',
      {'ownerId': ownerId, 'ids': ids},
    );
  }

  Future<void> attachWishes({
    required int wishlistId,
    required List<int> wishIds,
  }) async {
    for (var i = 0; i < wishIds.length; i++) {
      await _db.execute(
        '''
INSERT INTO wishlist_wishes (wishlist_id, wish_id, position)
VALUES (@wishlistId, @wishId, @position)
''',
        {
          'wishlistId': wishlistId,
          'wishId': wishIds[i],
          'position': i,
        },
      );
    }
  }

  Future<List<WishModel>> listItems(int wishlistId) async {
    final rows = await _db.query(
      '''
SELECT $_wishColumns
FROM wishes w
JOIN wishlist_wishes ww ON ww.wish_id = w.id
WHERE ww.wishlist_id = @wishlistId
ORDER BY ww.position, w.id
''',
      {'wishlistId': wishlistId},
    );
    return [for (final row in rows) WishModel.fromRow(row)];
  }

  Future<int> maxItemPosition(int wishlistId) {
    return _db.scalar<int>(
      '''
SELECT COALESCE(MAX(position), -1)::int
FROM wishlist_wishes
WHERE wishlist_id = @wishlistId
''',
      {'wishlistId': wishlistId},
    );
  }

  Future<int> itemCount(int wishlistId) {
    return _db.scalar<int>(
      '''
SELECT count(*)::int FROM wishlist_wishes
WHERE wishlist_id = @wishlistId
''',
      {'wishlistId': wishlistId},
    );
  }

  Future<bool> isAttached({
    required int wishlistId,
    required int wishId,
  }) async {
    final count = await _db.scalar<int>(
      '''
SELECT count(*)::int FROM wishlist_wishes
WHERE wishlist_id = @wishlistId AND wish_id = @wishId
''',
      {'wishlistId': wishlistId, 'wishId': wishId},
    );
    return count > 0;
  }

  Future<int> countAttached({
    required int wishlistId,
    required List<int> ids,
  }) {
    if (ids.isEmpty) {
      return Future.value(0);
    }
    return _db.scalar<int>(
      '''
SELECT count(*)::int FROM wishlist_wishes
WHERE wishlist_id = @wishlistId AND wish_id = ANY(@ids)
''',
      {'wishlistId': wishlistId, 'ids': ids},
    );
  }

  Future<int> countPublicAppearances(int wishId) {
    return _db.scalar<int>(
      '''
SELECT count(*)::int
FROM wishlist_wishes ww
JOIN wishlists wl ON wl.id = ww.wishlist_id
WHERE ww.wish_id = @wishId
  AND wl.visibility = CAST('public' AS wishlist_visibility)
''',
      {'wishId': wishId},
    );
  }

  Future<void> attachWish({
    required int wishlistId,
    required int wishId,
    required int position,
  }) async {
    await _db.execute(
      '''
INSERT INTO wishlist_wishes (wishlist_id, wish_id, position)
VALUES (@wishlistId, @wishId, @position)
''',
      {
        'wishlistId': wishlistId,
        'wishId': wishId,
        'position': position,
      },
    );
  }

  Future<int> detachWish({
    required int wishlistId,
    required int wishId,
  }) {
    return _db.execute(
      '''
DELETE FROM wishlist_wishes
WHERE wishlist_id = @wishlistId AND wish_id = @wishId
''',
      {'wishlistId': wishlistId, 'wishId': wishId},
    );
  }

  Future<void> reorderItems({
    required int wishlistId,
    required List<int> wishIds,
  }) async {
    for (var i = 0; i < wishIds.length; i++) {
      await _db.execute(
        '''
UPDATE wishlist_wishes
SET position = @position
WHERE wishlist_id = @wishlistId AND wish_id = @wishId
''',
        {
          'position': i,
          'wishlistId': wishlistId,
          'wishId': wishIds[i],
        },
      );
    }
  }
}
