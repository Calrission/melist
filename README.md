# MELIST

Telegram Mini App для вишлистов: пользователь собирает желания, делится списком по ссылке и подписывается на чужие профили и вишлисты.

Монорепозиторий — Dart workspace (`pubspec.yaml` в корне): один `pubspec.lock`, пакеты без версий друг на друга.

```
melist/
├── frontend/              # Flutter Web (Telegram Mini App), сборка → `build/web` или `.build/web`
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
dart pub global activate web_cache_killer
```

`dart` / `dart_frog` / `web_cache_killer` должны быть в `PATH` (обычно `%LOCALAPPDATA%\Pub\Cache\bin`).

## Первый запуск

```powershell
Copy-Item backend/.example_env backend/.env
```

Заполнить в `backend/.env`:

```
BOT_TOKEN=<токен бота>
JWT_SECRET=<случайная строка>
BOT_USERNAME=meelist_dev_bot
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

Сборка Flutter Web раздаётся тем же процессом, что и API, на порту **8080**. Mini App — [http://localhost:8080](http://localhost:8080). Пока есть `index.html` в `frontend/build/web` (build-dev) или `frontend/.build/web` (build-release), берётся более новая сборка. `/api`, `/auth`, `/health`, `/docs` и `/openapi.json` остаются API. Сборки нет — только API, `GET /` отвечает JSON.

Иконочный шрифт и Dart-класс генерируются из SVG в `frontend/assets/raw_icons/` по конфигурации `frontend/icon_font.yaml`:

```powershell
cd frontend
flutter pub run icon_font_generator:generator
```

Генератор создаёт `frontend/assets/fonts/melist_icons.otf` и `frontend/lib/presentation/icons/melist_icons.dart`. Шрифт зарегистрирован в `frontend/pubspec.yaml`.

| Конфиг IDE | Каталог | Команда | Зачем |
|---|---|---|---|
| `build-dev` | `frontend/` | `web_cache_killer`, затем `build/` → `.build/` | Сборка Flutter Web с cache-busting → `frontend/.build/web` |
| `build-release` | `frontend/` | `flutter build web --release --no-wasm-dry-run -o .build/web` | Релизная сборка в `frontend/.build/web` |
| `ngrok` | корень | `ngrok start --all --config ngrok.yml` | Один HTTPS-туннель на **8080** |
| `backend` | `backend/` | `dart_frog dev` | API и статика на хосте, если не используете контейнер `melist-api` |

`web_cache_killer` пишет в `frontend/build/web`. Релизная сборка — в `frontend/.build/web`. Бэкенд отдаёт ту, у которой новее `index.html` (переопределение — `WEB_ROOT` в `backend/.env`). Появившийся `index.html` подхватывается без перезапуска, смена каталога — после перезапуска бэкенда. Контейнер `melist-api` монтирует каталог `frontend/` и читает ту же сборку.

`API_URL` в `frontend/.env` оставьте пустым — запросы идут на тот же origin, в том числе через ngrok. Конфиг `main.dart` (`flutter run`, порт **8081**) по-прежнему на другом origin: тогда `API_URL=http://localhost:8080` и `CORS_ORIGINS` с этим origin.

```powershell
cd frontend
web_cache_killer
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
if (Test-Path .build) { Remove-Item -Recurse -Force .build }
Rename-Item build .build

# API уже слушает 8080 — Mini App: http://localhost:8080

# в другом терминале, из корня репозитория
ngrok start --all --config ngrok.yml
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
