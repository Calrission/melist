import 'package:melist_core/melist_core.dart';
import 'package:test/test.dart';

void main() {
  group('AuthValidateBody', () {
    test('round-trips initData', () {
      const body = AuthValidateBody(initData: 'user=%7B%22id%22%3A1%7D');
      expect(body.toJson(), {'initData': body.initData});
      expect(
        AuthValidateBody.fromJson(
          Map<String, dynamic>.from(body.toJson()),
        ).initData,
        body.initData,
      );
    });
  });

  group('PatchProfileBody', () {
    test('omits birthday unless set', () {
      const body = PatchProfileBody(theme: UiTheme.dark);
      expect(body.toJson(), {'theme': 'dark'});
    });

    test('sends null to clear birthday', () {
      const body = PatchProfileBody(birthday: null);
      expect(body.toJson(), {'birthday': null});
    });

    test('formats a date as YYYY-MM-DD', () {
      final body = PatchProfileBody(birthday: DateTime.utc(1990, 5, 12));
      expect(body.toJson(), {'birthday': '1990-05-12'});
    });
  });

  group('CreateWishBody', () {
    test('requires name and omits empty optionals', () {
      const body = CreateWishBody(name: 'Наушники', price: 12000);
      expect(body.toJson(), {'name': 'Наушники', 'price': 12000});
    });
  });

  group('PatchWishBody', () {
    test('omits unset fields and clears price', () {
      const named = PatchWishBody(name: 'Новое');
      expect(named.toJson(), {'name': 'Новое'});

      const cleared = PatchWishBody(price: null);
      expect(cleared.toJson(), {'price': null});
    });
  });

  group('CreateWishlistBody', () {
    test('serializes visibility and wishIds', () {
      const body = CreateWishlistBody(
        name: 'День рождения',
        visibility: WishlistVisibility.public,
        wishIds: [1, 2],
      );
      expect(body.toJson(), {
        'name': 'День рождения',
        'visibility': 'public',
        'wishIds': [1, 2],
      });
    });
  });

  group('AddWishlistWishBody', () {
    test('create / attach / copy are mutually exclusive', () {
      expect(
        const AddWishlistWishBody.create(
          CreateWishBody(name: 'Камера'),
        ).toJson(),
        {
          'wish': {'name': 'Камера'},
        },
      );
      expect(const AddWishlistWishBody.attach(10).toJson(), {'wishId': 10});
      expect(const AddWishlistWishBody.copy(42).toJson(), {
        'copyFromWishId': 42,
      });
    });

    test('fromJson rejects mixed variants', () {
      expect(
        () => AddWishlistWishBody.fromJson({'wishId': 1, 'copyFromWishId': 2}),
        throwsFormatException,
      );
    });
  });

  group('ReorderIdsBody', () {
    test('round-trips order', () {
      const body = ReorderIdsBody(order: [3, 1, 2]);
      expect(
        ReorderIdsBody.fromJson(Map<String, dynamic>.from(body.toJson())).order,
        [3, 1, 2],
      );
    });
  });

  group('subscription and favorite bodies', () {
    test('encode ids and shareToken', () {
      expect(const AddFavoriteBody(shareToken: 'abc').toJson(), {
        'shareToken': 'abc',
      });
      expect(const SubscribeWishlistBody(wishlistId: 1).toJson(), {
        'wishlistId': 1,
      });
      expect(const SubscribeUserBody(userId: 2).toJson(), {'userId': 2});
    });
  });
}
