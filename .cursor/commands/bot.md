# Работа над ботом MELIST

Задача касается `bot/` (Telegram-бот на Dart), `domain/` (общий доменный слой `melist_domain`) или их связки с `backend/`. Перед изменениями прочитай документацию и следуй ей.

## Обязательно прочитать

- [docs/bot/README.md](../../docs/bot/README.md) — архитектура, принципы, структура `bot/`, конфигурация, правила кода
- [docs/bot/roadmap.md](../../docs/bot/roadmap.md) — фазы и статусы (готово / в работе / очередь), раздел «Сейчас»
- [docs/bot/notifications.md](../../docs/bot/notifications.md) — события outbox, получатели, склейка, доставка, схема таблиц

## По необходимости

- [docs/backend/README.md](../../docs/backend/README.md), [best-practices.md](../../docs/backend/best-practices.md), [testing.md](../../docs/backend/testing.md) — если меняешь backend или сервисы, которые он вызывает
- [docs/backend/data-model.md](../../docs/backend/data-model.md) — схема PostgreSQL и порядок миграций
- [docs/backend/api.md](../../docs/backend/api.md) — если добавляешь эндпоинты настроек уведомлений
- [docs/README.md](../../docs/README.md) — нумерация функционала, на неё ссылаются фазы 7–8
- [.cursor/rules/bot.mdc](../rules/bot.mdc), [.cursor/rules/backend.mdc](../rules/backend.mdc) — краткие правила

## Порядок работы

1. Открой [docs/bot/roadmap.md](../../docs/bot/roadmap.md), возьми текущую фазу из «Сейчас» и первую задачу со статусом **очередь**. Не перескакивай фазы: каждая опирается на предыдущие. Если пользователь назвал конкретную задачу, проверь, что её зависимости готовы, и скажи, если нет.
2. Сверь задачу с кодом: что уже есть в `domain/`, `backend/`, `bot/`. Документация может отставать от кода. Если они расходятся, скажи об этом и поправь документацию.
3. Соблюдай границы:
   - доменная логика, SQL, миграции — только в `melist_domain`; бот и backend — тонкий транспорт;
   - с Telegram Bot API работает только бот через `TelegramClient`, backend его не вызывает;
   - события об изменениях пишутся в `outbox_events` в той же транзакции, что и данные;
   - статус брони желания (20) никогда не порождает уведомление;
   - схема меняется только новой миграцией `mNNNN_<name>.dart` + `allMigrations` + `data-model.md`; применённые не редактировать.
4. Напиши тесты рядом с изменениями: `bot/test/**` (fake `TelegramClient`, без сети), `domain/test/**`, для backend — по [testing.md](../../docs/backend/testing.md). Код с `SKIP LOCKED`, `LISTEN` и миграциями — integration-тестом с `TEST_DATABASE_URL`.
5. Прогони в каждом затронутом пакете (`domain/`, `backend/`, `bot/`):

```powershell
dart analyze
dart test
$env:TEST_DATABASE_URL='postgres://melist:melist@localhost:5433/melist?sslmode=disable'; dart test test/integration
```

   В backend после изменения `@Route` ещё `dart run dart_frog_swagger`. Если менялись Dockerfile или compose — `docker compose -f docker-compose.dev.yml up -d --build` из `backend/` и проверка `docker compose -f docker-compose.dev.yml ps`.

6. Обнови документацию:
   - в [docs/bot/roadmap.md](../../docs/bot/roadmap.md) поставь задаче **готово**, при закрытии фазы — статус фазы и «Сейчас»;
   - новая env-переменная — в `bot/.example_env` (или `backend/.example_env`) и в README пакета;
   - новая таблица — SQL в [data-model.md](../../docs/backend/data-model.md); новое событие или правило доставки — в [notifications.md](../../docs/bot/notifications.md);
   - новый эндпоинт — `api.md` и `docs/backend/roadmap.md`.

В ответе укажи: какая фаза и задачи закрыты, какие файлы изменены, какие тесты добавлены и прошли ли проверки, что обновлено в документации и какая задача следующая.
