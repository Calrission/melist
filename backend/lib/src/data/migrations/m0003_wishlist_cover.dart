import 'package:melist_backend/src/data/migration.dart';

/// Optional cover link on a wishlist, same idea as `wishes.cover_url`.
const m0003WishlistCover = Migration(
  version: 3,
  name: 'wishlist_cover',
  sql: '''
ALTER TABLE wishlists ADD COLUMN IF NOT EXISTS cover_url TEXT;
''',
);
