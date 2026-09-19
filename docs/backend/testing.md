# Тестирование backend

Инструменты: `package:test`, `mocktail`, `dart_frog_test`. Запуск — из `backend/`:

```powershell
dart test                                   # всё
dart test test/routes/auth                  # каталог
dart test -n "POST /auth/validate"          # по имени группы/теста
dart test --reporter expanded               # подробный вывод
```

## Структура `test/`

Зеркалит исходники:

```
test/
├── routes/                 # хендлеры: test/routes/<путь как в routes/>_test.dart
│   ├── auth/validate_test.dart
│   ├── auth/debug_test.dart
│   └── api/
│       ├── _middleware_test.dart
│       └── wishlists/index_test.dart
├── src/                    # unit-тесты lib/src/**
│   ├── auth/init_data_validator_test.dart
│   ├── auth/debug_auth_test.dart
│   ├── config/app_config_test.dart
│   └── data/               # database_config_test, database_test, migrator_test
├── integration/            # реальная PostgreSQL, тег integration, skip без TEST_DATABASE_URL
│   └── migrator_integration_test.dart
└── helpers/                # общие фабрики тестовых данных (не *_test.dart)
    ├── init_data.dart
    └── fake_pool.dart      # FakePool / FakeTxSession / makeResult для Database
```

Правило: новый роут — новый `*_test.dart` рядом в `test/routes/`; новый сервис — тест в `test/src/`.

## Что тестировать на каком уровне

1. **Сервисы в `lib/`** (основной объём): чистые unit-тесты без HTTP. Пример — `test/src/auth/init_data_validator_test.dart`: валидная подпись, битый hash, просроченный `auth_date`.
2. **Хендлеры в `routes/`**: коды ответов, формат тела, `405` на неверный метод, `400` на плохое тело. Зависимости подменяются через `context.read<T>()`.
3. **Middleware**: пропускает/отклоняет запрос и кладёт нужное в контекст.
4. **Работа с БД**: `Database` и `Migrator` тестируются без сервера — через `FakePool` из `test/helpers/fake_pool.dart`. Репозитории: подмените `DbExecutor` фейком, который записывает SQL и параметры и отдаёт заготовленные строки.
5. **Интеграционные с реальной PostgreSQL** (`test/integration/`): помечены `@Tags(['integration'])`, читают `TEST_DATABASE_URL`, без него — skip, поэтому `dart test` зелёный офлайн. Тест сам создаёт временную базу `melist_migrator_test_<ts>`, прогоняет миграции и удаляет её — dev-база не затрагивается. Запуск: `$env:TEST_DATABASE_URL='postgres://melist:melist@localhost:5433/melist?sslmode=disable'; dart test test/integration`. Обязателен после любой новой миграции.

## Хендлер с `mocktail`

Так написаны текущие тесты (`test/routes/auth/validate_test.dart`):

```dart
class _MockRequestContext extends Mock implements RequestContext {}

RequestContext contextWith(Request request) {
  final context = _MockRequestContext();
  when(() => context.request).thenReturn(request);
  when(() => context.read<InitDataValidator>()).thenReturn(validator);
  when(() => context.read<JwtService>()).thenReturn(jwtService);
  return context;
}

test('responds with 400 when initData is missing', () async {
  final context = contextWith(
    Request.post(
      Uri.parse('http://localhost/auth/validate'),
      headers: {HttpHeaders.contentTypeHeader: 'application/json'},
      body: jsonEncode({'initData': ''}),
    ),
  );

  final response = await route.onRequest(context);
  final body = jsonDecode(await response.body()) as Map<String, dynamic>;

  expect(response.statusCode, equals(HttpStatus.badRequest));
  expect(body['error'], equals('initData is required'));
});
```

Используйте настоящий `Request`, а не мок: тогда `request.json()`, заголовки и метод работают как в бою.

## Хендлер с `dart_frog_test`

