import 'package:melist_backend/src/data/migration.dart';

/// Wishlist cover is a link. The palette color is no longer stored.
const m0004DropWishlistColor = Migration(
  version: 4,
  name: 'drop_wishlist_color',
  sql: '''
ALTER TABLE wishlists DROP COLUMN IF EXISTS color;
''',
);
