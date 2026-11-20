# Модель данных (PostgreSQL)

Статус: **схема создаётся автоматически**. Класс `Database`, пул и миграции реализованы; описанные ниже таблицы создаются миграцией `0001_init` при старте backend. Этот документ — источник истины для схемы, под которую пишутся эндпоинты из [api.md](api.md); при изменении схемы правьте его вместе с новой миграцией.

## Подключение

- Пакет: [`postgres`](https://pub.dev/packages/postgres) `^3.5` (`Pool`).
- Переменная окружения `DATABASE_URL=postgres://user:pass@host:5432/melist?sslmode=disable` в `backend/.env`, читается через `AppConfig.databaseUrl`; формат и параметры — [README.md](README.md#database_url).
- `backend/lib/src/data/database.dart` — класс `Database`: обёртка над `Pool`. Создаётся один раз на процесс в `backend/main.dart`, там же `await database.connect()` — сервер не стартует, если БД недоступна или пароль неверен. В роуты попадает через `provider<Database>` над всем роутером; в роутах и репозиториях — `context.read<Database>()`.
- `backend/lib/src/data/database_config.dart` — `DatabaseConfig.parse(url)`: разбор `DATABASE_URL` в `Endpoint` + `PoolSettings`, валидация с понятными ошибками.
- Репозитории (`WishlistRepository`, `WishRepository`, …) живут в `backend/lib/src/data/` и принимают `DbExecutor` — общий интерфейс `Database` и транзакции, чтобы один и тот же код работал внутри и вне `transaction`.
- Миграции применяются автоматически при старте — см. [Миграции](#миграции).

## Миграции

Схема версионируется встроенными в бинарник миграциями; отдельный шаг «накатить БД» не нужен — `main.dart` делает это до открытия порта.

**Как устроено**

- `backend/lib/src/data/migration.dart` — `Migration(version, name, sql)`: SQL-скрипт как Dart-константа (не файл на диске, чтобы `dart_frog build` и Docker-образ ничего не теряли).
- `backend/lib/src/data/migrations/mNNNN_<name>.dart` — по файлу на миграцию; `m0001_init.dart` — таблицы из этого документа.
- `backend/lib/src/data/migrations/migrations.dart` — список `allMigrations` в порядке версий.
- `backend/lib/src/data/migrator.dart` — `Migrator(database).migrate()`:
  1. открывает одну транзакцию и берёт `pg_advisory_xact_lock(7264051)` — несколько инстансов, стартующих одновременно, не применят миграцию дважды;
  2. `CREATE TABLE IF NOT EXISTS schema_migrations (version, name, applied_at)`;
  3. читает применённые версии, выполняет отсутствующие по возрастанию (`executeScript`, simple protocol — многострочный DDL) и записывает каждую в `schema_migrations`;
  4. commit. Ошибка в любой миграции — rollback всего и исключение: сервер не стартует, схема остаётся в прежнем состоянии (DDL в PostgreSQL транзакционен).
- В логе при старте: `[migrations] applying 0001_init` → `[migrations] applied 0001_init (now at version 1)`, затем `0002_refresh_tokens`; при повторном запуске — `[migrations] schema up to date (version 2)`. Если в `schema_migrations` есть версии, неизвестные этой сборке (БД мигрирована более новым кодом), пишется предупреждение, старт продолжается.

**Как добавить миграцию**

1. Создать `lib/src/data/migrations/m0002_<name>.dart` с `Migration(version: 2, name: '<name>', sql: r'''...''')`. Имя — `snake_case`. Использовать `IF NOT EXISTS` / `DO $$ ... $$` там, где возможно, чтобы скрипт был идемпотентным.
2. Добавить константу в `allMigrations`.
3. Обновить SQL в этом документе (он должен отражать итоговую схему).
4. Прогнать `dart test` (юнит-тесты `Migrator` и проверка списка) и интеграционный тест на живой БД: `$env:TEST_DATABASE_URL='postgres://melist:melist@localhost:15432/melist?sslmode=disable'; dart test test/integration`.

Уже применённую где-либо миграцию не редактировать — только новая версия. `CREATE INDEX CONCURRENTLY` внутри транзакции не работает; для больших таблиц такие индексы создавать вне миграций.

**Права**: `0001_init` выполняет `CREATE EXTENSION IF NOT EXISTS pg_trgm` (поиск 17.1). В docker-compose пользователь `melist` — суперпользователь, проблем нет; в managed PostgreSQL (RDS, Neon, Supabase) `pg_trgm` входит в разрешённые расширения, но пользователю может понадобиться право `CREATE` на базу.

### API `Database`

```dart
final db = context.read<Database>();

// список строк как Map<String, dynamic>
final rows = await db.query(
  'SELECT * FROM wishlists WHERE owner_id = @ownerId ORDER BY position',
  {'ownerId': user.id},
);

// одна строка или null
final wishlist = await db.querySingle(
  'SELECT * FROM wishlists WHERE id = @id',
  {'id': id},
);

// первое значение первой строки
final total = await db.scalar<int>('SELECT count(*) FROM wishes');

// без результата, возвращает число затронутых строк
final deleted = await db.execute(
  'DELETE FROM wishes WHERE id = @id AND owner_id = @ownerId',
  {'id': id, 'ownerId': user.id},
);

// транзакция: commit по завершении, rollback + rethrow при исключении
final newId = await db.transaction((tx) async {
  final row = await tx.querySingle(
    'INSERT INTO wishes (owner_id, name) VALUES (@ownerId, @name) RETURNING id',
    {'ownerId': user.id, 'name': name},
  );
  await tx.execute(
    'INSERT INTO wishlist_wishes (wishlist_id, wish_id) VALUES (@wl, @w)',
    {'wl': wishlistId, 'w': row!['id']},
  );
  return row['id'] as int;
});

await db.executeScript('CREATE TABLE ...; CREATE INDEX ...;'); // DDL, несколько statement, без параметров
await db.connect(); // SELECT 1, бросает при ошибке — вызывается в main.dart на старте
await db.ping();    // то же, но true/false без исключений — для /health
await db.close();   // при остановке процесса (main.dart, по SIGINT/SIGTERM)
```

Параметры — именованные `@name`; строковые литералы и комментарии драйвер игнорирует. Если тип не выводится из контекста, укажите его в SQL: `@id:int8`, `@birthday:date`. Ошибки PostgreSQL приходят как `ServerException`, нарушение уникальности — `UniqueViolationException`, внешнего ключа — `ForeignKeyViolationException` (все из `package:postgres`).

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
  users ||--o{ refresh_tokens : sessions
```

### Enum-типы

```sql
CREATE TYPE wishlist_visibility AS ENUM ('public', 'draft', 'link');
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
  nickname     TEXT,                          -- 23.3, null = имя и фамилия
  avatar_url   TEXT,
  birthday     DATE,                          -- 23.1, 23.2
  theme        ui_theme NOT NULL DEFAULT 'system',
  created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);
```

Запись создаётся/обновляется при `POST /auth/validate` из данных `initData` (upsert, включая `avatar_url`). `nickname` при этом не затирается: `NULL` значит показать `first_name` и, если фамилия не пустая, `last_name`. `GET /api/v1/me` создаёт строку из JWT, если её ещё нет.

### `refresh_tokens`

Opaque refresh-токен живёт в HttpOnly cookie; в таблице только SHA-256 хеш. Несколько строк на пользователя — отдельные устройства. Ротация при `POST /auth/refresh`; повтор отозванного токена отзывает все сессии пользователя.

```sql
CREATE TABLE refresh_tokens (
  id           BIGSERIAL PRIMARY KEY,
  user_id      BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  token_hash   TEXT NOT NULL UNIQUE,
  expires_at   TIMESTAMPTZ NOT NULL,
  revoked_at   TIMESTAMPTZ,
  replaced_by  BIGINT REFERENCES refresh_tokens(id),
  created_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX refresh_tokens_user_id_idx ON refresh_tokens (user_id);
```

### `wishlists` (1–7)

```sql
CREATE TABLE wishlists (
  id           BIGSERIAL PRIMARY KEY,
  owner_id     BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  name         TEXT NOT NULL,
  description  TEXT,
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
  status       wish_status NOT NULL DEFAULT 'free',         -- 20
  reserved_by  BIGINT REFERENCES users(id) ON DELETE SET NULL,   -- кто забронировал; в API только reservedByMe
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

`GET /api/v1/me/entitlements` считает `premiumUntil = max(expires_at) where expires_at > now()`.

## Правила доступа

- Владелец видит и меняет только свои `wishlists` и `wishes` (`owner_id = AuthUser.id`); иначе `403`.
- `public` — виден на публичном профиле всем и открывается оттуда. Если ссылки ещё не было, она создаётся при показе профиля. Подписка разрешена.
- `link` — чужой открывает по `share_token`. На публичном профиле список виден только тому, у кого он сейчас в избранном. Остальным на профиле его нет.
- `draft` — только владелец. На публичном профиле не показывается. В избранном не показывается, даже если строка избранного осталась. `GET /api/v1/shared/{token}` для не-владельца — `404`.
- `GET /api/v1/users/{id}` отдаёт карточку пользователя, все его `public`-вишлисты и `link`-вишлисты, которые текущий пользователь держит в избранном.
- В доступном вишлисте чужому отдаются все желания списка.
- Копирование (4.3, 13) создаёт новую строку `wishes` с `copied_from`, а не ссылку. Чужое желание копируется, только если оно стоит в публичном вишлисте.

## Соответствие с `melist_core`

Модели в `core/lib/src/models/` — общие DTO для клиента и сервера. JSON — camelCase (как в [api.md](api.md)), строки БД — `fromRow` со `snake_case`.

| Таблица / тип | Dart |
|---|---|
| `users` | `UserModel` |
| `wishlists` | `WishlistModel` (`items` — желания карточки, не колонка) |
| `wishes` | `WishModel` |
| `favorites` | `FavoriteModel` |
| `wishlist_subscriptions` | `WishlistSubscriptionModel` |
| `user_subscriptions` | `UserSubscriptionModel` |
| `entitlements` | `EntitlementModel` |
| `donations` | `DonationModel` |
| `wishlist_visibility` | `WishlistVisibility` |
| `wish_status` | `WishStatus` |
| `ui_theme` | `UiTheme` |
| `entitlement_source` | `EntitlementSource` |
| `donations.status` | `DonationStatus` |

`wishlist_wishes` отдельной моделью не представлен: позиция желания в вишлисте — порядок `WishlistModel.items`. Репозиторий читает join и собирает список через `copyWith(items: ...)`.
