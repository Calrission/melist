# Best practices: Dart Frog

Собрано из [официальной документации Dart Frog](https://dart-frog.dev) (routes, middleware, dependency injection, authentication) и опыта проекта. Тестирование — отдельно в [testing.md](testing.md).

## 1. Роуты тонкие, логика в `lib/`

`routes/` — только транспорт: проверить метод, распарсить тело, вызвать сервис, собрать `Response`. Бизнес-логика, валидация, работа с БД — в `lib/src/**` и покрыты unit-тестами без HTTP.

```dart
// routes/auth/validate.dart — хорошо: делегирует
Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }
  return authenticateWithInitData(
    request: context.request,
    validator: context.read<InitDataValidator>(),
    jwtService: context.read<JwtService>(),
  );
}
```

Ориентир для `lib/src/`: `auth/`, `config/`, `http/`, `openapi/`, дальше `data/` (репозитории) и `services/` по мере подключения БД.

## 2. Файловая маршрутизация без конфликтов

- `routes/x/index.dart` → `/x`, `routes/x/[id].dart` → `/x/:id`, `routes/x/[id]/y.dart` → `/x/:id/y`.
- Не создавайте `routes/x.dart` при существующем каталоге `routes/x/` («rogue route»).
- Не ставьте статический файл рядом с динамическим (`routes/x/[id].dart` + `routes/x/reorder.dart`): динамический сегмент может перехватить путь. Массовые операции и сортировка — методами на коллекции (`PATCH /api/wishlists`), как в [api.md](api.md).
- Один файл обслуживает все методы пути: ветвите по `context.request.method`, на остальные отвечайте `405`.

## 3. Middleware и DI

- `routes/_middleware.dart` — глобально; `routes/api/_middleware.dart` — только для `/api/**`. Аутентификацию вешайте на подпапку, а не на корень, чтобы `/health` и `/auth/*` оставались открытыми.
- Зависимости отдаются через `provider<T>` и читаются `context.read<T>()`. Провайдер ленивый: объект создаётся при первом `read`.
- Порядок важен: Dart Frog резолвит снизу вверх. Если `B` зависит от `A`, то `handler.use(B()).use(A())` — `A` объявляется **после** (ниже) `B`. В `routes/_middleware.dart` `AppConfig` объявлен выше `InitDataValidator`/`JwtService`, потому что они читают конфиг внутри своего `create`-колбэка, а не в момент регистрации.
- Тяжёлые ресурсы (пул БД, HTTP-клиенты) создавайте один раз (кэш в top-level переменной или `provider`, возвращающий один экземпляр), а не на каждый запрос.

## 4. Аутентификация

- Пароля нет: вход только через проверенный Telegram `initData` (HMAC токеном бота), затем access JWT. `initDataUnsafe` на сервере не используется.
- Защищённые роуты — `dart_frog_auth` `bearerAuthentication<AuthUser>` в `routes/api/_middleware.dart`. При невалидном токене middleware сам отвечает `401`; в хендлере пользователь доступен как `context.read<AuthUser>()`.
- Никогда не доверяйте `userId` из тела запроса — только из `AuthUser`.
- Проверку владения ресурсом (`owner_id == AuthUser.id`) делайте в сервисе и возвращайте `403`.

## 5. Ответы и ошибки

- JSON через `Response.json(...)`; успешные коды: `200`, `201` при создании, `204` при удалении.
- Единый формат ошибки `{ "error": "<сообщение>" }`; хелперы в `lib/src/http/responses.dart` (`badRequest`, `notImplemented`, …). Не отдавайте стек-трейсы и внутренние детали.
- Валидируйте тело явно: `request.json()` может бросить `FormatException` или вернуть не `Map`. Оборачивайте разбор и отвечайте `400`.
- Для не поддерживаемых методов — `405`, не `404`.

## 6. Конфигурация и секреты

- Все секреты через `AppConfig` из `.env` / переменных окружения; в коде нет литералов токенов.
- `AppConfig.load()` падает на старте при отсутствии обязательных переменных — лучше упасть сразу, чем отдавать `500` под нагрузкой.
- `.env` в `.gitignore`, актуальный шаблон — `.example_env`. Новую переменную добавляйте в оба места и в [README.md](README.md).

## 7. OpenAPI

- Каждый эндпоинт помечен `@Route(...)` из `dart_frog_swagger`: `method`, `path`, `summary`, `description`, `tags`, `requestBody`, `responses`.
- Общие схемы (ошибка, JWT, пагинация) держите в `lib/src/openapi/*_docs.dart` и переиспользуйте, чтобы Swagger был согласован.
- После изменения аннотаций перегенерируйте спецификацию: `dart run dart_frog_swagger`. Файл `build/openapi.json` не коммитится.

## 8. Код-стайл

- Линтер `dart_frog_lint` (`analysis_options.yaml`), `dart analyze` без предупреждений перед коммитом.
- Именование файлов роутов — как в URL (`kebab-case` не нужен: пути в проекте односложные, `snake_case` не используем в путях).
- Хендлер — всегда `onRequest`; параметры пути приходят вторым аргументом: `onRequest(RequestContext context, String id)`.
- Не блокируйте изолят синхронной работой; всё I/O — `async`.

## 9. Развёртывание

- `dart_frog build` собирает `build/` с `Dockerfile`; запускать `dart build/bin/server.dart`.
- Порт берётся из `PORT` (по умолчанию `8080`), хост — `0.0.0.0` в контейнере.
- Перед сборкой в CI запускайте `dart run dart_frog_swagger`, иначе `/docs` покажет ошибку об отсутствующем `openapi.json`.

## Ссылки

- [Routes](https://dart-frog.dev/basics/routes/)
- [Middleware](https://dart-frog.dev/basics/middleware/)
- [Dependency Injection](https://dart-frog.dev/basics/dependency-injection/)
- [Authentication](https://dart-frog.dev/advanced/authentication/) и [`dart_frog_auth`](https://pub.dev/packages/dart_frog_auth)
- [CORS](https://dart-frog.dev/advanced/cors/)
- [`dart_frog_swagger`](https://pub.dev/packages/dart_frog_swagger)
- [`dart_frog_lint`](https://pub.dev/packages/dart_frog_lint)
