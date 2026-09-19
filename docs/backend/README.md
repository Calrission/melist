# Backend

API для MELIST на [Dart Frog](https://dart-frog.dev) с PostgreSQL. Пакет `melist_backend`, каталог `backend/`.

Связанные документы:

- [API и эндпоинты](api.md)
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
├── main.dart                   # точка входа: AppConfig, БД, миграции, provider<AppConfig|Database|DebugAuth>
├── routes/                     # эндпоинты (файл = путь)
│   ├── _middleware.dart        # логи, CORS, провайдеры per-request сервисов, Swagger UI
│   ├── index.dart              # GET /
│   ├── health.dart             # GET /health
│   ├── auth/
│   │   ├── validate.dart       # POST /auth/validate  (initData -> JWT)
│   │   ├── refresh.dart        # POST /auth/refresh   (initData -> новый JWT)
│   │   └── debug.dart          # GET  /auth/debug     (локальный Bearer, DEBUG_AUTH)
│   └── api/                    # защищённые роуты (Bearer JWT)
│       ├── _middleware.dart    # bearerAuthentication -> AuthUser в контексте
│       ├── me/ users/ wishlists/ wishes/ favorites/ shared/
│       ├── subscriptions/ ads/ donations/
├── lib/
│   ├── melist_backend.dart     # публичный экспорт
│   └── src/
│       ├── auth/               # InitDataValidator, JwtService, AuthUser, DebugAuth
│       ├── config/             # AppConfig (.env)
│       ├── data/               # Database (пул PostgreSQL), DatabaseConfig, Migrator, далее репозитории
│       │   └── migrations/     # mNNNN_<name>.dart — SQL-миграции, список allMigrations
│       ├── http/               # общие ответы (notImplemented, ошибки)
│       └── openapi/            # переиспользуемые схемы для @Route
├── test/
│   ├── routes/                 # зеркало routes/
│   ├── src/                    # unit-тесты сервисов
│   ├── integration/            # тесты на реальной PostgreSQL (TEST_DATABASE_URL), иначе skip
│   └── helpers/                # тестовый initData, FakePool для Database
├── dart_test.yaml              # тег integration
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
DEBUG_AUTH=false    # true — локальный логин без Telegram; в проде не включать
DEBUG_TOKEN=dev-admin
DEBUG_USER_ID=1
```

`AppConfig.load()` читает `.env`, затем поверх накладывает переменные окружения процесса — **окружение важнее файла**. Так одна и та же сборка работает локально с `.env` и в Docker/CI без него, где значения приходят через `environment:` или `-e`. Падает на старте, если `BOT_TOKEN`, `JWT_SECRET` или `DATABASE_URL` пусты. Секреты в код не попадают: см. `lib/src/config/app_config.dart`.

### Старт процесса (`main.dart`)

Dart Frog вызывает `run(handler, ip, port)` из `backend/main.dart` до открытия порта. Там по порядку: `AppConfig.load()` → `Database.fromUrl(...)` → `await database.connect()` (реальное соединение и `SELECT 1`) → `Migrator(database).migrate()` (создаёт недостающие таблицы, см. [data-model.md → Миграции](data-model.md#миграции)). Любая ошибка — процесс завершается с кодом 255 и строкой `Database startup failed: ...` в stderr; сервер не начинает принимать запросы с неработающей или неполной БД. При успехе в stdout:

```
Connected to PostgreSQL
[migrations] applying 0001_init          # только на пустой базе
[migrations] schema up to date (version 1)
```

Ctrl+C / SIGTERM закрывают пул.

Значения по умолчанию: TTL access JWT — 1 час, максимальный возраст `initData` — 24 часа.

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

Локальная БД для разработки:

```powershell
docker run -d --name melist-pg -e POSTGRES_USER=melist -e POSTGRES_PASSWORD=melist -e POSTGRES_DB=melist -p 5432:5432 postgres:16
```

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
$env:TEST_DATABASE_URL='postgres://melist:melist@localhost:5433/melist?sslmode=disable'; dart test test/integration

# один файл / фильтр по имени
dart test test/routes/auth/validate_test.dart
dart test -n "POST /auth/validate"

# production-сборка (build/, включая Dockerfile)
dart_frog build
dart build/bin/server.dart
```

Swagger UI: [http://localhost:8080/docs](http://localhost:8080/docs), спецификация — `/openapi.json`. Если `build/openapi.json` отсутствует, `/docs` покажет подсказку с командой генерации.

Кнопка **Authorize** принимает access JWT или `DEBUG_TOKEN` (без префикса `Bearer`). Защищены только `/api/**`; `/auth/*` остаются открытыми. Path-параметры (`id`, `token`, …) появляются в Try it out сами.

CLI Dart Frog ставится один раз: `dart pub global activate dart_frog_cli`.

## Аутентификация

Пароля у пользователя нет. Клиент присылает сырую строку `WebApp.initData`, сервер проверяет HMAC-SHA256 токеном бота и выдаёт access JWT (`sub` = Telegram user id). Дальше все запросы к `/api/**` идут с заголовком `Authorization: Bearer <jwt>`. Детали и формат ответов — [api.md](api.md).

Для локальной разработки без Mini App: `DEBUG_AUTH=true` в `.env`. На старте создаётся пользователь `debug_admin` (`DEBUG_USER_ID`, по умолчанию `1`), а строка `DEBUG_TOKEN` (по умолчанию `dev-admin`) принимается как Bearer на `/api/**`. Это не JWT: `iat`/`exp` не меняются. Токен можно взять из `GET /auth/debug` или сразу вставить в Swagger Authorize. Если флаг выключен, магическая строка даёт `401`, эндпоинт — `404`. На проде флаг не включать.

## Состояние

Реализовано: `/`, `/health`, `/auth/validate`, `/auth/refresh`, `GET /auth/debug` (локальный Bearer при `DEBUG_AUTH`), Bearer-middleware для `/api/**`, Swagger, класс `Database`, автоматические миграции, CRUD вишлистов (`GET`/`POST`/`DELETE /api/wishlists`, `GET`/`PATCH`/`DELETE /api/wishlists/{id}`).

Остальные `/api/**` — заглушки (`501`). `PATCH /api/wishlists` (сортировка) пока тоже.
