# Roadmap бота

План реализации бота MELIST: сначала уведомления о подписках, затем резервный интерфейс с функционалом Mini App. Архитектура — [README.md](README.md), спецификация уведомлений — [notifications.md](notifications.md), нумерация функций — [docs/README.md](../README.md).

Статусы: **готово**, **в работе**, **очередь**.

Агент, закрывая задачу: поставь **готово** в таблице фазы, сдвинь «Сейчас» и обнови затронутые документы (`data-model.md`, `api.md`, README пакетов).

## Сейчас

Фаза 1 — вынос доменного слоя в `melist_domain`. Документация (фаза 0) готова.

## Фазы

Идти сверху вниз. Фазы 1–6 дают уведомления, 7–9 — резервный интерфейс.

### 0. Решения и документация — готово

| Задача | Статус |
|---|---|
| Выбор архитектуры: отдельный бот + outbox в Postgres | готово |
| `docs/bot/README.md`, `notifications.md`, `roadmap.md` | готово |
| Команда `/bot`, правило `.cursor/rules/bot.mdc` | готово |

### 1. Пакет `melist_domain` — очередь

Перенос без изменения поведения: API отвечает так же, все существующие тесты зелёные.

| Задача | Статус |
|---|---|
| Создать `domain/` (`pubspec.yaml`, `analysis_options.yaml`, `lib/melist_domain.dart`) без зависимости от `dart_frog` | очередь |
| Перенести `backend/lib/src/data/**` (`Database`, `DatabaseConfig`, `Migrator`, миграции, репозитории) | очередь |
| Перенести сервисы `wishes`, `wishlists`, `favorites`, `profiles`, `subscriptions` и `AuthUser`, `AppException` с наследниками. Маппинг исключений в HTTP (`responses.dart`), `*_handlers.dart`, JWT, cookies, CORS остаются в backend | очередь |
| Если сервис зависит от `AppConfig` (например, ссылки шаринга с `BOT_USERNAME`), передавать значение параметром, а не конфигом | очередь |
| Перенести unit- и integration-тесты сервисов и репозиториев в `domain/test`, хелперы (`fake_pool`, `memory_*`) — туда же | очередь |
| `backend/pubspec.yaml` → path-зависимость `melist_domain`; импорты `package:melist_backend/src/data/...` → `package:melist_domain/...` | очередь |
| `backend/Dockerfile`: в синтетический workspace добавить `domain` | очередь |
| Обновить `docs/backend/README.md` (структура), `data-model.md` (пути), `.cursor/rules/backend.mdc` (где лежат репозитории и миграции) | очередь |

Готово, когда: `dart analyze` и `dart test` зелёные в `domain/` и `backend/`, `docker compose -f docker-compose.dev.yml up -d --build` поднимает API, Swagger отвечает.

### 2. Каркас бота — очередь

| Задача | Статус |
|---|---|
| `bot/` пакет `melist_bot`, `bin/bot.dart`, `BotConfig` (`.env` + окружение, валидация на старте), `.example_env` | очередь |
| `TelegramClient` на `http`: `getMe`, `getUpdates`, `setWebhook`, `deleteWebhook`, `sendMessage`, `answerCallbackQuery`, `editMessageReplyMarkup`; типизированные ошибки (`TelegramRetryAfter`, `TelegramForbidden`, `TelegramBadRequest`, `TelegramServerError`) | очередь |
| Модели `Update`, `Message`, `User`, `CallbackQuery`, `ChatMemberUpdated` — только нужные поля | очередь |
| Транспорт `polling` (offset, long poll 30 с, backoff при ошибке сети) и `webhook` (`shelf`, проверка `X-Telegram-Bot-Api-Secret-Token`) | очередь |
| `UpdateRouter`: команды, callback по префиксу `callback_data`, `my_chat_member`; ошибка обработчика логируется и не роняет процесс | очередь |
| `/start` и `/start <payload>`: приветствие и кнопка «Открыть MELIST» → `https://t.me/<BOT_USERNAME>?startapp=<payload>` | очередь |
| `GET /health` | очередь |
| Старт: `Database.connect`, `Migrator.migrate`, `getMe`; graceful shutdown | очередь |
| `bot/Dockerfile` (контекст — корень, workspace `core` + `domain` + `bot`, `dart compile exe`), сервис `bot` в `backend/docker-compose.dev.yml` с `env_file: .env` и `DATABASE_URL` на `db` | очередь |
| Тесты: `BotConfig`, разбор апдейтов, роутер, вебхук (401 на чужой секрет), `TelegramClient` на fake `http.Client` | очередь |

Готово, когда: локально в режиме `polling` бот отвечает на `/start`, в compose три контейнера здоровы.

### 3. Чаты и право писать — очередь

