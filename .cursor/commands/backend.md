# Работа над backend MELIST

Задача касается `backend/` (Dart Frog + PostgreSQL). Перед изменениями прочитай документацию и следуй ей.

## Обязательно прочитать

- [docs/backend/README.md](../../docs/backend/README.md) — стек, структура `backend/`, `.env`, команды
- [docs/backend/best-practices.md](../../docs/backend/best-practices.md) — соглашения Dart Frog: роуты, `lib/`, DI, ошибки, секреты
- [docs/backend/testing.md](../../docs/backend/testing.md) — как писать и запускать тесты

## По необходимости

- [docs/backend/api.md](../../docs/backend/api.md) — контракты эндпоинтов, привязка к функционалу, статус реализации
- [docs/backend/data-model.md](../../docs/backend/data-model.md) — схема PostgreSQL, правила доступа
- [docs/README.md](../../docs/README.md) — продукт и нумерация функционала
- [.cursor/rules/backend.mdc](../rules/backend.mdc) — краткие правила

## Порядок работы

1. Найди в `docs/backend/api.md` эндпоинт или функцию, которую нужно реализовать; сверь с `routes/api/**`.
2. Логику пиши в `backend/lib/src/**`, роут оставляй тонким; пользователя бери из `context.read<AuthUser>()`.
3. Обнови или добавь `@Route(...)`; общие схемы — `lib/src/openapi/common_docs.dart`.
4. Напиши тесты: `test/routes/<тот же путь>_test.dart` и `test/src/**` для сервисов.
5. Прогони из `backend/`:

```powershell
dart run dart_frog_swagger
dart analyze
dart test
```

6. Если эндпоинт перестал быть заглушкой — поправь раздел «Статус реализации» в `docs/backend/api.md`. Новую env-переменную добавь в `.example_env` и `docs/backend/README.md`.

В ответе укажи, какие файлы изменены, какие тесты добавлены и что осталось заглушкой.
