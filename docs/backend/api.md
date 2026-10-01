# API

Базовый URL в dev: `http://localhost:8080`. Все тела запросов и ответов — JSON. Актуальная спецификация генерируется из аннотаций `@Route` в `backend/routes/**` и доступна на `/docs` (Swagger UI) и `/openapi.json`.

Номера в скобках — пункты функционала из [docs/README.md](../README.md).

## Общие правила

- Публичные роуты: `/`, `/health`, `/auth/*`, `/docs`, `/openapi.json`. Если рядом есть сборка Flutter Web (`frontend/build/web/index.html` или `frontend/.build/web/index.html`), `GET /` отдаёт Mini App, а не JSON; остальные пути из этого списка по-прежнему API.
- Всё под `/api/**` требует `Authorization: Bearer <accessToken>`. Проверку делает `backend/routes/api/_middleware.dart`; в контекст кладётся `AuthUser` (`context.read<AuthUser>()`). При `DEBUG_AUTH=true` принимается и фиксированная строка из `DEBUG_TOKEN` (не JWT). В Swagger UI: **Authorize** → вставить токен без префикса `Bearer`.
- Ошибки всегда в формате `{ "error": "<сообщение>" }`.
- Тела `POST`/`PATCH` на клиенте — модели в `melist_core` (`CreateWishlistBody`, `PatchWishBody`, …). PATCH: нет ключа — поле не менять; `null` — сбросить (`jsonOmit` в конструкторе).
- Коды: `200` ok, `201` создано, `204` удалено без тела, `400` невалидное тело, `401` нет/плохой токен, `403` чужой ресурс, `404` не найдено, `405` метод не поддерживается, `501` ещё не реализовано.
- Массовые операции и сортировка выполняются методами на коллекции (`PATCH`/`DELETE /api/wishlists`), а не отдельными статическими путями рядом с `[id]` — в Dart Frog динамический сегмент может перехватить такой путь.

## Аутентификация

Access JWT — короткоживущий, только в JSON (`AuthSessionModel`). Refresh — opaque-токен в HttpOnly cookie `refresh_token` (`Secure` по флагу `COOKIE_SECURE`, `SameSite=Lax`, `Path=/auth`). В JSON refresh **нет**. `/api/**` по-прежнему только `Authorization: Bearer`.

```mermaid
sequenceDiagram
  participant App as MiniApp
  participant Api as Backend
  App->>Api: POST /auth/validate { initData }
  Api->>Api: HMAC-SHA256(initData, BOT_TOKEN), auth_date <= 24h
  Api-->>App: JSON accessToken plus Set-Cookie HttpOnly refresh
  App->>Api: GET /api/me  Authorization: Bearer accessToken
  Note over App: F5 clears in-memory access
  App->>Api: POST /auth/refresh Cookie refresh_token
  Api-->>App: new accessToken plus rotated Set-Cookie
```

### `POST /auth/validate`

Тело: `{ "initData": "<raw WebApp.initData>" }`.

Ответ `200`:

```json
{
  "accessToken": "<jwt>",
  "tokenType": "Bearer",
  "expiresIn": 900,
  "user": { "id": 123, "firstName": "…", "lastName": "…", "username": "…", "avatarUrl": "…" }
}
```

Заголовок `Set-Cookie`: `refresh_token=…; Path=/auth; HttpOnly; SameSite=Lax` (`Secure` если `COOKIE_SECURE=true`). Клиент: `AuthSessionModel` в `melist_core` (`fromJson` тела ответа) — поле refresh в модели нет.

`400` — `initData` отсутствует; `401` — `Invalid initData` / `Expired initData`.

JWT: `sub` = Telegram user id, claims `firstName`, `lastName`, `username`. TTL access по умолчанию 15 минут (`ACCESS_TOKEN_TTL_SECONDS`). Когда access истечёт — `POST /auth/refresh` с cookie, без повторного `initData`.

### `POST /auth/refresh`

Тела нет. Браузер присылает cookie `refresh_token`. Сервер проверяет хеш в `refresh_tokens`, ротирует токен и отвечает тем же JSON, что validate, плюс новый `Set-Cookie`.

`401` `{ "error": "Invalid refresh token" }` — нет cookie, просрочен, неизвестен или уже отозван. Повтор отозванного токена отзывает все refresh этого пользователя и тоже даёт `401` с `Set-Cookie` `Max-Age=0`.

### `POST /auth/logout`

Отзывает текущий refresh (если cookie есть) и всегда отвечает `204` с очисткой cookie (`Max-Age=0`), даже без cookie.

### `GET /auth/debug`

