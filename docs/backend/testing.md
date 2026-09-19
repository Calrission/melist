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
│   └── api/
│       ├── _middleware_test.dart
│       └── wishlists/index_test.dart
├── src/                    # unit-тесты lib/src/**
│   └── auth/init_data_validator_test.dart
└── helpers/                # общие фабрики тестовых данных (не *_test.dart)
    └── init_data.dart
```

Правило: новый роут — новый `*_test.dart` рядом в `test/routes/`; новый сервис — тест в `test/src/`.

## Что тестировать на каком уровне

1. **Сервисы в `lib/`** (основной объём): чистые unit-тесты без HTTP. Пример — `test/src/auth/init_data_validator_test.dart`: валидная подпись, битый hash, просроченный `auth_date`.
2. **Хендлеры в `routes/`**: коды ответов, формат тела, `405` на неверный метод, `400` на плохое тело. Зависимости подменяются через `context.read<T>()`.
3. **Middleware**: пропускает/отклоняет запрос и кладёт нужное в контекст.
4. Интеграционные тесты с реальной PostgreSQL — после подключения БД: отдельная тестовая база, `setUp`/`tearDown` очищают данные.

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

## Тестовые данные

- Подписанный `initData` собирается хелпером `signInitData(...)` из `test/helpers/init_data.dart` с фиксированным тестовым `BOT_TOKEN`; там же `hashOverride` для негативных кейсов.
- Время фиксируйте: сервисы принимают `clock` (`InitDataValidator(clock: () => now)`), чтобы тесты на `auth_date`/TTL были детерминированными.
- JWT для тестов выпускайте реальным `JwtService(secret: 'test-secret')` — это дёшево и проверяет совместимость `issue`/`verify`.

## Чек-лист перед коммитом

- `dart analyze` — без issues.
- `dart test` — зелёный.
- Для нового эндпоинта: тест на `405`, на успешный ответ, на `401` (если под `/api`), на `400` при невалидном теле.
- Если менялись `@Route` — `dart run dart_frog_swagger` и проверка `/docs`.
