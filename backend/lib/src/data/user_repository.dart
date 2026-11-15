import 'package:melist_backend/src/auth/auth_user.dart';
import 'package:melist_backend/src/data/database.dart';
import 'package:melist_core/melist_core.dart';

class UserRepository {
  const UserRepository(this._db);

  static const _columns = '''
id, first_name, last_name, username, nickname, avatar_url,
birthday,
theme::text AS theme,
created_at, updated_at
''';

  final DbExecutor _db;

  /// Inserts the Telegram user or refreshes profile fields on conflict.
  Future<void> ensure(AuthUser user) {
    return _upsert(
      id: user.id,
      firstName: user.firstName,
      lastName: user.lastName,
      username: user.username,
    );
  }

  /// Upserts Telegram profile fields from `initData`, including avatar.
  Future<void> upsertTelegram(UserModel user) {
    return _upsert(
      id: user.id,
      firstName: user.firstName,
      lastName: user.lastName,
      username: user.username,
      avatarUrl: user.avatarUrl,
    );
  }

  Future<UserModel?> findById(int id) async {
    final row = await _db.querySingle(
      'SELECT $_columns FROM users WHERE id = @id',
      {'id': id},
    );
    return row == null ? null : UserModel.fromRow(row);
  }

  /// Returns the updated row, or `null` when no user matched.
  Future<UserModel?> update({
    required int id,
    DateTime? birthday,
    bool clearBirthday = false,
    String? nickname,
    bool clearNickname = false,
    UiTheme? theme,
  }) async {
    final sets = <String>['updated_at = now()'];
    final params = <String, Object?>{'id': id};

    if (clearBirthday) {
      sets.add('birthday = NULL');
    } else if (birthday != null) {
      sets.add('birthday = @birthday:date');
      params['birthday'] = birthday;
    }
    if (clearNickname) {
      sets.add('nickname = NULL');
    } else if (nickname != null) {
      sets.add('nickname = @nickname');
      params['nickname'] = nickname;
    }
    if (theme != null) {
      sets.add('theme = CAST(@theme AS ui_theme)');
      params['theme'] = theme.name;
    }

    final row = await _db.querySingle(
      '''
UPDATE users SET ${sets.join(', ')}
WHERE id = @id
RETURNING $_columns
''',
      params,
    );
    return row == null ? null : UserModel.fromRow(row);
  }

  Future<void> _upsert({
    required int id,
    String? firstName,
    String? lastName,
    String? username,
    String? avatarUrl,
  }) {
    return _db.execute(
      '''
INSERT INTO users (id, first_name, last_name, username, avatar_url)
VALUES (@id, @firstName, @lastName, @username, @avatarUrl)
ON CONFLICT (id) DO UPDATE SET
  first_name = COALESCE(EXCLUDED.first_name, users.first_name),
  last_name = COALESCE(EXCLUDED.last_name, users.last_name),
  username = COALESCE(EXCLUDED.username, users.username),
  avatar_url = COALESCE(EXCLUDED.avatar_url, users.avatar_url),
  updated_at = now()
''',
      {
        'id': id,
        'firstName': firstName,
        'lastName': lastName,
        'username': username,
        'avatarUrl': avatarUrl,
      },
    );
  }
}
