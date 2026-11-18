# Сценарии использования

Продуктовые сценарии MELIST, пригодные как тест-кейсы. Нумерация функций в скобках — [README.md](README.md). Контракты — [backend/api.md](backend/api.md).

**Актёры.** **A** и **B** — разные пользователи с валидным `Authorization: Bearer` (после `POST /auth/validate`). Все запросы ниже, кроме явно указанных, идут под `/api/**` с токеном актёра из шага «Когда».

**Обозначения.** `WL` — вишлист, `W` — желание. Ожидание всегда включает HTTP-код и проверяемые поля тела (или их отсутствие).

## Вишлисты и желания внутри списка

### 1. Новые желания в новом вишлисте (1, 1.3, 12)

- **Дано:** A авторизован, вишлистов нет.
- **Когда:** `POST /api/wishes` `{ "name": "Наушники" }` → id `W1`; ещё раз `{ "name": "Книга" }` → `W2`. Затем `POST /api/wishlists` `{ "name": "День рождения", "visibility": "public", "wishIds": [W1, W2] }`.
- **Тогда:** оба `POST /api/wishes` — `201`, у желаний `ownerId = A`. `POST /api/wishlists` — `201`, `name = "День рождения"`, `visibility = public`. `GET /api/wishlists/{id}` от A — `200`, `items` содержит `W1` и `W2` в этом порядке.

### 2. Новые желания в существующий вишлист (4.1)

- **Дано:** у A есть `WL` с желанием `W1` в `items`.
- **Когда:** `POST /api/wishlists/{WL}/wishes` `{ "wish": { "name": "Камера" } }`, затем ещё раз `{ "wish": { "name": "Часы" } }`.
- **Тогда:** оба ответа `201`, новые id не равны `W1`. `GET /api/wishlists/{WL}` от A — в `items` три желания: `W1`, «Камера», «Часы» (новые в конце).

### 3. B читает желания в публичном вишлисте A (7, 25)

Карточка `GET /api/wishlists/{id}` — только для владельца (`403` у чужого). Чужие желания публичного списка читаются по ссылке и в `items` на профиле.

- **Дано:** у A публичный `WL` с желанием `{ "name": "Наушники" }`. A вызвал `POST /api/wishlists/{WL}/share` → `shareToken`.
- **Когда:** B делает `GET /api/users/{A}` и `GET /api/shared/{shareToken}`.
- **Тогда:** профиль — `200`, в `wishlists` есть `WL` (`visibility = public`). Shared — `200`, в `items` есть «Наушники». `GET /api/wishlists/{WL}` от B — `403`.

### 4. B не читает черновик A без ссылки (1.2)

- **Дано:** у A вишлист `WL` с `visibility = draft` и хотя бы одним желанием. Share-ссылки нет.
- **Когда:** B делает `GET /api/users/{A}`, `GET /api/wishlists/{WL}`, `POST /api/subscriptions/wishlists` `{ "wishlistId": WL }`.
- **Тогда:** профиль — `200`, `WL` нет в `wishlists`. Карточка — `403`. Подписка — `404` `{ "error": "Wishlist not found" }`.

### 5. Создание вишлиста: имя и видимость (1.1, 1.2)

- **Дано:** A авторизован.
- **Когда:**
  1. `POST /api/wishlists` `{ "name": "НГ", "visibility": "draft" }`
  2. `POST /api/wishlists` `{ "name": "НГ" }`
  3. `POST /api/wishlists` `{ "visibility": "draft" }`
- **Тогда:** (1) `201`, `visibility = draft`. (2) `201`, `visibility = draft`. (3) `400` `{ "error": "name is required" }`.

### 6. Список своих вишлистов и карточка (2.1, 2.2)

- **Дано:** у A два вишлиста `WL1`, `WL2`; в `WL1` одно желание.
- **Когда:** `GET /api/wishlists`, затем `GET /api/wishlists/{WL1}` (оба от A).
- **Тогда:** список — `200`, массив из двух элементов, порядок по `position`. У `WL1` в списке `items` с этим желанием, у `WL2` `items` пустой. Карточка `WL1` — `200`, те же `items`.

### 7. Редактирование вишлиста (3)

- **Дано:** у A вишлист `WL`: `name = "Старое"`, `visibility = draft`.
- **Когда:** `PATCH /api/wishlists/{WL}` `{ "name": "Новое", "visibility": "public" }` от A. `PATCH` с новым именем от B.
- **Тогда:** от A — `200`, имя и видимость обновлены. От B — `403`. Пустое тело — `400` `{ "error": "No fields to update" }`.

