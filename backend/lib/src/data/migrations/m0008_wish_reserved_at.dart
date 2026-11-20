import 'package:melist_backend/src/data/migration.dart';

/// When the wish was reserved. Orders a user's own reservations.
const m0008WishReservedAt = Migration(
  version: 8,
  name: 'wish_reserved_at',
  sql: '''
ALTER TABLE wishes ADD COLUMN IF NOT EXISTS reserved_at TIMESTAMPTZ;

UPDATE wishes
SET reserved_at = updated_at
WHERE reserved_by IS NOT NULL AND reserved_at IS NULL;

CREATE INDEX IF NOT EXISTS wishes_reserved_by_idx
  ON wishes (reserved_by, reserved_at DESC);
''',
);