Только при `DEBUG_AUTH=true`. Возвращает фиксированный Bearer, чтобы в Swagger и curl не проходить Telegram `initData`.

Ответ `200`:

```json
{
  "accessToken": "dev-admin",
  "tokenType": "Bearer",
  "user": { "id": 1, "firstName": "Debug", "lastName": "Admin", "username": "debug_admin" }
}
```

Дальше: `Authorization: Bearer dev-admin` на `/api/**`. Пользователь с `DEBUG_USER_ID` создаётся на старте сервера. `404` — флаг выключен. На проде не включать.

## Профиль

### `GET /api/me` (22)

Текущий пользователь: данные из Telegram + настройки. Если строки в `users` ещё нет, она создаётся из JWT.

```json
{ "id": 1, "firstName": "…", "lastName": "…", "username": "…", "avatarUrl": "…",
  "birthday": "1990-05-12", "theme": "dark" }
```

### `PATCH /api/me` (23, 26)

Тело: `{ "birthday"?: "YYYY-MM-DD" | null, "theme"?: "light" | "dark" | "system" }`. `null` у `birthday` сбрасывает дату. Ответ — как `GET /api/me`.

### `GET /api/me/entitlements` (29)

Доступ к дополнительным функциям: `{ "premiumUntil": "<iso>" | null, "sources": ["ad", "donation"] }`.

### `GET /api/users/{id}` (25)

Публичный профиль пользователя и его вишлисты с `visibility = public`. `404`, если пользователя нет.

## Вишлисты

Файлы: `backend/routes/api/wishlists/`.

### `GET /api/wishlists` (2.1)

Свои вишлисты, отсортированные по `position`. В каждом списке `items` — желания по `position`, как в карточке.

### `POST /api/wishlists` (1)

```json
{ "name": "День рождения", "visibility": "public" | "draft" | "link", "color": "#FFB74D", "wishIds": [1, 2] }
```

`wishIds` — опционально (1.3). Ответ `201` с созданным вишлистом.

### `PATCH /api/wishlists` (5.1)

Сортировка: `{ "order": [3, 1, 2] }` — полный список id в новом порядке. `204`.

### `DELETE /api/wishlists` (6.2)

Массовое удаление: `{ "ids": [1, 2] }`. `204`.

### `GET /api/wishlists/{id}` (2.2)

Карточка вишлиста с желаниями (`items` по `position`).

### `PATCH /api/wishlists/{id}` (3)

`{ "name"?, "visibility"?: "public" | "draft" | "link", "color"? }`.

### `DELETE /api/wishlists/{id}` (6.1)

`204`.

### `POST /api/wishlists/{id}/wishes` (4)

Одно из трёх тел:

- `{ "wish": { "name", "price"?, "url"?, "description"?, "coverUrl"? } }` — новое желание (4.1)
- `{ "wishId": 10 }` — своё существующее (4.2)
- `{ "copyFromWishId": 42 }` — копия с чужого вишлиста (4.3)

Ответ `201` — добавленное желание. Повторная привязка того же `wishId` — `409`.

### `PATCH /api/wishlists/{id}/wishes` (5.2)

Сортировка желаний внутри вишлиста: `{ "order": [wishId, …] }`. `204`.

### `DELETE /api/wishlists/{id}/wishes/{wishId}`

Убрать желание из вишлиста (само желание не удаляется). `204`.

### `POST /api/wishlists/{id}/share` (7.1)

Создать или вернуть ссылку доступа: `{ "shareToken": "…", "url": "https://t.me/<bot>/app?startapp=wl_<token>" }`.

Пункт 7.2 («поделиться») — на клиенте через Telegram share.

### `GET /api/shared/{token}` (7, 8.1)

Просмотр вишлиста по ссылке-приглашению для `public` и `link`. `draft` для не-владельца — `404`. Токен — значение `shareToken` или `wl_<shareToken>` из `startapp`. В `items` все желания списка.

## Избранное

Файлы: `backend/routes/api/favorites/`.

- `GET /api/favorites` (9) — чужие вишлисты в избранном, по `position`. В `items` все желания.
- `POST /api/favorites` (8.1) — `{ "shareToken": "…" }` → `201`. Свой вишлист — `400`, повтор — `409`.
- `PATCH /api/favorites` (10) — `{ "order": [wishlistId, …] }` → `204`
- `DELETE /api/favorites/{wishlistId}` (11) → `204`

## Желания

Файлы: `backend/routes/api/wishes/`.

### `GET /api/wishes` (16, 17)

