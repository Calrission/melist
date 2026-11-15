import 'package:melist_backend/melist_backend.dart';
import 'package:test/test.dart';

import '../../helpers/memory_wishlists.dart';

void main() {
  const owner = AuthUser(id: 7, username: 'ann');
  const guest = AuthUser(id: 8, username: 'bob');

  late MemoryWishlistData data;
  late WishlistService wishlists;
  late FavoriteService favorites;

  setUp(() {
    data = MemoryWishlistData();
    wishlists = memoryWishlistService(data);
    favorites = memoryFavoriteService(data);
  });

  Future<String> shareList(String name, {AuthUser as = owner}) async {
    final list = await wishlists.create(
      as,
      name: name,
      visibility: 'link',
    );
    return wishlists.share(as, list.id);
  }

  group('FavoriteService.add and list', () {
    test('adds a shared wishlist with every wish', () async {
      final list = await wishlists.create(
        owner,
        name: 'Birthday',
        visibility: 'link',
      );
      await wishlists.addWish(
        owner,
        list.id,
        wish: {'name': 'Camera'},
      );
      await wishlists.addWish(
        owner,
        list.id,
        wish: {'name': 'Secret'},
      );
      final token = await wishlists.share(owner, list.id);

      final added = await favorites.add(guest, 'wl_$token');

      expect(added.id, list.id);
      expect(added.name, 'Birthday');
      expect(added.items.map((item) => item.name), ['Camera', 'Secret']);
      expect(data.userIds, contains(8));

      final listed = await favorites.list(guest);
      expect(listed.single.id, list.id);
      expect(listed.single.ownerNickname, '');
      expect(
        listed.single.items.map((item) => item.name),
        ['Camera', 'Secret'],
      );
    });

    test('includes the owner nickname, or the name when unset', () async {
      const named = AuthUser(
        id: 7,
        firstName: 'Ann',
        lastName: 'Lee',
        username: 'ann',
      );
      final token = await shareList('Birthday', as: named);
      await favorites.add(guest, token);

      expect((await favorites.list(guest)).single.ownerNickname, 'Ann Lee');

      await memoryProfileService(data).update(named, nickname: 'Annie');

      expect((await favorites.list(guest)).single.ownerNickname, 'Annie');
    });

    test('rejects own wishlists, unknown tokens and duplicates', () async {
      final token = await shareList('Mine');

      await expectLater(
        favorites.add(owner, token),
        throwsA(isA<BadRequestException>()),
      );
      await expectLater(
        favorites.add(guest, ''),
        throwsA(isA<BadRequestException>()),
      );
      await expectLater(
        favorites.add(guest, 'missing'),
        throwsA(isA<NotFoundException>()),
      );

      await favorites.add(guest, token);
      await expectLater(
        favorites.add(guest, token),
        throwsA(isA<ConflictException>()),
      );
    });
  });

  group('FavoriteService.reorder', () {
    test('reorders favorites by a full permutation', () async {
      final firstToken = await shareList('A');
      final secondToken = await shareList('B');
      final first = await favorites.add(guest, firstToken);
      final second = await favorites.add(guest, secondToken);

      await favorites.reorder(guest, [second.id, first.id]);

      expect(
        (await favorites.list(guest)).map((item) => item.name),
        ['B', 'A'],
      );
    });

    test('rejects duplicates and partial orders', () async {
      final first = await favorites.add(guest, await shareList('A'));
      await favorites.add(guest, await shareList('B'));

      await expectLater(
        favorites.reorder(guest, [first.id, first.id]),
        throwsA(isA<BadRequestException>()),
      );
      await expectLater(
        favorites.reorder(guest, [first.id]),
        throwsA(isA<BadRequestException>()),
      );
    });
  });

  group('FavoriteService.remove', () {
    test('detaches a favorite and leaves the wishlist', () async {
      final token = await shareList('Birthday');
      final added = await favorites.add(guest, token);

      await favorites.remove(guest, added.id);

      expect(await favorites.list(guest), isEmpty);
      expect(data.wishlists.containsKey(added.id), isTrue);
    });

    test('returns 404 when the wishlist is not in favorites', () async {
      await expectLater(
        favorites.remove(guest, 99),
        throwsA(isA<NotFoundException>()),
      );
    });
  });
}
