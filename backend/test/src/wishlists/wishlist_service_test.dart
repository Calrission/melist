import 'package:melist_backend/melist_backend.dart';
import 'package:melist_core/melist_core.dart';
import 'package:test/test.dart';

import '../../helpers/memory_wishlists.dart';

void main() {
  const owner = AuthUser(id: 7, username: 'ann');
  const stranger = AuthUser(id: 8, username: 'bob');

  late MemoryWishlistData data;
  late WishlistService service;

  setUp(() {
    data = MemoryWishlistData();
    service = memoryWishlistService(data);
  });

  group('WishlistService.create', () {
    test('creates a draft with the next position', () async {
      await service.create(owner, name: ' Birthday ');
      final created = await service.create(owner, name: 'NY');

      expect(created.name, 'NY');
      expect(created.visibility, WishlistVisibility.draft);
      expect(created.position, 1);
      expect(data.userIds, contains(7));
    });

    test('accepts public visibility', () async {
      final created = await service.create(
        owner,
        name: 'Party',
        visibility: 'public',
      );

      expect(created.visibility, WishlistVisibility.public);
    });

    test('stores a trimmed cover url', () async {
      final created = await service.create(
        owner,
        name: 'Party',
        coverUrl: ' https://img.example/cover.png ',
      );
      expect(created.coverUrl, 'https://img.example/cover.png');

      final blank = await service.create(owner, name: 'Plain', coverUrl: '  ');
      expect(blank.coverUrl, isNull);
    });

    test('rejects empty name and unknown visibility', () {
      expect(
        () => service.create(owner, name: '  '),
        throwsA(isA<BadRequestException>()),
      );
      expect(
        () => service.create(owner, name: 'A', visibility: 'hidden'),
        throwsA(isA<BadRequestException>()),
      );
    });

    test('attaches only own wishes', () async {
      data.wishes[1] = const WishModel(id: 1, ownerId: 7, name: 'Book');
      data.wishes[2] = const WishModel(id: 2, ownerId: 8, name: 'Other');

      await expectLater(
        service.create(owner, name: 'List', wishIds: [1, 2]),
        throwsA(isA<BadRequestException>()),
      );

      final created = await service.create(
        owner,
        name: 'List',
        wishIds: [1, 1],
      );
      expect(created.items.single.id, 1);
    });
  });

  group('WishlistService.get and list', () {
    test('lists own wishlists by position with their wishes', () async {
      data.wishes[1] = const WishModel(id: 1, ownerId: 7, name: 'Book');
      await service.create(owner, name: 'A', wishIds: [1]);
      await service.create(owner, name: 'B');
      await service.create(stranger, name: 'C');

      final mine = await service.listMine(owner);
      expect(mine.map((item) => item.name), ['A', 'B']);
      expect(mine.first.items.map((item) => item.name), ['Book']);
      expect(mine.last.items, isEmpty);
    });

    test('returns 404 / 403 on getById', () async {
      final created = await service.create(owner, name: 'A');

      await expectLater(
        service.getById(owner, 404),
        throwsA(isA<NotFoundException>()),
      );
      await expectLater(
        service.getById(stranger, created.id),
        throwsA(isA<ForbiddenException>()),
      );

      final loaded = await service.getById(owner, created.id);
      expect(loaded.name, 'A');
      expect(loaded.items, isEmpty);
    });
  });

  group('WishlistService.update', () {
    test('changes name and visibility', () async {
      final created = await service.create(owner, name: 'Old');

      final updated = await service.update(
        owner,
        created.id,
        name: 'New',
        visibility: 'public',
      );

      expect(updated.name, 'New');
      expect(updated.visibility, WishlistVisibility.public);
    });

    test('sets and clears cover url', () async {
      final created = await service.create(owner, name: 'Old');

      final updated = await service.update(
        owner,
        created.id,
        coverUrl: ' https://img.example/cover.png ',
      );
      expect(updated.coverUrl, 'https://img.example/cover.png');

      final cleared = await service.update(owner, created.id, coverUrl: null);
      expect(cleared.coverUrl, isNull);

      final blank = await service.update(owner, created.id, coverUrl: '  ');
      expect(blank.coverUrl, isNull);
    });

    test('rejects empty patch and foreign owners', () async {
      final created = await service.create(owner, name: 'A');

      await expectLater(
        service.update(owner, created.id),
        throwsA(isA<BadRequestException>()),
      );
      await expectLater(
        service.update(stranger, created.id, name: 'X'),
        throwsA(isA<ForbiddenException>()),
      );
    });
  });

  group('WishlistService.delete', () {
    test('deletes one own wishlist', () async {
      final created = await service.create(owner, name: 'A');
      await service.deleteOne(owner, created.id);

      expect(data.wishlists, isEmpty);
    });

    test('bulk delete requires every id to be owned', () async {
      final first = await service.create(owner, name: 'A');
      final second = await service.create(owner, name: 'B');
      final other = await service.create(stranger, name: 'C');

      await service.deleteMany(owner, [first.id, second.id]);
      expect(data.wishlists.keys, [other.id]);

      await expectLater(
        service.deleteMany(owner, [other.id]),
        throwsA(isA<NotFoundException>()),
      );
      await expectLater(
        service.deleteMany(owner, []),
        throwsA(isA<BadRequestException>()),
      );
    });
  });

  group('WishlistService.addWish', () {
    test('creates a new wish and appends it (4.1)', () async {
      final list = await service.create(owner, name: 'Birthday');

      final created = await service.addWish(
        owner,
        list.id,
        wish: {'name': ' Headphones ', 'price': 12000},
      );

      expect(created.name, 'Headphones');
      expect(created.ownerId, 7);
      expect(created.price, 12000);
      expect(data.userIds, contains(7));

      final card = await service.getById(owner, list.id);
      expect(card.items.single.id, created.id);
    });

    test('attaches an own existing wish (4.2)', () async {
      final first = await service.create(owner, name: 'A');
      final second = await service.create(owner, name: 'B');
      final wish = await service.addWish(
        owner,
        first.id,
        wish: {'name': 'Book'},
      );

      final attached = await service.addWish(
        owner,
        second.id,
        wishId: wish.id,
      );

      expect(attached.id, wish.id);
      expect(
        (await service.getById(owner, second.id)).items.single.id,
        wish.id,
      );
    });

    test('rejects a second attach of the same wish with 409', () async {
      final list = await service.create(owner, name: 'A');
      final wish = await service.addWish(
        owner,
        list.id,
        wish: {'name': 'Book'},
      );

      await expectLater(
        service.addWish(owner, list.id, wishId: wish.id),
        throwsA(isA<ConflictException>()),
      );
    });

    test('copies a foreign public wish from a public wishlist (4.3)', () async {
      final publicList = await service.create(
        stranger,
        name: 'Public',
        visibility: 'public',
      );
      final source = await service.addWish(
        stranger,
        publicList.id,
        wish: {'name': 'Headphones', 'url': 'https://shop.example'},
      );
      final mine = await service.create(owner, name: 'Mine');

      final copy = await service.addWish(
        owner,
        mine.id,
        copyFromWishId: source.id,
      );

      expect(copy.id, isNot(source.id));
      expect(copy.ownerId, 7);
      expect(copy.name, 'Headphones');
      expect(copy.url, 'https://shop.example');
      expect(copy.copiedFrom, source.id);
    });

    test('copies own wish without a public appearance', () async {
      final first = await service.create(owner, name: 'A');
      final source = await service.addWish(
        owner,
        first.id,
        wish: {'name': 'Secret'},
      );
      final second = await service.create(owner, name: 'B');

      final copy = await service.addWish(
        owner,
        second.id,
        copyFromWishId: source.id,
      );

      expect(copy.copiedFrom, source.id);
    });

    test('forbids copying an unpublished foreign wish', () async {
      final draftList = await service.create(stranger, name: 'Draft');
      final unpublished = await service.addWish(
        stranger,
        draftList.id,
        wish: {'name': 'Draft wish'},
      );
      final mine = await service.create(owner, name: 'Mine');

      await expectLater(
        service.addWish(owner, mine.id, copyFromWishId: unpublished.id),
        throwsA(isA<ForbiddenException>()),
      );
    });

    test('rejects mixed or empty add variants and foreign wishlists', () async {
      final list = await service.create(owner, name: 'A');
      final other = await service.create(stranger, name: 'B');

      await expectLater(
        service.addWish(owner, list.id),
        throwsA(isA<BadRequestException>()),
      );
      await expectLater(
        service.addWish(
          owner,
          list.id,
          wish: {'name': 'A'},
          wishId: 1,
        ),
        throwsA(isA<BadRequestException>()),
      );
      await expectLater(
        service.addWish(owner, other.id, wish: {'name': 'A'}),
        throwsA(isA<ForbiddenException>()),
      );
      await expectLater(
        service.addWish(owner, list.id, wishId: 99),
        throwsA(isA<NotFoundException>()),
      );
    });
  });

  group('WishlistService.reorderWishes', () {
    test('reorders wishes by a full permutation', () async {
      final list = await service.create(owner, name: 'A');
      final first = await service.addWish(
        owner,
        list.id,
        wish: {'name': 'One'},
      );
      final second = await service.addWish(
        owner,
        list.id,
        wish: {'name': 'Two'},
      );
      final third = await service.addWish(
        owner,
        list.id,
        wish: {'name': 'Three'},
      );

      await service.reorderWishes(owner, list.id, [
        third.id,
        first.id,
        second.id,
      ]);

      expect(
        (await service.getById(owner, list.id)).items.map((item) => item.id),
        [third.id, first.id, second.id],
      );
    });

    test('rejects duplicates and partial orders', () async {
      final list = await service.create(owner, name: 'A');
      final first = await service.addWish(
        owner,
        list.id,
        wish: {'name': 'One'},
      );
      final second = await service.addWish(
        owner,
        list.id,
        wish: {'name': 'Two'},
      );

      await expectLater(
        service.reorderWishes(owner, list.id, [first.id, first.id]),
        throwsA(isA<BadRequestException>()),
      );
      await expectLater(
        service.reorderWishes(owner, list.id, [first.id]),
        throwsA(isA<BadRequestException>()),
      );
      await expectLater(
        service.reorderWishes(owner, list.id, [first.id, 99]),
        throwsA(isA<BadRequestException>()),
      );
      expect(
        (await service.getById(owner, list.id)).items.map((item) => item.id),
        [first.id, second.id],
      );
    });
  });

  group('WishlistService.removeWish', () {
    test('detaches a wish and leaves the catalog row', () async {
      final list = await service.create(owner, name: 'A');
      final wish = await service.addWish(
        owner,
        list.id,
        wish: {'name': 'Book'},
      );

      await service.removeWish(owner, list.id, wish.id);

      expect((await service.getById(owner, list.id)).items, isEmpty);
      expect(data.wishes[wish.id]?.name, 'Book');
    });

    test('returns 404 when the wish is not in the list', () async {
      final list = await service.create(owner, name: 'A');

      await expectLater(
        service.removeWish(owner, list.id, 99),
        throwsA(isA<NotFoundException>()),
      );
    });
  });

  group('WishlistService.reorder', () {
    test('reorders own wishlists by a full permutation', () async {
      final first = await service.create(owner, name: 'A');
      final second = await service.create(owner, name: 'B');
      final third = await service.create(owner, name: 'C');

      await service.reorder(owner, [third.id, first.id, second.id]);

      expect(
        (await service.listMine(owner)).map((item) => item.name),
        ['C', 'A', 'B'],
      );
    });

    test('rejects duplicates and partial orders', () async {
      final first = await service.create(owner, name: 'A');
      final second = await service.create(owner, name: 'B');

      await expectLater(
        service.reorder(owner, [first.id, first.id]),
        throwsA(isA<BadRequestException>()),
      );
      await expectLater(
        service.reorder(owner, [first.id]),
        throwsA(isA<BadRequestException>()),
      );
      expect(
        (await service.listMine(owner)).map((item) => item.id),
        [first.id, second.id],
      );
    });
  });

  group('WishlistService.share and getShared', () {
    test('creates a token once and returns the same link later', () async {
      final list = await service.create(owner, name: 'Birthday');

      final first = await service.share(owner, list.id);
      final second = await service.share(owner, list.id);

      expect(first, isNotEmpty);
      expect(second, first);
      expect(data.wishlists[list.id]?.shareToken, first);
    });

    test('resolves a share token including the wl_ prefix', () async {
      final list = await service.create(
        owner,
        name: 'Link',
        visibility: 'link',
      );
      await service.addWish(
        owner,
        list.id,
        wish: {'name': 'Book'},
      );
      final token = await service.share(owner, list.id);

      final shared = await service.getShared(stranger, 'wl_$token');
      expect(shared.id, list.id);
      expect(shared.name, 'Link');
      expect(shared.items.single.name, 'Book');
    });

    test('shows every wish on a shared list', () async {
      final list = await service.create(
        owner,
        name: 'Gifts',
        visibility: 'link',
      );
      await service.addWish(
        owner,
        list.id,
        wish: {'name': 'Public'},
      );
      await service.addWish(
        owner,
        list.id,
        wish: {'name': 'Secret'},
      );
      final token = await service.share(owner, list.id);

      final guest = await service.getShared(stranger, token);
      expect(guest.items.map((item) => item.name), ['Public', 'Secret']);

      final own = await service.getShared(owner, token);
      expect(own.items.map((item) => item.name), ['Public', 'Secret']);
    });

    test('hides a draft from strangers even with a token', () async {
      final list = await service.create(owner, name: 'Draft');
      final token = await service.share(owner, list.id);

      await expectLater(
        service.getShared(stranger, token),
        throwsA(isA<NotFoundException>()),
      );
      final own = await service.getShared(owner, token);
      expect(own.id, list.id);
    });

    test('rejects sharing a foreign wishlist and unknown tokens', () async {
      final list = await service.create(owner, name: 'A');

      await expectLater(
        service.share(stranger, list.id),
        throwsA(isA<ForbiddenException>()),
      );
      await expectLater(
        service.getShared(owner, 'missing'),
        throwsA(isA<NotFoundException>()),
      );
    });
  });
}
