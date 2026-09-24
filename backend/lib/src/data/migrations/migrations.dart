import 'package:melist_backend/src/data/migration.dart';
import 'package:melist_backend/src/data/migrations/m0001_init.dart';
import 'package:melist_backend/src/data/migrations/m0002_refresh_tokens.dart';

/// Every migration the application knows about, in version order.
///
/// To change the schema: add `mNNNN_<name>.dart` with the next version,
/// append it here, update `docs/backend/data-model.md`. Never edit a
/// migration that may already be applied somewhere.
const allMigrations = <Migration>[
  m0001Init,
  m0002RefreshTokens,
];