### 8. Привязка своего существующего желания (4.2)

- **Дано:** у A желание `W` (`GET /api/wishes` его содержит) и вишлист `WL` без `W` в `items`.
- **Когда:** `POST /api/wishlists/{WL}/wishes` `{ "wishId": W }`.
- **Тогда:** `201`, `id = W` (новая строка `wishes` не создаётся). `GET /api/wishlists/{WL}` — `W` в `items`. `GET /api/wishes` — по-прежнему одно желание с этим id.

### 9. Повторная привязка того же желания — конфликт

- **Дано:** `W` уже в `WL` у A.
- **Когда:** `POST /api/wishlists/{WL}/wishes` `{ "wishId": W }`.
- **Тогда:** `409` `{ "error": "Wish is already in the wishlist" }`. Число желаний в каталоге A не меняется.

### 10. Копия желания с чужого публичного вишлиста (4.3)

- **Дано:** у B публичный вишлист с желанием `W`. У A свой `WL`.
- **Когда:** A: `POST /api/wishlists/{WL}/wishes` `{ "copyFromWishId": W }`.
- **Тогда:** `201`, новый id ≠ `W`, `ownerId = A`, `copiedFrom = W`, `name` как у исходного. `GET /api/wishes/{W}` от B — исходное без изменений.

### 11. Нельзя скопировать чужое желание вне публичного вишлиста (4.3)

- **Дано:** у B желание `W` только в каталоге или в черновике, не в публичном вишлисте.
- **Когда:** A: `POST /api/wishlists/{свой}/wishes` `{ "copyFromWishId": W }`.
- **Тогда:** `403`. У A новое желание не появляется (`GET /api/wishes` без копии).

### 12. Сортировка вишлистов (5.1)

- **Дано:** у A ровно три вишлиста с id `1, 2, 3` в текущем порядке списка.
- **Когда:** `PATCH /api/wishlists` `{ "order": [3, 1, 2] }`. Затем `GET /api/wishlists`.
- **Тогда:** PATCH — `204`. GET — id в порядке `[3, 1, 2]`. Неполный или чужой id в `order` — `400`.

### 13. Сортировка желаний внутри вишлиста (5.2)

- **Дано:** у A в `WL` желания `[W1, W2, W3]` в `items`.
- **Когда:** `PATCH /api/wishlists/{WL}/wishes` `{ "order": [W3, W1, W2] }`. Затем карточка `WL`.
- **Тогда:** PATCH — `204`. `items` — `[W3, W1, W2]`. Неполная перестановка — `400`.

### 14. Убрать желание из вишлиста, каталог целый

- **Дано:** у A желание `W` в `WL` и в `GET /api/wishes`.
- **Когда:** `DELETE /api/wishlists/{WL}/wishes/{W}`.
- **Тогда:** `204`. Карточка `WL` — `W` нет в `items`. `GET /api/wishes/{W}` от A — `200`. Повторный DELETE — `404` `{ "error": "Wish is not in the wishlist" }`.

### 15. Удаление одного вишлиста (6.1)

- **Дано:** у A вишлист `WL` и желание `W` только в этом списке (или ещё в каталоге).
- **Когда:** `DELETE /api/wishlists/{WL}` от A. Затем `GET /api/wishlists/{WL}` от A. Отдельно B: `DELETE /api/wishlists/{WL}` пока список ещё существует.
- **Тогда:** DELETE от A — `204`. Повторный GET от A — `404`. DELETE от B по чужому существующему id — `403`. Желание `W` остаётся в `GET /api/wishes`, если существовало как сущность каталога.

### 16. Массовое удаление вишлистов (6.2)

- **Дано:** у A вишлисты `WL1`, `WL2`, `WL3`.
- **Когда:** `DELETE /api/wishlists` `{ "ids": [WL1, WL2] }`. Затем `GET /api/wishlists`.
- **Тогда:** `204`. В списке остался только `WL3`. Пустой `ids` — `400`. Id, которого нет у A, — `404` `{ "error": "Some wishlists were not found" }`.

## Шеринг

### 17. Ссылка на свой вишлист (7.1)

- **Дано:** у A вишлист `WL` (public, draft или link), `shareToken` ещё `null`.
- **Когда:** `POST /api/wishlists/{WL}/share` дважды.
- **Тогда:** оба раза `200`, одинаковый `shareToken` (не пустой), `url` вида `https://t.me/<bot>?startapp=wl_<token>`. От B на чужой `WL` без владения — `403`.

