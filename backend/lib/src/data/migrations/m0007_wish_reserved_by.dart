import 'package:melist_backend/src/data/migration.dart';

/// Who reserved a wish. The id stays in the database and is never returned.
const m0007WishReservedBy = Migration(
  version: 7,
  name: 'wish_reserved_by',
  sql: '''
ALTER TABLE wishes
  ADD COLUMN IF NOT EXISTS reserved_by BIGINT REFERENCES users(id) ON DELETE SET NULL;
''',
);
