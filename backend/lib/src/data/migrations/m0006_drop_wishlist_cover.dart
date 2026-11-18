import 'package:melist_backend/src/data/migration.dart';

/// Wishlists no longer store a cover link.
const m0006DropWishlistCover = Migration(
  version: 6,
  name: 'drop_wishlist_cover',
  sql: '''
ALTER TABLE wishlists DROP COLUMN IF EXISTS cover_url;
''',
);