### 18. Поделиться в Telegram (7.2)

- **Дано:** A получил `url` из сценария 17.
- **Когда:** клиент открывает системный share Telegram (не API).
- **Тогда:** сервер не вызывается. Автотест API не пишется; достаточно, что `url` из 17 не пустой.

### 19. B открывает вишлист A по токену (7)

- **Дано:** у A `WL` с `visibility = link`. A получил `shareToken`.
- **Когда:** B: `GET /api/shared/{shareToken}` и `GET /api/shared/wl_{shareToken}`.
- **Тогда:** оба — `200`, `id = WL`. Неизвестный токен — `404` `{ "error": "Wishlist not found" }`. Тот же `GET` для чужого `draft` с токеном — `404`.

### 20. По ссылке видны все желания списка (7)

- **Дано:** в `WL` у A (`public` или `link`) два желания: `W1` и `W2`. Есть `shareToken`.
- **Когда:** B: `GET /api/shared/{shareToken}`. A: тот же запрос.
- **Тогда:** у B и у A в `items` оба желания.

## Избранное

### 21. B добавляет вишлист A по токену (8.1)

- **Дано:** у A вишлист со `shareToken` (после `/share`).
- **Когда:** B: `POST /api/favorites` `{ "shareToken": "<token>" }` или `{ "shareToken": "wl_<token>" }`.
- **Тогда:** `201`, тело — вишлист A, `id = WL`.

### 22. Список избранного (9.1)

- **Дано:** B добавил вишлисты A: сначала `WL1`, затем `WL2`.
- **Когда:** B: `GET /api/favorites`.
- **Тогда:** `200`, массив из двух элементов, порядок добавления (`WL1`, `WL2`), если не было reorder. У каждого элемента `ownerNickname` — ник владельца, а если он не задан, имя и фамилия.

### 23. В избранном видны все желания (9)

- **Дано:** как в 20, B добавил `WL` в избранное.
- **Когда:** B: `GET /api/favorites`.
- **Тогда:** у элемента `WL` в `items` есть `W1` и `W2`.

### 24. Сортировка избранного (10.1)

- **Дано:** у B в избранном ровно `[WL1, WL2]`.
- **Когда:** `PATCH /api/favorites` `{ "order": [WL2, WL1] }`. Затем GET.
- **Тогда:** PATCH — `204`. GET — `[WL2, WL1]`. Неполный `order` — `400`.

### 25. Удаление из избранного не удаляет вишлист (11.1)

- **Дано:** `WL` A в избранном у B.
- **Когда:** B: `DELETE /api/favorites/{WL}`. A: `GET /api/wishlists/{WL}`. B: `GET /api/favorites`.
- **Тогда:** DELETE — `204`. У A карточка `WL` — `200`. У B избранное пустое (или без `WL`). Повторный DELETE — `404` `{ "error": "Wishlist is not in favorites" }`.

### 26. Нельзя добавить свой вишлист в избранное (8.1)

- **Дано:** у A свой `WL` и его `shareToken`.
- **Когда:** A: `POST /api/favorites` `{ "shareToken": "<token>" }`.
- **Тогда:** `400` `{ "error": "Cannot favorite your own wishlist" }`.

### 27. Повтор в избранное — конфликт (8.1)

- **Дано:** `WL` A уже в избранном у B.
- **Когда:** B: `POST /api/favorites` с тем же токеном.
- **Тогда:** `409` `{ "error": "Wishlist is already in favorites" }`.

## Каталог желаний

### 28. Создание желания (12)

- **Дано:** A авторизован.
- **Когда:** `POST /api/wishes` `{ "name": "Наушники", "price": 12000, "url": "https://example.com", "description": "чёрные", "coverUrl": "https://example.com/c.png" }`. Отдельно `{ }`.
- **Тогда:** полный — `201`, поля совпадают, без явного enum: `status = free`. Без `name` — `400` `{ "error": "name is required" }`.

### 29. Список своих желаний, новые сверху (16.1)

- **Дано:** A создал сначала `W1`, затем `W2`.
- **Когда:** `GET /api/wishes`.
- **Тогда:** `200`, первый элемент `W2`, второй `W1`. Чужие желания B в массиве отсутствуют.

### 30. Поиск по названию (17.1)

- **Дано:** у A желания «Наушники» и «Книга».
- **Когда:** `GET /api/wishes?query=науш` и `GET /api/wishes?query=стол`.
- **Тогда:** первый — массив из «Наушники» (регистр не важен). Второй — `[]`. `mine=false` — `400` `{ "error": "mine must be true" }`.

