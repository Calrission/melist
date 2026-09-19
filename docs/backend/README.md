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
- PostgreSQL через пакет `postgres` — запланировано, см. [data-model.md](data-model.md)
- Тесты: `test`, `mocktail`, `dart_frog_test`; линтер `dart_frog_lint`

## Структура

```
backend/
├── routes/                     # эндпоинты (файл = путь)
│   ├── _middleware.dart        # логи, CORS, провайдеры конфигов/сервисов, Swagger UI
│   ├── index.dart              # GET /
│   ├── health.dart             # GET /health
│   ├── auth/
│   │   ├── validate.dart       # POST /auth/validate  (initData -> JWT)
│   │   └── refresh.dart        # POST /auth/refresh   (initData -> новый JWT)
│   └── api/                    # защищённые роуты (Bearer JWT)
│       ├── _middleware.dart    # bearerAuthentication -> AuthUser в контексте
│       ├── me/ users/ wishlists/ wishes/ favorites/ shared/
│       ├── subscriptions/ ads/ donations/
├── lib/
│   ├── melist_backend.dart     # публичный экспорт
│   └── src/
│       ├── auth/               # InitDataValidator, JwtService, AuthUser, authenticate
│       ├── config/             # AppConfig (.env)
│       ├── http/               # общие ответы (notImplemented, ошибки)
│       └── openapi/            # переиспользуемые схемы для @Route
├── test/
│   ├── routes/                 # зеркало routes/
│   ├── src/                    # unit-тесты сервисов
│   └── helpers/                # генерация тестового initData
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
DATABASE_URL=       # postgres://user:pass@host:5432/melist (после подключения БД)
```

`AppConfig.load()` читает `.env` и переменные окружения, падает на старте, если `BOT_TOKEN` или `JWT_SECRET` пусты. Секреты в код не попадают: см. `lib/src/config/app_config.dart`.

Значения по умолчанию: TTL access JWT — 1 час, максимальный возраст `initData` — 24 часа.

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

# все тесты
dart test

# один файл / фильтр по имени
dart test test/routes/auth/validate_test.dart
dart test -n "POST /auth/validate"

# production-сборка (build/, включая Dockerfile)
dart_frog build
dart build/bin/server.dart
```

Swagger UI: [http://localhost:8080/docs](http://localhost:8080/docs), спецификация — `/openapi.json`. Если `build/openapi.json` отсутствует, `/docs` покажет подсказку с командой генерации.

CLI Dart Frog ставится один раз: `dart pub global activate dart_frog_cli`.

## Аутентификация

Пароля у пользователя нет. Клиент присылает сырую строку `WebApp.initData`, сервер проверяет HMAC-SHA256 токеном бота и выдаёт access JWT (`sub` = Telegram user id). Дальше все запросы к `/api/**` идут с заголовком `Authorization: Bearer <jwt>`. Детали и формат ответов — [api.md](api.md).

## Состояние

Реализовано: `/`, `/health`, `/auth/validate`, `/auth/refresh`, Bearer-middleware для `/api/**`, Swagger.

Все `/api/**` эндпоинты созданы как заглушки: проверяют метод и JWT, возвращают `501 { "error": "Not implemented" }`. База данных не подключена — схема описана в [data-model.md](data-model.md).
