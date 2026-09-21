import 'package:melist_backend/src/data/migration.dart';

/// Initial schema, mirrors `docs/backend/data-model.md`.
const m0001Init = Migration(
  version: 1,
  name: 'init',
  sql: r'''
CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- Enum types (CREATE TYPE has no IF NOT EXISTS, hence the DO blocks).
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'wishlist_visibility') THEN
    CREATE TYPE wishlist_visibility AS ENUM ('public', 'draft', 'link');
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'wish_status') THEN
    CREATE TYPE wish_status AS ENUM ('draft', 'free', 'reserved');
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'ui_theme') THEN
    CREATE TYPE ui_theme AS ENUM ('system', 'light', 'dark');
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'entitlement_source') THEN
    CREATE TYPE entitlement_source AS ENUM ('ad', 'donation');
  END IF;
END $$;

-- users (22, 23, 26): id = Telegram user id from JWT `sub`.
CREATE TABLE IF NOT EXISTS users (
  id           BIGINT PRIMARY KEY,
  first_name   TEXT,
  last_name    TEXT,
  username     TEXT,
  avatar_url   TEXT,
  birthday     DATE,
  theme        ui_theme NOT NULL DEFAULT 'system',
  created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- wishlists (1-7)
CREATE TABLE IF NOT EXISTS wishlists (
  id           BIGSERIAL PRIMARY KEY,
  owner_id     BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  name         TEXT NOT NULL,
  description  TEXT,
  color        TEXT NOT NULL,
  visibility   wishlist_visibility NOT NULL DEFAULT 'draft',
  position     INTEGER NOT NULL DEFAULT 0,
  share_token  TEXT UNIQUE,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS wishlists_owner_position_idx
  ON wishlists (owner_id, position);

-- wishes (12-21): exist independently of wishlists (16).
CREATE TABLE IF NOT EXISTS wishes (
  id           BIGSERIAL PRIMARY KEY,
  owner_id     BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  name         TEXT NOT NULL,
  price        NUMERIC(12, 2),
  url          TEXT,
  description  TEXT,
  cover_url    TEXT,
  status       wish_status NOT NULL DEFAULT 'free',
  copied_from  BIGINT REFERENCES wishes(id) ON DELETE SET NULL,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS wishes_owner_idx ON wishes (owner_id);
CREATE INDEX IF NOT EXISTS wishes_name_trgm_idx
  ON wishes USING gin (name gin_trgm_ops);

-- wishlist_wishes (4, 5.2): many-to-many with ordering.
CREATE TABLE IF NOT EXISTS wishlist_wishes (
  wishlist_id  BIGINT NOT NULL REFERENCES wishlists(id) ON DELETE CASCADE,
  wish_id      BIGINT NOT NULL REFERENCES wishes(id) ON DELETE CASCADE,
  position     INTEGER NOT NULL DEFAULT 0,
  added_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (wishlist_id, wish_id)
);
CREATE INDEX IF NOT EXISTS wishlist_wishes_position_idx
  ON wishlist_wishes (wishlist_id, position);

-- favorites (8-11)
CREATE TABLE IF NOT EXISTS favorites (
  user_id      BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  wishlist_id  BIGINT NOT NULL REFERENCES wishlists(id) ON DELETE CASCADE,
  position     INTEGER NOT NULL DEFAULT 0,
  added_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, wishlist_id)
);

-- wishlist_subscriptions (30-32)
CREATE TABLE IF NOT EXISTS wishlist_subscriptions (
  user_id      BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  wishlist_id  BIGINT NOT NULL REFERENCES wishlists(id) ON DELETE CASCADE,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, wishlist_id)
);

-- user_subscriptions (33-35)
CREATE TABLE IF NOT EXISTS user_subscriptions (
  follower_id  BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  followee_id  BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (follower_id, followee_id),
  CHECK (follower_id <> followee_id)
);

-- entitlements (29)
CREATE TABLE IF NOT EXISTS entitlements (
  id           BIGSERIAL PRIMARY KEY,
  user_id      BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  source       entitlement_source NOT NULL,
  granted_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
  expires_at   TIMESTAMPTZ NOT NULL
);
CREATE INDEX IF NOT EXISTS entitlements_user_expires_idx
  ON entitlements (user_id, expires_at);

-- donations (28)
CREATE TABLE IF NOT EXISTS donations (
  id                    BIGSERIAL PRIMARY KEY,
  user_id               BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  amount_stars          INTEGER NOT NULL,
  telegram_payment_id   TEXT UNIQUE,
  status                TEXT NOT NULL DEFAULT 'pending',
  created_at            TIMESTAMPTZ NOT NULL DEFAULT now()
);
''',
);