### 31. Чтение, правка и удаление своего желания (18, 21.1)

- **Дано:** у A желание `W` с `name = "Старое"`.
- **Когда:** `GET /api/wishes/{W}`; `PATCH /api/wishes/{W}` `{ "name": "Новое" }`; `DELETE /api/wishes/{W}`; снова GET.
- **Тогда:** GET — `200`. PATCH — `200`, `name = "Новое"`. DELETE — `204`. Повторный GET — `404`. Те же GET/PATCH/DELETE от B — `403` (если `W` существует).

### 32. (удалён)

Видимость желания не поддерживается. Видимость есть только у вишлиста: `public` / `draft` / `link`.

### 33. Статус желания (20)

- **Дано:** у A желание `W`.
- **Когда:** `PATCH` со `"status": "draft" | "free" | "reserved"`, затем `"status": "done"`.
- **Тогда:** валидные — `200`. `done` — `400`.

### 34. Дублирование своего желания (13.1)

- **Дано:** у A желание `W` с `name = "Наушники"`.
- **Когда:** `POST /api/wishes/{W}/duplicate`. `POST /api/wishes/{W}/duplicate` от B.
- **Тогда:** от A — `201`, новый id, `copiedFrom = W`, `name = "Наушники"`. Исходный `GET /api/wishes/{W}` без изменений. От B — `403`.

### 35. Массовое удаление желаний (21.2)

- **Дано:** у A желания `W1`, `W2`, `W3`.
- **Когда:** `DELETE /api/wishes` `{ "ids": [W1, W2] }`. Затем `GET /api/wishes`.
- **Тогда:** `204`. В списке только `W3`. Пустой `ids` — `400`. Чужой id — `404`.

### 36. B не работает с каталогом A

- **Дано:** желание `W` принадлежит A, не обязательно в вишлисте.
- **Когда:** B: `GET /api/wishes/{W}`, `PATCH /api/wishes/{W}` `{ "name": "X" }`, `DELETE /api/wishes/{W}`, `GET /api/wishes` (список B).
- **Тогда:** GET/PATCH/DELETE чужого — `403` или `404` (нет утечки тела A). Список B не содержит `W`.

## Профиль

### 37. Профиль после входа (22)

- **Дано:** валидный Telegram `initData` пользователя A (`first_name`, `photo_url`).
- **Когда:** `POST /auth/validate` `{ "initData" }`. Затем `GET /api/me` с выданным JWT.
- **Тогда:** validate — `200`, `user.firstName` и `user.avatarUrl` из initData, `Set-Cookie` с `refresh_token` (не в JSON). `GET /api/me` — `200`, те же `id`, `firstName`, `avatarUrl`, `theme = system`, пока не меняли. Без Bearer на `/api/me` — `401`.

### 37b. Тихое обновление access (refresh cookie)

- **Дано:** A прошёл `POST /auth/validate`, cookie `refresh_token` установлена.
- **Когда:** `POST /auth/refresh` с этой cookie; затем повторно тем же cookie; затем без cookie.
- **Тогда:** первый refresh — `200` с новым `accessToken` и новым `Set-Cookie`. Повтор старого cookie — `401`. Без cookie — `401`.

### 38. Дата рождения (23)

- **Дано:** A авторизован.
- **Когда:** `PATCH /api/me` `{ "birthday": "1990-05-12" }`; затем `{ "birthday": "1991-01-01" }`; затем `{ "birthday": null }`; затем `{ "birthday": "12-05-1990" }`.
- **Тогда:** первые два — `200`, `birthday` равно отправленной дате (`YYYY-MM-DD`). `null` — `200`, `birthday = null`. Неверный формат — `400`.

### 38b. Никнейм (23.3)

- **Дано:** A авторизован, в Telegram `first_name = Ann`, `last_name = Lee`, свой ник не задан.
- **Когда:** `GET /api/me`. Затем `PATCH /api/me` `{ "nickname": "Annie" }`. Затем `{ "nickname": null }`.
- **Тогда:** GET — `200`, `nickname = "Ann Lee"`. После PATCH — `nickname = "Annie"`, `firstName` и `lastName` не меняются. `null` и `""` — снова `"Ann Lee"`. Не строка — `400`.

### 39. Тема оформления (26)