| Задача | Статус |
|---|---|
| Миграция `m0006_notifications` целиком (все таблицы из [notifications.md](notifications.md#модель-данных)), SQL в `data-model.md` | очередь |
| `BotChatRepository`: `upsert(userId, status)`, `isActive`, `markBlocked` | очередь |
| Бот: `/start` → `active` (и `users.ensure` из `from`), `write_access_allowed` → `active`, `my_chat_member` `kicked` → `blocked`, `member` → `active` | очередь |
| Backend: `InitDataValidator` читает `allows_write_to_pm`; `/auth/validate` при `true` ставит `active`, если статус `unknown` или строки нет | очередь |
| Тесты переходов статусов, интеграционный тест миграции | очередь |

### 4. Outbox: события из сервисов — очередь

| Задача | Статус |
|---|---|
| `OutboxRepository(tx).add(type, actorId, wishlistId?, wishId?, payload)` + `NOTIFY melist_outbox` в той же транзакции | очередь |
| `WishlistService`: `create` (public), `update` (видимость, поля; перевести на `_transaction` + `FOR UPDATE`, сравнение старого и нового), `deleteOne`/`deleteMany` (`wishlist.closed` с `recipientIds`), `addWish`, `removeWish` | очередь |
| `WishService`: `update` (поля, кроме `status`), `deleteOne`/`deleteMany` → `wishlist.wishes_removed` для затронутых `public`-списков | очередь |
| `ProfileService.update`: `profile.updated` при смене никнейма или даты рождения | очередь |
| Правила: только `public`, не писать при неизменённом значении, никогда — на смену `status` | очередь |
| Тесты: на каждое действие — какое событие записано; откат транзакции → события нет; `status` не порождает события | очередь |

### 5. Доставка уведомлений — очередь

| Задача | Статус |
|---|---|
| `OutboxConsumer`: `LISTEN melist_outbox` на выделенном соединении + опрос раз в `NOTIFY_POLL_SECONDS`, пачки через `FOR UPDATE SKIP LOCKED`, `processed_at` | очередь |
| `Fanout`: получатели по таблице событий, минус автор, минус `muted`, только `bot_chats.active` и `notification_settings.enabled` | очередь |
| `Debouncer`: `INSERT ... ON CONFLICT (group_key) WHERE status='pending' DO UPDATE` со слиянием `payload` и `deliver_after` | очередь |
| `Deliverer`: выборка due, перепроверка видимости, рендер (HTML, экранирование, «и ещё N»), кнопки «Открыть» и «Не присылать» | очередь |
| `RateLimiter`: общий token bucket + 1 сообщение в секунду на чат, глобальная пауза при `429` | очередь |
| Обработка ответов по таблице из [notifications.md](notifications.md#доставка), экспоненциальный backoff, `NOTIFY_MAX_ATTEMPTS` | очередь |
| Callback `mute_wl:<id>` / `mute_user:<id>` → `muted = true`, ответ `answerCallbackQuery`, кнопка меняется на «Уведомления выключены» | очередь |
| Ежедневная очистка `outbox_events` и `notifications` | очередь |
| Тесты: склейка 10 событий → 1 сообщение, `403` → `blocked` и `skipped`, `429` → пауза без потери, непубличный список → `skipped`; integration: две параллельные выборки не берут одно событие | очередь |

Готово, когда: в compose-стеке подписчик получает одно сообщение после серии правок вишлиста, а блокировка бота прекращает попытки.

### 6. Настройки и frontend — очередь

| Задача | Статус |
|---|---|
| Backend: `GET`/`PATCH /api/v1/me/notifications`, `PATCH /api/v1/subscriptions/wishlists/{id}`, `PATCH /api/v1/subscriptions/users/{id}`, `muted` в `GET /api/v1/subscriptions/*`; `@Route`, тесты, `api.md`, `docs/backend/roadmap.md` | очередь |
| Frontend: `requestWriteAccess()` при первой подписке, если `allows_write_to_pm` не `true`; запоминать отказ | очередь |
| Frontend: экран настроек уведомлений (вкл/выкл, статус бота, ссылка «Открыть чат с ботом», если `blocked`), переключатель mute в списках подписок | очередь |
| Frontend: `startapp=list_<id>` — открыть публичный список (нужен backend-эндпоинт чтения чужого публичного списка по id) | очередь |

### 7. Резервный интерфейс: чтение — очередь

Бот повторяет основные экраны Mini App сообщениями с inline-клавиатурами; навигация через `editMessageText`, списки постранично по 8 элементов.

| Команда / экран | Функции | Статус |
|---|---|---|
| `/menu` — главное меню, `setMyCommands` | — | очередь |
| `/lists` — мои вишлисты → карточка → желания | 2.1, 2.2 | очередь |
| `/wishes` — все мои желания, поиск текстом | 16, 17 | очередь |
| `/favorites` — избранное | 9 | очередь |
| `/subs` — подписки на списки и профили, отписка, mute | 31, 32, 34, 35 | очередь |
| Профиль пользователя и его публичные списки по `/start profile_<id>` | 25 | очередь |
| Открытие списка по `/start wl_<token>`, добавление в избранное, подписка | 7, 8.1, 30, 33 | очередь |

### 8. Резервный интерфейс: изменение данных — очередь

Многошаговые действия требуют состояния диалога: таблица `bot_sessions (user_id PK, state TEXT, data JSONB, updated_at)`, TTL 1 час, `/cancel` сбрасывает.

| Действие | Функции | Статус |
|---|---|---|
| Создать желание (название → цена → ссылка, шаги можно пропустить) | 12 | очередь |
| Создать вишлист, сменить видимость | 1, 3.2 | очередь |
| Добавить желание в список, убрать из списка | 4.1, 4.2 | очередь |
| Редактировать желание и список | 3, 18 | очередь |
| Смена статуса желания | 20 | очередь |
| Удаление с подтверждением | 6.1, 21.1 | очередь |
| Поделиться списком (`switch_inline_query` / ссылка) | 7.1, 7.2 | очередь |

Сортировка перетаскиванием (5, 10), тема (26) и массовые операции (6.2, 21.2) в бот не переносятся.

### 9. Эксплуатация — очередь

| Задача | Статус |
|---|---|
| Режим `webhook` на проде, публичный URL за тем же reverse proxy, что API | очередь |
| Структурированные логи: `update_id`, `notification_id`, статус Telegram | очередь |
| Метрики в `/health`: длина очереди `pending`, число `failed` за час, возраст старейшего необработанного события | очередь |
| Алерт, если старейшее необработанное событие старше 5 минут | очередь |
