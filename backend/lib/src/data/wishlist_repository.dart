import 'package:melist_backend/src/data/database.dart';
import 'package:melist_core/melist_core.dart';

class WishlistRepository {
  const WishlistRepository(this._db);

  static const _columns = '''
id, owner_id, name, description, color,
visibility::text AS visibility,
position, share_token, created_at, updated_at
''';

  static const _wishColumns = '''
w.id, w.owner_id, w.name, w.price, w.url, w.description, w.cover_url,
w.visibility::text AS visibility,
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

  Future<WishlistModel?> findById(int id) async {
    final row = await _db.querySingle(
      'SELECT $_columns FROM wishlists WHERE id = @id',
      {'id': id},
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
}
