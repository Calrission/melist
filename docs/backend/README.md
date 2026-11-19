# Backend

API для MELIST на [Dart Frog](https://dart-frog.dev) с PostgreSQL. Пакет `melist_backend`, каталог `backend/`.

Связанные документы:

- [API и эндпоинты](api.md)
- [Roadmap эндпоинтов](roadmap.md)
- [Модель данных](data-model.md)
- [Best practices](best-practices.md)
- [Тестирование](testing.md)

## Стек

- Dart `^3.12`, Dart Frog `^1.1` (file-based routing, middleware, DI через `provider`)
- `dart_frog_auth` — Bearer-аутентификация защищённых роутов
- `dart_jsonwebtoken` — выпуск и проверка access JWT
- `crypto` — HMAC-проверка Telegram `initData`
- `dotenv` — конфигурация из `.env`
- `dart_frog_swagger` — OpenAPI из аннотаций `@Route`, Swagger UI на `/docs`
- `shelf_cors_headers` — CORS
- `melist_core` — общие модели (workspace-пакет `core/`)
- `postgres` `^3.5` — PostgreSQL, пул соединений; обёртка `Database` в `lib/src/data/`, схема — [data-model.md](data-model.md)
- Тесты: `test`, `mocktail`, `dart_frog_test`; линтер `dart_frog_lint`

## Структура

```
backend/
├── main.dart                   # точка входа: AppConfig, БД, миграции, provider, статика Mini App
├── routes/                     # эндпоинты (файл = путь)
│   ├── _middleware.dart        # логи, CORS, провайдеры per-request сервисов, Swagger UI
│   ├── index.dart              # GET /
│   ├── health.dart             # GET /health
│   ├── version.dart            # GET /version
│   ├── auth/
│   │   ├── validate.dart       # POST /auth/validate  (initData -> JWT + refresh cookie)
│   │   ├── refresh.dart        # POST /auth/refresh   (cookie -> новый access)
│   │   ├── logout.dart         # POST /auth/logout    (отозвать cookie)
│   │   └── debug.dart          # GET  /auth/debug     (локальный Bearer, DEBUG_AUTH)
│   └── api/                    # защищённые роуты (Bearer JWT)
│       ├── _middleware.dart    # bearerAuthentication -> AuthUser в контексте
│       ├── me/ users/ wishlists/ wishes/ favorites/ shared/
│       ├── subscriptions/ ads/ donations/
├── lib/
│   ├── melist_backend.dart     # публичный экспорт
│   └── src/
│       ├── auth/               # InitDataValidator, JwtService, AuthSessionService, refresh cookie
│       ├── config/             # AppConfig (.env)
│       ├── data/               # Database (пул PostgreSQL), DatabaseConfig, Migrator, далее репозитории
│       │   └── migrations/     # mNNNN_<name>.dart — SQL-миграции, список allMigrations
│       ├── http/               # общие ответы (notImplemented, ошибки)
│       ├── openapi/            # переиспользуемые схемы для @Route
│       ├── wishes/             # WishService — CRUD желаний
│       ├── wishlists/          # WishlistService — CRUD вишлистов
│       ├── favorites/          # FavoriteService — избранное
│       ├── profiles/           # ProfileService — свой и чужой профиль
│       └── subscriptions/      # SubscriptionService — подписки на вишлисты и профили
├── test/
│   ├── routes/                 # зеркало routes/
│   ├── src/                    # unit-тесты сервисов
│   ├── integration/            # тесты на реальной PostgreSQL (TEST_DATABASE_URL), иначе skip
│   └── helpers/                # тестовый initData, FakePool для Database
├── dart_test.yaml              # тег integration
├── docker-compose.yml          # прод: API + PostgreSQL + Caddy (melist.online)
├── docker-compose.dev.yml      # локально: PostgreSQL + API
├── Dockerfile                  # образ API, контекст — корень репозитория
├── build/openapi.json          # генерируется, в git не попадает
├── .env                        # секреты, в git не попадает
└── .example_env                # шаблон .env
```

Правило: `routes/` содержит только разбор запроса и вызов логики из `lib/`. Подробнее — [best-practices.md](best-practices.md).

## Конфигурация

Файл `backend/.env` (шаблон — `backend/.example_env`):

```
BOT_TOKEN=          # токен Telegram-бота, для проверки initData
JWT_SECRET=         # секрет подписи access JWT
DATABASE_URL=       # postgres://user:pass@host:5432/melist?sslmode=disable
BOT_USERNAME=meelist_dev_bot  # username бота без @, для ссылок шаринга (7.1); в релизе свой
DEBUG_AUTH=false    # true — локальный логин без Telegram; в проде не включать
DEBUG_TOKEN=dev-admin
DEBUG_USER_ID=1
ACCESS_TOKEN_TTL_SECONDS=900     # access JWT, по умолчанию 15 минут
REFRESH_TOKEN_TTL_SECONDS=604800 # refresh cookie, по умолчанию 7 дней
COOKIE_SECURE=false              # true в проде (HTTPS)
CORS_ORIGINS=http://localhost:8081,http://*:8081,https://*.ngrok-free.dev  # origins с credentials; `*` — одна метка или IPv4; пусто — allow-all без cookies
WEB_ROOT=           # каталог сборки Flutter Web; пусто — более новый из frontend/build/web и frontend/.build/web
```

`AppConfig.load()` читает `.env`, затем поверх накладывает переменные окружения процесса — **окружение важнее файла**. Так одна и та же сборка работает локально с `.env` и в Docker/CI без него, где значения приходят через `environment:` или `-e`. Падает на старте, если `BOT_TOKEN`, `JWT_SECRET` или `DATABASE_URL` пусты. Секреты в код не попадают: см. `lib/src/config/app_config.dart`.

### Старт процесса (`main.dart`)

Dart Frog вызывает `run(handler, ip, port)` из `backend/main.dart` до открытия порта. Там по порядку: `AppConfig.load()` → `Database.fromUrl(...)` → `await database.connect()` (реальное соединение и `SELECT 1`) → `Migrator(database).migrate()` (создаёт недостающие таблицы, см. [data-model.md → Миграции](data-model.md#миграции)). Любая ошибка — процесс завершается с кодом 255 и строкой `Database startup failed: ...` в stderr; сервер не начинает принимать запросы с неработающей или неполной БД. При успехе в stdout:

```
Connected to PostgreSQL
[migrations] applying 0001_init          # только на пустой базе
[migrations] applying 0002_refresh_tokens
[migrations] schema up to date (version 2)
```

Ctrl+C / SIGTERM закрывают пул.

Значения по умолчанию: TTL access JWT — 15 минут, refresh cookie — 7 дней, максимальный возраст `initData` — 24 часа.

### `DATABASE_URL`

Формат `postgres://[user[:pass]@]host[:port]/dbname[?params]`, разбирается `DatabaseConfig.parse` (`lib/src/data/database_config.dart`). Параметры:

| Параметр | Значения | По умолчанию |
|---|---|---|
| `sslmode` | `disable`, `require`, `verify-full` (`prefer`/`allow` → `require`, `verify-ca` → `verify-full`) | `disable` |
| `max_connections` | размер пула, > 0 | `10` |
| `connect_timeout`, `query_timeout` | секунды, > 0 | без лимита (дефолты драйвера) |
| `application_name` | имя в `pg_stat_activity` | `melist_backend` |
| `user`, `password`, `port`, `database` | переопределяют части URL | — |

Пароль с спецсимволами — percent-encode (`p%40ss`). Неизвестный параметр или неверное значение — `FormatException` на старте.

Локальный стек — [`docker-compose.dev.yml`](../../backend/docker-compose.dev.yml): PostgreSQL и API. Образ API собирается из [`Dockerfile`](../../backend/Dockerfile) (workspace без frontend). С хоста Postgres — порт **15432**, API — **8080**. `DATABASE_URL` внутри контейнера — `postgres://melist:melist@db:5432/melist?sslmode=disable` (хост `db`, не `localhost`).

```powershell
cd backend
Copy-Item .example_env .env   # заполнить BOT_TOKEN и JWT_SECRET
docker compose -f docker-compose.dev.yml up -d --build
```

Только Postgres, API через `dart_frog dev` на хосте:

```powershell
docker compose -f docker-compose.dev.yml up -d db
```

Прод — [`docker-compose.yml`](../../backend/docker-compose.yml): тот же API и Postgres без опубликованных портов, перед ними Caddy на `melist.online`. Образ API — обычный [`Dockerfile`](../../backend/Dockerfile). Релизная сборка Flutter кладётся на хост в `frontend/.build/web` (на диске сервера нет места собирать Flutter SDK внутри Docker). На сервере после `git pull`:

```bash
cd backend
docker compose up -d --build
```

`DATABASE_URL` в `.env` для хоста: `postgres://melist:melist@localhost:15432/melist?sslmode=disable`.

## Команды

Зависимости ставятся из корня workspace:

```powershell
flutter pub get
```

Остальное — из `backend/`:

```powershell
cd backend

# dev-сервер с hot reload, http://localhost:8080
dart_frog dev

# сгенерировать OpenAPI (build/openapi.json) — после любого изменения @Route
dart run dart_frog_swagger

# статический анализ
dart analyze

# все тесты (интеграционные с БД пропускаются без TEST_DATABASE_URL)
dart test

# интеграционные тесты миграций на живой PostgreSQL (создаёт и удаляет временную базу)
$env:TEST_DATABASE_URL='postgres://melist:melist@localhost:15432/melist?sslmode=disable'; dart test test/integration

# один файл / фильтр по имени
dart test test/routes/auth/validate_test.dart
dart test -n "POST /auth/validate"

# production-сборка (build/, включая сгенерированный Dockerfile)
dart_frog build
dart build/bin/server.dart

# API + PostgreSQL локально (нужен backend/.env)
docker compose -f docker-compose.dev.yml up -d --build
```

Swagger UI: [http://localhost:8080/docs](http://localhost:8080/docs), спецификация — `/openapi.json`. Если `build/openapi.json` отсутствует, `/docs` покажет подсказку с командой генерации.

Кнопка **Authorize** принимает access JWT или `DEBUG_TOKEN` (без префикса `Bearer`). Защищены только `/api/v1/**`; `/auth/*` остаются открытыми. Path-параметры (`id`, `token`, …) появляются в Try it out сами.

CLI Dart Frog ставится один раз: `dart pub global activate dart_frog_cli`.

## Аутентификация

Пароля у пользователя нет. Клиент присылает сырую строку `WebApp.initData`, сервер проверяет HMAC-SHA256 токеном бота и выдаёт access JWT (`sub` = Telegram user id) плюс HttpOnly cookie `refresh_token`. Дальше все запросы к `/api/v1/**` идут с заголовком `Authorization: Bearer <jwt>`. Когда access истечёт — `POST /auth/refresh` (cookie), без повторного `initData`. Детали и формат ответов — [api.md](api.md).

Сборка Mini App (`frontend/build/web` или `frontend/.build/web`, или `WEB_ROOT`) раздаётся тем же процессом на порту API. Открывать её на `GET /`. `GET /` — приложение, пока в каталоге есть `index.html`; `/api`, `/auth`, `/health`, `/version`, `/docs`, `/openapi.json` не перехватываются. `API_URL` на клиенте пустой. `flutter run` на другом порту — cross-origin: задайте `CORS_ORIGINS` (origin фронта) и `API_URL`. `COOKIE_SECURE=true` обязателен на HTTPS.

Для локальной разработки без Mini App: `DEBUG_AUTH=true` в `.env`. На старте создаётся пользователь `debug_admin` (`DEBUG_USER_ID`, по умолчанию `1`), а строка `DEBUG_TOKEN` (по умолчанию `dev-admin`) принимается как Bearer на `/api/v1/**`. Это не JWT: `iat`/`exp` не меняются. Токен можно взять из `GET /auth/debug` или сразу вставить в Swagger Authorize. Если флаг выключен, магическая строка даёт `401`, эндпоинт — `404`. На проде флаг не включать.

## Состояние

Реализовано: `/`, `/health`, `/version`, `/auth/validate`, `POST /auth/refresh`, `POST /auth/logout`, `GET /auth/debug` (локальный Bearer при `DEBUG_AUTH`), Bearer-middleware для `/api/v1/**`, Swagger, класс `Database`, автоматические миграции, CRUD вишлистов (`GET`/`POST`/`PATCH`/`DELETE /api/v1/wishlists`, `GET`/`PATCH`/`DELETE /api/v1/wishlists/{id}`), CRUD желаний (`GET`/`POST`/`DELETE /api/v1/wishes`, `GET`/`PATCH`/`DELETE /api/v1/wishes/{id}`, `POST /api/v1/wishes/{id}/duplicate`), желания внутри вишлиста (`POST`/`PATCH /api/v1/wishlists/{id}/wishes`, `DELETE /api/v1/wishlists/{id}/wishes/{wishId}`), шеринг (`POST /api/v1/wishlists/{id}/share`, `GET /api/v1/shared/{token}`), избранное (`GET`/`POST`/`PATCH /api/v1/favorites`, `DELETE /api/v1/favorites/{wishlistId}`), профиль (`GET`/`PATCH /api/v1/me`, `GET /api/v1/users/{id}`), подписки (`GET`/`POST /api/v1/subscriptions/wishlists`, `DELETE /api/v1/subscriptions/wishlists/{wishlistId}`, `GET`/`POST /api/v1/subscriptions/users`, `DELETE /api/v1/subscriptions/users/{userId}`).

Остальные `/api/v1/**` — заглушки (`501`). Порядок доделок — [roadmap.md](roadmap.md).
