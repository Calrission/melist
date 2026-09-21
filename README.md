# MELIST

Telegram Mini App для вишлистов: пользователь собирает желания, делится списком по ссылке и подписывается на чужие профили и вишлисты.

Монорепозиторий — Dart workspace (`pubspec.yaml` в корне): один `pubspec.lock`, пакеты без версий друг на друга.

```
melist/
├── frontend/              # Flutter Web (Telegram Mini App), сборка → `.build/web`
├── backend/               # Dart Frog API
│   ├── docker-compose.yml # PostgreSQL + API
│   └── Dockerfile         # образ API, контекст — корень репозитория
├── core/                  # общие модели (melist_core)
└── docs/                  # документация
```

Конфигурации запуска IntelliJ / Android Studio — [`.idea/runConfigurations/`](.idea/runConfigurations/). Они совпадают с командами frontend и локального `dart_frog dev` ниже. Стек API в Docker запускается compose, не из IDE.

## Требования

- [Docker](https://docs.docker.com/get-docker/) — Postgres и API
- Токен Telegram-бота (`BOT_TOKEN`) и `JWT_SECRET` в `backend/.env`

Для frontend, тестов и hot reload API на хосте дополнительно:

- [Flutter](https://flutter.dev) / Dart SDK `^3.12`
- [ngrok](https://ngrok.com/) — публичный HTTPS Mini App (конфиг `ngrok`)

```powershell
dart pub global activate dart_frog_cli
dart pub global activate dhttpd
dart pub global activate web_cache_killer
```

`dart` / `dart_frog` / `dhttpd` / `web_cache_killer` должны быть в `PATH` (обычно `%LOCALAPPDATA%\Pub\Cache\bin`).

## Первый запуск

```powershell
Copy-Item backend/.example_env backend/.env
```

Заполнить в `backend/.env`:

```
BOT_TOKEN=<токен бота>
JWT_SECRET=<случайная строка>
BOT_USERNAME=melist_bot
DEBUG_AUTH=true
```

`DEBUG_AUTH=true` — локальный Bearer без Telegram (`DEBUG_TOKEN`, по умолчанию `dev-admin`). На проде не включать.

`DATABASE_URL` в `.env` нужен **хостовому** `dart_frog dev` (порт **5433**). Контейнер API его игнорирует и ходит в сервис `db` на `5432`.

```
DATABASE_URL=postgres://melist:melist@localhost:5433/melist?sslmode=disable
```

Зависимости workspace — если будете собирать frontend или гонять тесты:

```powershell
flutter pub get
```

## Backend (Docker)

Из `backend/`. Нужен заполненный `.env` (`BOT_TOKEN`, `JWT_SECRET`).

```powershell
cd backend
docker compose up -d --build
```

| Сервис | Контейнер | С хоста |
|---|---|---|
| API | `melist-api` | [http://localhost:8080](http://localhost:8080) |
| PostgreSQL | `melist-pg` | `localhost:5433` |

- Health: [http://localhost:8080/health](http://localhost:8080/health)
- Swagger: [http://localhost:8080/docs](http://localhost:8080/docs), спецификация — `/openapi.json`
- Внутри API `DATABASE_URL` = `postgres://melist:melist@db:5432/melist?sslmode=disable`

Остановить: `docker compose down`. Данные Postgres остаются в томе `melist-pg-data`.

Только база, API на хосте с hot reload (конфиг IDE **backend**):

```powershell
docker compose up -d db
cd backend
dart_frog dev
```

Не запускайте `dart_frog dev` и контейнер `melist-api` одновременно: оба слушают **8080**.

В Swagger Authorize вставить `DEBUG_TOKEN` (без `Bearer`) или JWT из `POST /auth/validate`.

OpenAPI после изменения `@Route` (для `dart_frog dev`; в образе генерируется при `docker compose build`):

```powershell
cd backend
dart run dart_frog_swagger
```

## Frontend (конфиги IDE)

Запускать в отдельных терминалах. Сначала собрать, потом раздать.

| Конфиг IDE | Каталог | Команда | Зачем |
|---|---|---|---|
| `build-dev` | `frontend/` | `web_cache_killer`, затем `build/` → `.build/` | Сборка Flutter Web с cache-busting → `frontend/.build/web` |
| `web-server` | `frontend/` | `dhttpd --port 55456 --path .build/web` | Статика Mini App, [http://localhost:55456](http://localhost:55456) |
| `build-release` | `frontend/` | `flutter build web --release --no-wasm-dry-run -o .build/web` | Релизная сборка в `frontend/.build/web` |
| `ngrok` | корень | `ngrok http 55456` | HTTPS-туннель для BotFather / Telegram |
| `backend` | `backend/` | `dart_frog dev` | API на хосте, если не используете контейнер `melist-api` |

`web_cache_killer` всегда пишет в `build/`; после успешной сборки каталог переименовывается в `.build/` (в gitignore). Раздавать нужно `.build/web`.

```powershell
cd frontend
web_cache_killer
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
if (Test-Path .build) { Remove-Item -Recurse -Force .build }
Rename-Item build .build
dhttpd --port 55456 --path .build/web

# в другом терминале, из корня репозитория
ngrok http 55456
```

HTTPS из ngrok указать в BotFather как Web App URL. После правок frontend снова **build-dev**, затем перезагрузить Mini App в Telegram.

## Тесты и анализ

Нужны `flutter pub get` из корня и живой Postgres на `localhost:5433` для интеграционных тестов.

```powershell
cd backend
dart analyze
dart test
$env:TEST_DATABASE_URL='postgres://melist:melist@localhost:5433/melist?sslmode=disable'; dart test test/integration

cd ../core
dart analyze
dart test

cd ../frontend
flutter analyze
flutter test
```

Сценарии продукта: `dart test test/scenarios` из `backend/` (см. [docs/scenarios.md](docs/scenarios.md)).

## Документация

- [Продукт и нумерация функций](docs/README.md)
- [Сценарии использования](docs/scenarios.md)
- [Backend: запуск, env, команды](docs/backend/README.md)
- [Backend: API](docs/backend/api.md)
- [Backend: roadmap](docs/backend/roadmap.md)
- [Backend: модель данных](docs/backend/data-model.md)
- [Backend: тестирование](docs/backend/testing.md)
