import 'package:melist_backend/src/data/migration.dart';

/// Optional display name. Null means first name plus last name.
const m0005UserNickname = Migration(
  version: 5,
  name: 'user_nickname',
  sql: '''
ALTER TABLE users ADD COLUMN IF NOT EXISTS nickname TEXT;
''',
);
