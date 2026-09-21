import 'package:melist_backend/src/data/database.dart';
import 'package:melist_core/melist_core.dart';

class UserSubscriptionRepository {
  const UserSubscriptionRepository(this._db);

  static const _userColumns = '''
u.id, u.first_name, u.last_name, u.username, u.avatar_url,
u.birthday,
u.theme::text AS theme,
u.created_at, u.updated_at
''';

  final DbExecutor _db;

  Future<List<UserModel>> listUsers(int followerId) async {
    final rows = await _db.query(
      '''
SELECT $_userColumns
FROM user_subscriptions s
JOIN users u ON u.id = s.followee_id
WHERE s.follower_id = @followerId
ORDER BY s.created_at DESC, u.id
''',
      {'followerId': followerId},
    );
    return [for (final row in rows) UserModel.fromRow(row)];
  }

  Future<bool> exists({
    required int followerId,
    required int followeeId,
  }) async {
    final count = await _db.scalar<int>(
      '''
SELECT count(*)::int FROM user_subscriptions
WHERE follower_id = @followerId AND followee_id = @followeeId
''',
      {'followerId': followerId, 'followeeId': followeeId},
    );
    return count > 0;
  }

  Future<void> insert({
    required int followerId,
    required int followeeId,
  }) {
    return _db.execute(
      '''
INSERT INTO user_subscriptions (follower_id, followee_id)
VALUES (@followerId, @followeeId)
''',
      {'followerId': followerId, 'followeeId': followeeId},
    );
  }

  Future<int> delete({
    required int followerId,
    required int followeeId,
  }) {
    return _db.execute(
      '''
DELETE FROM user_subscriptions
WHERE follower_id = @followerId AND followee_id = @followeeId
''',
      {'followerId': followerId, 'followeeId': followeeId},
    );
  }
}
