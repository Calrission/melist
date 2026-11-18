import 'package:melist_backend/src/data/migration.dart';
import 'package:melist_backend/src/data/migrations/m0001_init.dart';
import 'package:melist_backend/src/data/migrations/m0002_refresh_tokens.dart';
import 'package:melist_backend/src/data/migrations/m0003_wishlist_cover.dart';
import 'package:melist_backend/src/data/migrations/m0004_drop_wishlist_color.dart';
import 'package:melist_backend/src/data/migrations/m0005_user_nickname.dart';
import 'package:melist_backend/src/data/migrations/m0006_drop_wishlist_cover.dart';

/// Every migration the application knows about, in version order.
///
/// To change the schema: add `mNNNN_<name>.dart` with the next version,
/// append it here, update `docs/backend/data-model.md`. Never edit a
/// migration that may already be applied somewhere.
const allMigrations = <Migration>[
  m0001Init,
  m0002RefreshTokens,
  m0003WishlistCover,
  m0004DropWishlistColor,
  m0005UserNickname,
  m0006DropWishlistCover,
];
