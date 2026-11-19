# Bot

Telegram-бот MELIST — отдельный сервис (пакет `melist_bot`, каталог `bot/`). Сейчас его задача — уведомлять пользователей об изменениях в профилях и вишлистах, на которые они подписаны. Дальше бот станет **резервным интерфейсом**: тот же функционал, что в Mini App, доступный в чате, когда сайт не работает.

Связанные документы:

- [Уведомления: события, получатели, доставка](notifications.md)
- [Roadmap бота](roadmap.md)
- [Backend](../backend/README.md), [модель данных](../backend/data-model.md)

## Архитектура

Три процесса и одна база:

```mermaid
flowchart LR
  subgraph clients [Клиенты]
    MiniApp[Mini App, Flutter Web]
    Chat[Чат с ботом]
  end
  subgraph services [Сервисы]
    API[backend, Dart Frog]
    Bot[bot: webhook, worker уведомлений]
  end
  Domain[[пакет melist_domain: репозитории, сервисы, миграции]]
  PG[(PostgreSQL)]
  TG[Telegram Bot API]

  MiniApp -->|REST + JWT| API
  API --- Domain
  Bot --- Domain
  Domain --> PG
  API -->|"outbox_events + NOTIFY в той же транзакции"| PG
  PG -->|"LISTEN, SKIP LOCKED"| Bot
  TG -->|"webhook / getUpdates"| Bot
  Bot -->|sendMessage| TG
  TG --> Chat
  Chat -->|"кнопка startapp"| MiniApp
```

Принципы:

