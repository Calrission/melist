import 'package:melist_backend/src/auth/auth_user.dart';
import 'package:melist_backend/src/data/database.dart';

class UserRepository {
  const UserRepository(this._db);

  final DbExecutor _db;

  /// Inserts the Telegram user or refreshes profile fields on conflict.
  Future<void> ensure(AuthUser user) {
    return _db.execute(
      '''
INSERT INTO users (id, first_name, last_name, username)
VALUES (@id, @firstName, @lastName, @username)
ON CONFLICT (id) DO UPDATE SET
  first_name = COALESCE(EXCLUDED.first_name, users.first_name),
  last_name = COALESCE(EXCLUDED.last_name, users.last_name),
  username = COALESCE(EXCLUDED.username, users.username),
  updated_at = now()
''',
      {
        'id': user.id,
        'firstName': user.firstName,
        'lastName': user.lastName,
        'username': user.username,
      },
    );
  }
}