Свои желания, новые сверху. Query: `query` — поиск по названию (17.1, `ILIKE`); `mine=true` — только свои (17.2, значение по умолчанию; иное — `400`). Пагинация: `limit` (по умолчанию 50, максимум 100), `offset`. Ответ — массив.

### `POST /api/wishes` (12)

```json
{ "name": "Наушники", "price": 12000, "url": "https://…", "description": "…", "coverUrl": "https://…",
  "status": "draft" | "free" | "reserved" }
```

Обязательно только `name`. `201`.

### `DELETE /api/wishes` (21.2)

`{ "ids": [1, 2] }` → `204`.

### `GET /api/wishes/{id}`

Одно желание.

### `PATCH /api/wishes/{id}` (18, 20)

Любые поля из `POST`, включая `status` (20).

### `DELETE /api/wishes/{id}` (21.1)

`204`.

### `POST /api/wishes/{id}/duplicate` (13)

Копия своего желания. `201`.

## Подписки

Файлы: `backend/routes/api/subscriptions/`. Свой вишлист или свой профиль — `400`. Чужой черновик вишлиста — `404`. Повтор — `409`. Список — новые сверху; в списке вишлистов только `public`.

- `GET /api/subscriptions/wishlists` (31) — публичные вишлисты, на которые подписан пользователь.
- `POST /api/subscriptions/wishlists` (30) — `{ "wishlistId": 1 }` → `201` с вишлистом.
- `DELETE /api/subscriptions/wishlists/{wishlistId}` (32) → `204`
- `GET /api/subscriptions/users` (34) — профили, на которые подписан пользователь.
- `POST /api/subscriptions/users` (33) — `{ "userId": 1 }` → `201` с пользователем.
- `DELETE /api/subscriptions/users/{userId}` (35) → `204`

## Монетизация

- `POST /api/ads/reward` (29.1) — подтверждение просмотра рекламы: `{ "provider": "adsgram", "payload": "…" }` → обновлённые entitlements. Показ рекламы (27.1) — SDK на клиенте.
- `POST /api/donations` (28, 29.2) — создать инвойс Telegram Stars: `{ "amount": 100 }` → `{ "invoiceLink": "…" }`.

## Соответствие функционал → эндпоинт

- 1 → `POST /api/wishlists`
- 2 → `GET /api/wishlists`, `GET /api/wishlists/{id}`
- 3 → `PATCH /api/wishlists/{id}`
- 4 → `POST /api/wishlists/{id}/wishes`
- 5 → `PATCH /api/wishlists`, `PATCH /api/wishlists/{id}/wishes`
- 6 → `DELETE /api/wishlists/{id}`, `DELETE /api/wishlists`
- 7 → `POST /api/wishlists/{id}/share`, `GET /api/shared/{token}`
- 8–11 → `/api/favorites`
- 12, 16–21 → `/api/wishes`
- 13 → `POST /api/wishes/{id}/duplicate`
- 22, 23, 26 → `/api/me`
- 25 → `GET /api/users/{id}`
- 27–29 → `POST /api/ads/reward`, `POST /api/donations`, `GET /api/me/entitlements`
- 30–35 → `/api/subscriptions/*`

## Статус реализации

Работают: `/`, `/health`, `/auth/validate`, `POST /auth/refresh`, `POST /auth/logout`, `GET /auth/debug`, CRUD вишлистов (`GET`/`POST`/`PATCH`/`DELETE /api/wishlists`, `GET`/`PATCH`/`DELETE /api/wishlists/{id}`), CRUD желаний (`GET`/`POST`/`DELETE /api/wishes`, `GET`/`PATCH`/`DELETE /api/wishes/{id}`, `POST /api/wishes/{id}/duplicate`), желания внутри вишлиста (`POST`/`PATCH /api/wishlists/{id}/wishes`, `DELETE /api/wishlists/{id}/wishes/{wishId}`), шеринг (`POST /api/wishlists/{id}/share`, `GET /api/shared/{token}`), избранное (`GET`/`POST`/`PATCH /api/favorites`, `DELETE /api/favorites/{wishlistId}`), профиль (`GET`/`PATCH /api/me`, `GET /api/users/{id}`), подписки (`GET`/`POST /api/subscriptions/wishlists`, `DELETE /api/subscriptions/wishlists/{wishlistId}`, `GET`/`POST /api/subscriptions/users`, `DELETE /api/subscriptions/users/{userId}`). Остальные `/api/**` — заглушки: проверяют метод и Bearer JWT, отвечают `501 { "error": "Not implemented" }`. Очередь работ — [roadmap.md](roadmap.md) (монетизация 27–29 там не планируется).
