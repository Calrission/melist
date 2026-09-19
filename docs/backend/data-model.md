# Модель данных (PostgreSQL)

Статус: **план**. База ещё не подключена к коду; этот документ фиксирует схему, под которую пишутся эндпоинты из [api.md](api.md).

## Подключение

- Пакет: [`postgres`](https://pub.dev/packages/postgres) `^3.x` (`Connection` / `Pool`).
- Переменная окружения `DATABASE_URL=postgres://user:pass@host:5432/melist` в `backend/.env`, читается через `AppConfig`.
- Пул соединений создаётся один раз и отдаётся в роуты через `provider<Pool>` в `backend/routes/_middleware.dart`; репозитории в `backend/lib/src/data/` получают его через `context.read<Pool>()`.
- Миграции: нумерованные SQL-файлы в `backend/migrations/` (`0001_init.sql`, …), применяются скриптом `dart run bin/migrate.dart` или внешним инструментом (например, `dbmate`). Таблица `schema_migrations` хранит применённые версии.

## Схема

```mermaid
erDiagram
  users ||--o{ wishlists : owns
  users ||--o{ wishes : owns
  wishlists ||--o{ wishlist_wishes : contains
  wishes ||--o{ wishlist_wishes : in
  users ||--o{ favorites : has
  wishlists ||--o{ favorites : favorited
  users ||--o{ wishlist_subscriptions : follows
  wishlists ||--o{ wishlist_subscriptions : followed
  users ||--o{ user_subscriptions : follower
  users ||--o{ user_subscriptions : followee
  users ||--o{ entitlements : has
  users ||--o{ donations : made
```

### Enum-типы

```sql
CREATE TYPE wishlist_visibility AS ENUM ('public', 'draft');
CREATE TYPE wish_visibility     AS ENUM ('public', 'private', 'link');
CREATE TYPE wish_status         AS ENUM ('draft', 'free', 'reserved');
CREATE TYPE ui_theme            AS ENUM ('system', 'light', 'dark');
CREATE TYPE entitlement_source  AS ENUM ('ad', 'donation');
```

### `users` (22, 23, 26)

Идентификатор — Telegram user id, приходит из JWT (`sub`).

```sql
CREATE TABLE users (
  id           BIGINT PRIMARY KEY,           -- telegram user id
  first_name   TEXT,
  last_name    TEXT,
  username     TEXT,
  avatar_url   TEXT,
  birthday     DATE,                          -- 23.1, 23.2
  theme        ui_theme NOT NULL DEFAULT 'system',
  created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);
```

Запись создаётся/обновляется при `POST /auth/validate` из данных `initData` (upsert).

### `wishlists` (1–7)

```sql
CREATE TABLE wishlists (
  id           BIGSERIAL PRIMARY KEY,
  owner_id     BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  name         TEXT NOT NULL,
  description  TEXT,
  color        TEXT NOT NULL,                 -- 1.4, значение из базовой палитры
  visibility   wishlist_visibility NOT NULL DEFAULT 'draft',
  position     INTEGER NOT NULL DEFAULT 0,    -- 5.1
  share_token  TEXT UNIQUE,                   -- 7.1, генерируется по запросу
  created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX wishlists_owner_position_idx ON wishlists (owner_id, position);
```

### `wishes` (12–21)

```sql
CREATE TABLE wishes (
  id           BIGSERIAL PRIMARY KEY,
  owner_id     BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  name         TEXT NOT NULL,                 -- 12.1
  price        NUMERIC(12, 2),                -- 12.2
  url          TEXT,
  description  TEXT,
  cover_url    TEXT,
  visibility   wish_visibility NOT NULL DEFAULT 'public',   -- 19
  status       wish_status NOT NULL DEFAULT 'free',         -- 20
  copied_from  BIGINT REFERENCES wishes(id) ON DELETE SET NULL,  -- 4.3, 13
  created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX wishes_owner_idx ON wishes (owner_id);
CREATE INDEX wishes_name_trgm_idx ON wishes USING gin (name gin_trgm_ops);  -- 17.1, требует pg_trgm
```

Желание существует независимо от вишлиста (16 — «все свои желания»), поэтому связь many-to-many.

### `wishlist_wishes` (4, 5.2)

```sql
CREATE TABLE wishlist_wishes (
  wishlist_id  BIGINT NOT NULL REFERENCES wishlists(id) ON DELETE CASCADE,
  wish_id      BIGINT NOT NULL REFERENCES wishes(id) ON DELETE CASCADE,
  position     INTEGER NOT NULL DEFAULT 0,
  added_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (wishlist_id, wish_id)
);
CREATE INDEX wishlist_wishes_position_idx ON wishlist_wishes (wishlist_id, position);
```

### `favorites` (8–11)

```sql
CREATE TABLE favorites (
  user_id      BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  wishlist_id  BIGINT NOT NULL REFERENCES wishlists(id) ON DELETE CASCADE,
  position     INTEGER NOT NULL DEFAULT 0,    -- 10
  added_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, wishlist_id)
);
```

### `wishlist_subscriptions` (30–32) и `user_subscriptions` (33–35)

```sql
CREATE TABLE wishlist_subscriptions (
  user_id      BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  wishlist_id  BIGINT NOT NULL REFERENCES wishlists(id) ON DELETE CASCADE,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, wishlist_id)
);

CREATE TABLE user_subscriptions (
  follower_id  BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  followee_id  BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (follower_id, followee_id),
  CHECK (follower_id <> followee_id)
);
```

### `entitlements` (29) и `donations` (28)

```sql
CREATE TABLE entitlements (
  id           BIGSERIAL PRIMARY KEY,
  user_id      BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  source       entitlement_source NOT NULL,   -- 29.1 ad / 29.2 donation
  granted_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
  expires_at   TIMESTAMPTZ NOT NULL
);
CREATE INDEX entitlements_user_expires_idx ON entitlements (user_id, expires_at);

CREATE TABLE donations (
  id                    BIGSERIAL PRIMARY KEY,
  user_id               BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  amount_stars          INTEGER NOT NULL,
  telegram_payment_id   TEXT UNIQUE,
  status                TEXT NOT NULL DEFAULT 'pending',  -- pending / paid / refunded
  created_at            TIMESTAMPTZ NOT NULL DEFAULT now()
);
```

`GET /api/me/entitlements` считает `premiumUntil = max(expires_at) where expires_at > now()`.

## Правила доступа

- Владелец видит и меняет только свои `wishlists` и `wishes` (`owner_id = AuthUser.id`); иначе `403`.
- Чужой вишлист читается, если `visibility = 'public'` или запрос идёт по `share_token` (`GET /api/shared/{token}`).
- Чужое желание читается, если оно в доступном вишлисте и `visibility <> 'private'`.
- Копирование (4.3, 13) создаёт новую строку `wishes` с `copied_from`, а не ссылку.

## Соответствие с `melist_core`

Модели `WithListModel` и `WishItemModel` в `core/lib/src/models/` — ранний набросок; при подключении БД их нужно привести к этой схеме (добавить `visibility`, `status`, `color`, `coverUrl`, сделать `price`/`url` nullable) и использовать общие DTO на клиенте и сервере.