[`dart_frog_test`](https://pub.dev/packages/dart_frog_test) убирает ручные стабы: `TestRequestContext` собирает контекст, `provide<T>` подменяет зависимости, матчеры делают ожидания читаемыми.

```dart
import 'package:dart_frog_test/dart_frog_test.dart';

test('returns 501 for authenticated user', () async {
  final context = TestRequestContext(path: '/api/wishlists')
    ..provide<AuthUser>(const AuthUser(id: 1));

  final response = await route.onRequest(context.context);

  expect(response, hasStatus(HttpStatus.notImplemented));
  await expectJsonBody(response, {'error': 'Not implemented'});
});

test('rejects unsupported methods', () async {
  await expectNotAllowedMethods(
    route.onRequest,
    contextBuilder: (method) => TestRequestContext(
      path: '/api/wishlists',
      method: method,
    ),
    allowedMethods: [HttpMethod.get, HttpMethod.post, HttpMethod.patch, HttpMethod.delete],
  );
});
```

Матчеры: `isOk`, `isCreated`, `isBadRequest`, `isUnauthorized`, `isForbidden`, `isNotFound`, `hasStatus(code)`, `expectBody`, `expectJsonBody`.

Оба подхода допустимы; для новых тестов предпочтителен `dart_frog_test`, `mocktail` остаётся для моков сервисов.

## Middleware

Middleware — функция `Handler middleware(Handler handler)`. Тестируется оборачиванием фиктивного хендлера:

```dart
test('rejects request without Bearer token', () async {
  final handler = middleware((_) => Response(body: 'ok'));
  final context = _MockRequestContext();
  when(() => context.request).thenReturn(Request.get(Uri.parse('http://localhost/api/me')));

  final response = await handler(context);

  expect(response.statusCode, equals(HttpStatus.unauthorized));
});
```

Известное ограничение ([dart_frog#1963](https://github.com/dart-frog-dev/dart_frog/issues/1963)): если middleware вызывает `context.provide(...)` (так делают `provider` и `bearerAuthentication`), мок `RequestContext` из `mocktail` должен вернуть новый контекст, иначе `Null is not a subtype of RequestContext`. Стабьте `provide`:

```dart
when(() => context.provide<AuthUser>(any())).thenReturn(context);
```

Либо проверяйте провайдеры интеграционно — через `dart_frog dev` и реальный запрос.

## База данных без сервера

`Database` принимает готовый `Pool`, поэтому в тестах подставляется `FakePool` из `test/helpers/fake_pool.dart`: он записывает каждый `execute` в `calls` (запрос, параметры, `ignoreRows`), отвечает через `onExecute`, а `runTx` вызывает колбэк с `FakeTxSession` (`pool.tx`) и выставляет `rolledBack` при исключении. `Result` собирается хелпером `makeResult`:

```dart
final pool = FakePool();
final db = Database(pool);

pool.onExecute = (query, params) => makeResult(
  rows: [[1, 'Birthday']],        // columns по умолчанию ['id', 'name']
);
final rows = await db.query('SELECT ...');

expect(pool.sqlTexts, contains('SELECT ...'));   // параметризованные запросы видны как '<Sql>'
```

Запросы без параметров приходят в фейк строкой, с параметрами — объектом `Sql` (драйвер не отдаёт его текст), поэтому проверяйте `calls[i].parameters`. Пример разветвления ответа по тексту запроса — `test/src/data/migrator_test.dart` (`schemaHas`).

Роут, использующий БД, тестируйте через `TestRequestContext(...).provide<Database>(Database(fakePool))` или, лучше, подменяйте репозиторий целиком — тогда SQL проверяется один раз в тесте репозитория, а роут — только на коды и формат ответа.

## Тестовые данные

- Подписанный `initData` собирается хелпером `signInitData(...)` из `test/helpers/init_data.dart` с фиксированным тестовым `BOT_TOKEN`; там же `hashOverride` для негативных кейсов.
- Время фиксируйте: сервисы принимают `clock` (`InitDataValidator(clock: () => now)`), чтобы тесты на `auth_date`/TTL были детерминированными.
- JWT для тестов выпускайте реальным `JwtService(secret: 'test-secret')` — это дёшево и проверяет совместимость `issue`/`verify`.

## Чек-лист перед коммитом

- `dart analyze` — без issues.
- `dart test` — зелёный.
- Для нового эндпоинта: тест на `405`, на успешный ответ, на `401` (если под `/api`), на `400` при невалидном теле.
- Если менялись `@Route` — `dart run dart_frog_swagger` и проверка `/docs`.
- Если добавлена миграция — `dart test test/integration` с `TEST_DATABASE_URL` и обновлённый `docs/backend/data-model.md`.