1. **С Bot API работает только бот.** Backend не вызывает `api.telegram.org`. `BOT_TOKEN` в backend нужен только для офлайн-проверки HMAC `initData`.
2. **Бизнес-логика живёт в одном месте — `melist_domain`.** Backend и бот вызывают одни и те же сервисы (`WishlistService`, `SubscriptionService`, …). Бот не пишет свой SQL для доменных таблиц и не ходит в backend по HTTP: иначе при падении API бот тоже перестанет работать, а резерв нужен именно на этот случай.
3. **Backend сообщает об изменениях через outbox.** Сервис, изменивший данные, в той же транзакции пишет событие в `outbox_events` и делает `NOTIFY melist_outbox`. Событие появляется тогда и только тогда, когда закоммичены данные.
4. **Бот доставляет асинхронно.** Обработчик раскладывает события по получателям (`notifications`), склеивает частые изменения, учитывает лимиты Telegram и повторяет отправку при сбоях. Падение бота не ломает API: события копятся и доставляются после рестарта.
5. **Схема общая, миграции одни.** Все миграции лежат в `melist_domain`, `Migrator` вызывают оба процесса при старте (advisory lock защищает от двойного применения). Таблицы бота (`bot_chats`, `notifications`, позже `bot_sessions`) пишет только бот, кроме оговорённых в [notifications.md](notifications.md#владение-таблицами) случаев.

### Почему бот, а не уведомления из backend

Варианты рассматривались: отправка прямо из запроса, outbox внутри процесса API, отдельный бот, брокер сообщений, дайджест по cron. Выбран отдельный бот, потому что:

- ему всё равно нужен свой процесс для входящих апдейтов (`/start`, блокировка бота, команды резервного интерфейса);
- он масштабируется и перезапускается независимо от API;
- outbox в Postgres даёт гарантию доставки без новой инфраструктуры. Брокер (Redis Streams, NATS) можно поставить позже, контракт событий от этого не изменится.

## Структура (целевая)

```
melist/
├── core/      # melist_core: модели, общие с frontend (без postgres)
├── domain/    # melist_domain: Database, миграции, репозитории, сервисы, AppException, AuthUser
├── backend/   # melist_backend: Dart Frog, HTTP-транспорт над melist_domain
└── bot/       # melist_bot: Telegram-транспорт над melist_domain
```

```
bot/
├── bin/bot.dart                 # точка входа: BotConfig, Database, Migrator, запуск транспорта и worker
├── lib/
│   ├── melist_bot.dart
│   └── src/
│       ├── config/              # BotConfig (.env + окружение, как AppConfig)
│       ├── telegram/            # TelegramClient: тонкий клиент Bot API, модели Update/Message, ошибки
│       ├── transport/           # LongPolling, WebhookServer (shelf) — источники Update
│       ├── updates/             # UpdateRouter и обработчики: /start, my_chat_member, write_access_allowed, callback
│       ├── chats/               # BotChatRepository, статус чата (active / blocked)
│       ├── notifications/       # OutboxConsumer, Fanout, Debouncer, Deliverer, рендер текстов
│       └── ratelimit/           # RateLimiter: общий лимит и лимит на чат
├── test/                        # зеркало lib/src, fake TelegramClient, integration (TEST_DATABASE_URL)
├── Dockerfile                   # контекст — корень репозитория, как у backend
├── .example_env
└── pubspec.yaml
```

`bot/` и `domain/`, как и `backend/`, не входят в корневой Flutter-workspace: зависимости разрешаются у каждого пакета отдельно, `Dockerfile` собирает временный workspace из `core` + `domain` + пакета сервиса.

## Стек

- Dart `^3.12`, без Flutter.
- `melist_domain`, `melist_core` — path-зависимости.
- `postgres` `^3.5` — через `Database` из `melist_domain`, `LISTEN` на `melist_outbox`.
- `http` — `TelegramClient`. Свой тонкий клиент вместо фреймворка: полный контроль над `429 retry_after`, таймаутами и тестами через fake. Если для резервного интерфейса понадобятся диалоги со сложным состоянием, вопрос о фреймворке (`televerse`) решается отдельно.
- `shelf` — HTTP-сервер вебхука и `/health`.
- Тесты: `test`, `mocktail`; линтер `very_good_analysis` или тот же набор правил, что в backend.

## Получение апдейтов

| Режим | Когда | Как |
|---|---|---|
| `polling` | локальная разработка | `getUpdates` с long polling. Перед стартом `deleteWebhook`, иначе Telegram вернёт `409`. ngrok не нужен. |
| `webhook` | прод, стенды | `setWebhook(url, secret_token, allowed_updates)` на старте. Сервер принимает `POST /telegram/webhook`, проверяет заголовок `X-Telegram-Bot-Api-Secret-Token`, на чужой секрет отвечает `401`. |

Отвечаем Telegram `200` сразу после записи апдейта в очередь обработки; долгие действия не держат HTTP-ответ. На один токен — один активный режим: dev-бот (`meelist_dev_bot`) и прод-бот используют разные токены.

`allowed_updates`: `message`, `callback_query`, `my_chat_member`.

## Конфигурация

`bot/.env` (шаблон — `bot/.example_env`); окружение процесса важнее файла, как в backend. В docker-compose бот читает тот же `backend/.env`, поэтому общие переменные заводятся один раз.

```
BOT_TOKEN=                  # тот же токен, что у backend
BOT_USERNAME=meelist_dev_bot
DATABASE_URL=postgres://melist:melist@localhost:15432/melist?sslmode=disable
BOT_UPDATES_MODE=polling    # polling | webhook
BOT_WEBHOOK_URL=            # https://<host>/telegram/webhook, обязателен при webhook
BOT_WEBHOOK_SECRET=         # 1–256 символов [A-Za-z0-9_-], обязателен при webhook
BOT_PORT=8090               # webhook и GET /health
NOTIFY_ENABLED=true         # false — worker уведомлений не запускается
NOTIFY_POLL_SECONDS=5       # страховочный опрос outbox, если NOTIFY потерялся
NOTIFY_DEBOUNCE_SECONDS=120 # окно склейки событий
NOTIFY_MAX_DELAY_SECONDS=900  # дольше не откладываем, даже если события продолжают приходить
NOTIFY_RATE_PER_SECOND=25   # общий лимит отправки (у Telegram около 30)
NOTIFY_MAX_ATTEMPTS=5
```

`BotConfig.load()` падает на старте, если пусты `BOT_TOKEN`, `DATABASE_URL`, `BOT_USERNAME` или (в режиме `webhook`) `BOT_WEBHOOK_URL` / `BOT_WEBHOOK_SECRET`.

## Старт процесса (`bin/bot.dart`)

1. `BotConfig.load()`.
2. `Database.fromUrl(...)`, `connect()`, `Migrator(database).migrate()` — так же, как в `backend/main.dart`; ошибка завершает процесс.
3. `TelegramClient.getMe()` — проверка токена; `username` сверяется с `BOT_USERNAME`.
4. Транспорт: `deleteWebhook` + long polling или `setWebhook` + `WebhookServer`.
5. Если `NOTIFY_ENABLED`: `OutboxConsumer` (LISTEN + опрос), `Deliverer`.
6. SIGINT/SIGTERM: перестать брать новые задачи, дождаться текущих отправок (до 10 с), закрыть пул.

`GET /health` поднимается в обоих режимах: `200 {"status":"ok"}`, если есть соединение с БД и транспорт работает.

## Команды

Из `bot/`:

```powershell
dart pub get
dart run bin/bot.dart              # локально, BOT_UPDATES_MODE=polling
dart analyze
dart test
$env:TEST_DATABASE_URL='postgres://melist:melist@localhost:15432/melist?sslmode=disable'; dart test test/integration
```

Весь стек из `backend/`:

```powershell
docker compose -f docker-compose.dev.yml up -d --build       # db + backend + bot
docker compose -f docker-compose.dev.yml logs -f bot
```

## Правила кода

- Обработчики апдейтов тонкие, как роуты Dart Frog: разобрать апдейт, собрать `AuthUser` из `from`, вызвать сервис из `melist_domain`, отрендерить ответ. Доменные проверки (владелец, видимость, валидация) — только в сервисах.
- `AuthUser` в боте строится из `update.from` и только после того, как апдейт пришёл от Telegram (секрет вебхука или `getUpdates`). Данные из текста сообщения и `callback_data` — недоверенный ввод, ID в них перепроверяются сервисом.
- `callback_data` ≤ 64 байт: формат `<action>:<id>`, например `mute_wl:123`.
- SQL — только в репозиториях `melist_domain` с параметрами `@name`. Таблицы бота тоже описываются миграциями в `melist_domain`.
- Все вызовы Bot API идут через `TelegramClient`; ошибки — типизированные (`TelegramRetryAfter`, `TelegramForbidden`, `TelegramBadRequest`, `TelegramServerError`).
- Тексты сообщений — HTML parse mode, пользовательские строки (название списка, ник) всегда экранируются.
- Секреты только через `BotConfig`; новую переменную — в `bot/.example_env` и этот файл.
