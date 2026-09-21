import 'package:melist_backend/src/data/database.dart';
import 'package:melist_core/melist_core.dart';

class WishRepository {
  const WishRepository(this._db);

  static const _columns = '''
id, owner_id, name, price, url, description, cover_url,
visibility::text AS visibility,
status::text AS status,
copied_from, created_at, updated_at
''';

  final DbExecutor _db;

  Future<List<WishModel>> listByOwner({
    required int ownerId,
    required int limit,
    required int offset,
    String? query,
  }) async {
    final params = <String, Object?>{
      'ownerId': ownerId,
      'limit': limit,
      'offset': offset,
    };
    final sql = StringBuffer('''
SELECT $_columns FROM wishes
WHERE owner_id = @ownerId
''');
    if (query != null && query.isNotEmpty) {
      sql.write(" AND name ILIKE ('%' || @query || '%') ESCAPE '!'");
      params['query'] = query;
    }
    sql.write(' ORDER BY id DESC LIMIT @limit OFFSET @offset');

    final rows = await _db.query(sql.toString(), params);
    return [for (final row in rows) WishModel.fromRow(row)];
  }

  Future<WishModel?> findById(int id) async {
    final row = await _db.querySingle(
      'SELECT $_columns FROM wishes WHERE id = @id',
      {'id': id},
    );
    return row == null ? null : WishModel.fromRow(row);
  }

  Future<WishModel> insert({
    required int ownerId,
    required String name,
    required WishVisibility visibility,
    required WishStatus status,
    double? price,
    String? url,
    String? description,
    String? coverUrl,
    int? copiedFrom,
  }) async {
    final row = await _db.querySingle(
      '''
INSERT INTO wishes (
  owner_id, name, price, url, description, cover_url,
  visibility, status, copied_from
) VALUES (
  @ownerId,
  @name,
  @price,
  @url,
  @description,
  @coverUrl,
  CAST(@visibility AS wish_visibility),
  CAST(@status AS wish_status),
  @copiedFrom
)
RETURNING $_columns
''',
      {
        'ownerId': ownerId,
        'name': name,
        'price': price,
        'url': url,
        'description': description,
        'coverUrl': coverUrl,
        'visibility': visibility.name,
        'status': status.name,
        'copiedFrom': copiedFrom,
      },
    );
    return WishModel.fromRow(row!);
  }

  /// Returns the updated row, or `null` when no owned row matched.
  Future<WishModel?> update({
    required int id,
    required int ownerId,
    String? name,
    double? price,
    bool clearPrice = false,
    String? url,
    bool clearUrl = false,
    String? description,
    bool clearDescription = false,
    String? coverUrl,
    bool clearCoverUrl = false,
    WishVisibility? visibility,
    WishStatus? status,
  }) async {
    final sets = <String>['updated_at = now()'];
    final params = <String, Object?>{'id': id, 'ownerId': ownerId};

    if (name != null) {
      sets.add('name = @name');
      params['name'] = name;
    }
    if (clearPrice) {
      sets.add('price = NULL');
    } else if (price != null) {
      sets.add('price = @price');
      params['price'] = price;
    }
    if (clearUrl) {
      sets.add('url = NULL');
    } else if (url != null) {
      sets.add('url = @url');
      params['url'] = url;
    }
    if (clearDescription) {
      sets.add('description = NULL');
    } else if (description != null) {
      sets.add('description = @description');
      params['description'] = description;
    }
    if (clearCoverUrl) {
      sets.add('cover_url = NULL');
    } else if (coverUrl != null) {
      sets.add('cover_url = @coverUrl');
      params['coverUrl'] = coverUrl;
    }
    if (visibility != null) {
      sets.add('visibility = CAST(@visibility AS wish_visibility)');
      params['visibility'] = visibility.name;
    }
    if (status != null) {
      sets.add('status = CAST(@status AS wish_status)');
      params['status'] = status.name;
    }

    final row = await _db.querySingle(
      '''
UPDATE wishes
SET ${sets.join(', ')}
WHERE id = @id AND owner_id = @ownerId
RETURNING $_columns
''',
      params,
    );
    return row == null ? null : WishModel.fromRow(row);
  }

  Future<int> delete({required int id, required int ownerId}) {
    return _db.execute(
      '''
DELETE FROM wishes
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
DELETE FROM wishes
WHERE owner_id = @ownerId AND id = ANY(@ids)
''',
      {'ownerId': ownerId, 'ids': ids},
    );
  }

  /// Copies an owned wish. Returns `null` when the source is missing or
  /// belongs to someone else.
  Future<WishModel?> duplicate({
    required int id,
    required int ownerId,
  }) async {
    final row = await _db.querySingle(
      '''
INSERT INTO wishes (
  owner_id, name, price, url, description, cover_url,
  visibility, status, copied_from
)
SELECT
  owner_id, name, price, url, description, cover_url,
  visibility, status, id
FROM wishes
WHERE id = @id AND owner_id = @ownerId
RETURNING $_columns
''',
      {'id': id, 'ownerId': ownerId},
    );
    return row == null ? null : WishModel.fromRow(row);
  }
}
