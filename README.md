# MELIST

Telegram Mini App для вишлистов: пользователь собирает желания, делится списком по ссылке и подписывается на чужие профили и вишлисты.

Монорепозиторий — Dart workspace (`pubspec.yaml` в корне): один `pubspec.lock`, пакеты без версий друг на друга.

```
melist/
├── frontend/   # Flutter Web (Telegram Mini App)
├── backend/    # Dart Frog API + PostgreSQL
├── core/       # общие модели (melist_core)
└── docs/       # документация
```

Конфигурации запуска IntelliJ / Android Studio лежат в [`.idea/runConfigurations/`](.idea/runConfigurations/) и совпадают с командами ниже.

## Требования

- [Flutter](https://flutter.dev) / Dart SDK `^3.12`
- [Docker](https://docs.docker.com/get-docker/) — PostgreSQL
- Токен Telegram-бота (`BOT_TOKEN`)
- [ngrok](https://ngrok.com/) — публичный HTTPS для Mini App (конфиг `ngrok`)

Один раз поставить CLI:

```powershell
dart pub global activate dart_frog_cli
dart pub global activate dhttpd
dart pub global activate web_cache_killer
```

`dart` / `dart_frog` / `dhttpd` / `web_cache_killer` должны быть в `PATH` (обычно `%LOCALAPPDATA%\Pub\Cache\bin`).

## Первый запуск

Из корня репозитория:

```powershell
flutter pub get
```

Backend: скопировать шаблон env и заполнить секреты.

```powershell
Copy-Item backend/.example_env backend/.env
```

Минимум в `backend/.env`:

```
BOT_TOKEN=<токен бота>
JWT_SECRET=<случайная строка>
DATABASE_URL=postgres://melist:melist@localhost:5433/melist?sslmode=disable
BOT_USERNAME=melist_bot
DEBUG_AUTH=true
```

`DEBUG_AUTH=true` — локальный Bearer без Telegram (`DEBUG_TOKEN`, по умолчанию `dev-admin`). На проде не включать.

PostgreSQL из [`backend/docker-compose.yml`](backend/docker-compose.yml) слушает **хост-порт 5433** (внутри контейнера 5432):

```powershell
cd backend
docker compose up -d
```

Шаблон `.example_env` указывает `localhost:5432`. С compose нужен порт **5433**, как в `DATABASE_URL` выше.

## Запуск

Те же команды, что в IDE. Запускать в отдельных терминалах (или через Run Configurations).

| Конфиг IDE | Каталог | Команда | Зачем |
|---|---|---|---|
| `backend` | `backend/` | `dart_frog dev` | API с hot reload, [http://localhost:8080](http://localhost:8080) |
| `build-dev` | `frontend/` | `web_cache_killer` | Сборка Flutter Web с cache-busting → `frontend/build/web` |
| `web-server` | `frontend/` | `dhttpd --port 55456 --path build/web` | Статика Mini App, [http://localhost:55456](http://localhost:55456) |
| `build-release` | `frontend/` | `flutter build web --release --no-wasm-dry-run` | Релизная сборка в `frontend/build/web` |
| `ngrok` | корень | `ngrok http 55456` | HTTPS-туннель для BotFather / Telegram |

### Локальный контур Mini App

1. PostgreSQL: `docker compose up -d` из `backend/`.
2. API: конфиг **backend** → Swagger на [http://localhost:8080/docs](http://localhost:8080/docs), health — [http://localhost:8080/health](http://localhost:8080/health).
3. Сборка клиента: конфиг **build-dev**.
4. Раздача: конфиг **web-server**.
5. Публичный URL: конфиг **ngrok**. HTTPS из ngrok указать в BotFather как Web App URL.

После правок frontend снова **build-dev**, затем перезагрузить Mini App в Telegram (кэш JS сбивается timestamp’ами в именах файлов).

Для Swagger без Mini App: Authorize → вставить `DEBUG_TOKEN` (без `Bearer`) или JWT из `POST /auth/validate`.

### Команды вручную

```powershell
# API
cd backend
dart_frog dev

# Клиент: сборка с cache-busting (как build-dev)
cd frontend
web_cache_killer

# Клиент: раздача (как web-server)
cd frontend
dhttpd --port 55456 --path build/web

# Клиент: релиз (как build-release)
cd frontend
flutter build web --release --no-wasm-dry-run

# Туннель (как ngrok)
ngrok http 55456
```

OpenAPI после изменения `@Route`:

```powershell
cd backend
dart run dart_frog_swagger
```

## Тесты и анализ

```powershell
# workspace: зависимости уже стоят через flutter pub get из корня

cd backend
dart analyze
dart test
# интеграционные тесты на живой PostgreSQL (создают временную БД и удаляют её)
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
