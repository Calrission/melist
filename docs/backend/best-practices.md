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
    users: context.read<UserRepository>(),
    sessions: context.read<AuthSessionService>(),
    cookieSecure: context.read<AppConfig>().cookieSecure,
  );
}
```

Ориентир для `lib/src/`: `auth/`, `config/`, `data/` (`Database`, репозитории), `http/`, `openapi/`, дальше `services/` по мере роста логики.

## 2. Файловая маршрутизация без конфликтов

- `routes/x/index.dart` → `/x`, `routes/x/[id].dart` → `/x/:id`, `routes/x/[id]/y.dart` → `/x/:id/y`.
- Не создавайте `routes/x.dart` при существующем каталоге `routes/x/` («rogue route»).
- Не ставьте статический файл рядом с динамическим (`routes/x/[id].dart` + `routes/x/reorder.dart`): динамический сегмент может перехватить путь. Массовые операции и сортировка — методами на коллекции (`PATCH /api/wishlists`), как в [api.md](api.md).
- Один файл обслуживает все методы пути: ветвите по `context.request.method`, на остальные отвечайте `405`.

## 3. Middleware и DI

- `routes/_middleware.dart` — глобально; `routes/api/_middleware.dart` — только для `/api/**`. Аутентификацию вешайте на подпапку, а не на корень, чтобы `/health` и `/auth/*` оставались открытыми.
- Зависимости отдаются через `provider<T>` и читаются `context.read<T>()`. Провайдер ленивый: объект создаётся при первом `read`.
- Порядок важен: Dart Frog резолвит снизу вверх. Если `B` зависит от `A`, то `handler.use(B()).use(A())` — `A` объявляется **после** (ниже) `B`. В `routes/_middleware.dart` `AppConfig` объявлен выше `InitDataValidator`/`JwtService`, потому что они читают конфиг внутри своего `create`-колбэка, а не в момент регистрации.
- Тяжёлые ресурсы (пул БД, HTTP-клиенты) создавайте один раз и проверяйте на старте, а не на первом запросе. Место для этого — кастомная точка входа `main.dart` (`Future<HttpServer> run(Handler handler, InternetAddress ip, int port)`): там создаются `AppConfig` и `Database`, выполняется `await database.connect()`, и готовые экземпляры отдаются через `handler.use(provider<T>((_) => instance))` над всем роутером. Ленивые `provider` в `_middleware.dart` для таких зависимостей не используйте — иначе сервер стартует с неверным `DATABASE_URL` и падает только на первом запросе к БД.
- В `routes/_middleware.dart` остаются только дешёвые per-request сервисы (`InitDataValidator`, `JwtService`), которые читают `AppConfig` из контекста.

## 3a. Работа с базой данных

- Единственная точка доступа к PostgreSQL — `Database` (`lib/src/data/database.dart`), в роутах `context.read<Database>()`. Напрямую `package:postgres` в `routes/` не импортировать.
- SQL живёт в репозиториях `lib/src/data/*_repository.dart`, по одному на агрегат (`WishlistRepository`, `WishRepository`, …). Репозиторий принимает `DbExecutor` в конструктор, поэтому его можно вызвать и с `Database`, и с транзакцией `tx`.
- Только параметризованные запросы с `@name`; интерполяция значений в строку SQL запрещена. Динамические части (сортировка, набор колонок) — из белого списка констант.
- Проверка владения — в SQL: `WHERE id = @id AND owner_id = @ownerId`. Ноль затронутых строк → `404` или `403` по ситуации, а не отдельный `SELECT` перед `UPDATE`.
- Несколько записей, которые должны измениться вместе (создать желание и привязать к вишлисту, пересортировать позиции), — в `db.transaction((tx) async { ... })`. Внутри используйте только `tx`, не `db`.
- Ошибки драйвера ловите там, где знаете, что с ними делать: `UniqueViolationException` → `409`, `ForeignKeyViolationException` → `400`/`404`. Остальное — `500` без деталей в ответе.
- Читайте значения через `row['column']` из `Map<String, dynamic>` и сразу собирайте модель (`fromRow`), не протаскивайте `Map` в роуты.
- `DATABASE_URL` разбирается `DatabaseConfig.parse` на старте в `main.dart`; ошибка формата или подключения — процесс не стартует. Размер пула — `?max_connections=N`, по умолчанию 10.
- Схема меняется только миграциями (`lib/src/data/migrations/`), которые применяет `Migrator` при старте. Ни `CREATE TABLE` в репозиториях, ни ручные правки в DBeaver: то, чего нет в миграции, не окажется на проде. Порядок добавления — [data-model.md → Миграции](data-model.md#миграции).
- `executeScript` — только для DDL с константным SQL; для данных всегда `execute`/`query` с параметрами.

## 4. Аутентификация

- Пароля нет: вход только через проверенный Telegram `initData` (HMAC токеном бота), затем access JWT в JSON и opaque refresh в HttpOnly cookie (`SameSite=Lax`, `Path=/auth`). Refresh в теле ответа не отдаётся. `initDataUnsafe` на сервере не используется.
- Тихое обновление — `POST /auth/refresh` (cookie); выход — `POST /auth/logout`. Защищённые роуты — `dart_frog_auth` `bearerAuthentication<AuthUser>` в `routes/api/_middleware.dart` (только Bearer, cookie на `/api/**` не смотрим). При невалидном токене middleware сам отвечает `401`; в хендлере пользователь доступен как `context.read<AuthUser>()`.
- Никогда не доверяйте `userId` из тела запроса — только из `AuthUser`.
- Проверку владения ресурсом (`owner_id == AuthUser.id`) делайте в сервисе и возвращайте `403`.

## 5. Ответы и ошибки

- JSON через `Response.json(...)`; успешные коды: `200`, `201` при создании, `204` при удалении.
- Единый формат ошибки `{ "error": "<сообщение>" }`; хелперы в `lib/src/http/responses.dart` (`badRequest`, `notImplemented`, …). Не отдавайте стек-трейсы и внутренние детали.
- Валидируйте тело явно: `request.json()` может бросить `FormatException` или вернуть не `Map`. Оборачивайте разбор и отвечайте `400`.
- Для не поддерживаемых методов — `405`, не `404`.

## 6. Конфигурация и секреты

- Все секреты через `AppConfig` из `.env` / переменных окружения; в коде нет литералов токенов. Приоритет: переменная окружения процесса перекрывает значение из `.env` — файл для локальной разработки, окружение для контейнеров и CI. `DEBUG_AUTH` — только локальный обход Telegram; в production должен оставаться `false`.
- `AppConfig.load()` вызывается в `main.dart` и падает на старте при отсутствии обязательных переменных — лучше упасть сразу, чем отдавать `500` под нагрузкой.
- `.env` в `.gitignore`, актуальный шаблон — `.example_env`. Новую переменную добавляйте в оба места и в [README.md](README.md).

## 7. OpenAPI

- Каждый эндпоинт помечен `@Route(...)` из `dart_frog_swagger`: `method`, `path`, `summary`, `description`, `tags`, `requestBody`, `responses`.
- Общие схемы (ошибка, JWT, пагинация) держите в `lib/src/openapi/*_docs.dart` и переиспользуйте, чтобы Swagger был согласован.
- Bearer и path-параметры для Swagger UI добавляются через `transformJson: applyOpenApiSpec` в `routes/_middleware.dart` (`@Route` не умеет `security` и `parameters`).
- После изменения аннотаций перегенерируйте спецификацию: `dart run dart_frog_swagger`. Файл `build/openapi.json` не коммитится.

## 8. Код-стайл

- Линтер `dart_frog_lint` (`analysis_options.yaml`), `dart analyze` без предупреждений перед коммитом.
- Именование файлов роутов — как в URL (`kebab-case` не нужен: пути в проекте односложные, `snake_case` не используем в путях).
- Хендлер — всегда `onRequest`; параметры пути приходят вторым аргументом: `onRequest(RequestContext context, String id)`.
- Не блокируйте изолят синхронной работой; всё I/O — `async`.

## 9. Развёртывание

- `dart_frog build` собирает `build/` с `Dockerfile`; локальный стек — `backend/docker-compose.yml` и `backend/Dockerfile` (контекст сборки — корень монорепо, без frontend). Запускать `dart build/bin/server.dart` или `docker compose up --build` из `backend/`.
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