- **Дано:** A авторизован, `theme = system`.
- **Когда:** `PATCH /api/me` `{ "theme": "dark" }`, `{ "theme": "light" }`, `{ "theme": "system" }`, `{ "theme": "neon" }`.
- **Тогда:** `dark`/`light`/`system` — `200`, поле совпадает. `neon` — `400` `{ "error": "theme must be system, light or dark" }`. Пустой PATCH `{}` — `400` `{ "error": "No fields to update" }`.

### 40. Чужой профиль: только публичные вишлисты (25.1)

- **Дано:** у A публичный `WL_pub` и черновик `WL_draft`. Строка `users` для A существует (вход или создание вишлиста).
- **Когда:** B: `GET /api/users/{A}`.
- **Тогда:** `200`, `user.id = A`. В `wishlists` есть `WL_pub`, нет `WL_draft`. Несуществующий id — `404` `{ "error": "User not found" }`. Невалидный id (`abc`) — `400`.

### 41. Черновики A скрыты на профиле (25.1)

Тот же оракул, что 40: после смены `WL_pub` на `draft` (`PATCH /api/wishlists/{id}` `{ "visibility": "draft" }`) повторный `GET /api/users/{A}` от B не содержит этот id.

## Подписки

### 42. Подписка на публичный вишлист (30, 31)

- **Дано:** у A публичный `WL`.
- **Когда:** B: `POST /api/subscriptions/wishlists` `{ "wishlistId": WL }`. Затем `GET /api/subscriptions/wishlists`.
- **Тогда:** POST — `201`, тело вишлиста `id = WL`. GET — `200`, массив начинается с `WL` (новые сверху). Без `wishlistId` — `400`.

### 43. Нельзя подписаться на черновик (30)

- **Дано:** у A `WL` с `visibility = draft`.
- **Когда:** B: `POST /api/subscriptions/wishlists` `{ "wishlistId": WL }`.
- **Тогда:** `404` `{ "error": "Wishlist not found" }`. GET подписок B не содержит `WL`.

### 44. Отписка от вишлиста (32)

- **Дано:** B подписан на публичный `WL` A.
- **Когда:** `DELETE /api/subscriptions/wishlists/{WL}`. Затем GET. Повторный DELETE.
- **Тогда:** первый DELETE — `204`. GET — без `WL`. Второй — `404` `{ "error": "Wishlist subscription not found" }`.

### 45. Подписка на профиль (33, 34)

- **Дано:** пользователь A есть в `users` (например, создал вишлист или вызывал `/api/me`).
- **Когда:** B: `POST /api/subscriptions/users` `{ "userId": A }`. Затем `GET /api/subscriptions/users`.
- **Тогда:** POST — `201`, `id = A`. GET — `200`, первый элемент — A (новые сверху). Нет `userId` — `400`. Нет пользователя — `404` `{ "error": "User not found" }`.

### 46. Отписка от профиля (35)

- **Дано:** B подписан на A.
- **Когда:** `DELETE /api/subscriptions/users/{A}`. Повторный DELETE.
- **Тогда:** `204`, затем GET без A. Повтор — `404` `{ "error": "User subscription not found" }`.

### 47. Нельзя подписаться на своё (30, 33)

- **Дано:** у A публичный `WL`.
- **Когда:** A: `POST /api/subscriptions/wishlists` `{ "wishlistId": WL }` и `POST /api/subscriptions/users` `{ "userId": A }`.
- **Тогда:** вишлист — `400` `{ "error": "Cannot subscribe to your own wishlist" }`. Профиль — `400` `{ "error": "Cannot subscribe to yourself" }`.

### 48. Повторная подписка — конфликт

- **Дано:** B уже подписан на публичный `WL` A и на профиль A.
- **Когда:** B повторяет оба POST из 42 и 45.
- **Тогда:** вишлист — `409` `{ "error": "Already subscribed to this wishlist" }`. Профиль — `409` `{ "error": "Already subscribed to this user" }`.

### 49. Подписка на вишлист пропадает из списка, если список стал черновиком (31)

- **Дано:** B подписан на публичный `WL` A.
- **Когда:** A: `PATCH /api/wishlists/{WL}` `{ "visibility": "draft" }`. B: `GET /api/subscriptions/wishlists`.
- **Тогда:** GET — `200`, `WL` в массиве нет. DELETE подписки всё ещё может вернуть `204`, если строка подписки не удалялась (или `404`, если решите чистить каскадом — текущее поведение: строка остаётся, GET фильтрует `public`, DELETE находит строку и возвращает `204`).

## Монетизация

Сценарии функций 27–29 в API не реализованы (`501`). Тесты на успешный путь не пишутся, пока нет контракта в roadmap.
