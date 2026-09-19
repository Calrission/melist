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
    test('creates a draft with default color and next position', () async {
      await service.create(owner, name: ' Birthday ');
      final created = await service.create(owner, name: 'NY');

      expect(created.name, 'NY');
      expect(created.color, defaultWishlistColor);
      expect(created.visibility, WishlistVisibility.draft);
      expect(created.position, 1);
      expect(data.userIds, contains(7));
    });

    test('accepts palette color case-insensitively', () async {
      final created = await service.create(
        owner,
        name: 'Party',
        color: '#ef5350',
        visibility: 'public',
      );

      expect(created.color, '#EF5350');
      expect(created.visibility, WishlistVisibility.public);
    });

    test('rejects empty name and unknown color or visibility', () {
      expect(
        () => service.create(owner, name: '  '),
        throwsA(isA<BadRequestException>()),
      );
      expect(
        () => service.create(owner, name: 'A', color: '#000000'),
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
    test('lists own wishlists by position', () async {
      await service.create(owner, name: 'A');
      await service.create(owner, name: 'B');
      await service.create(stranger, name: 'C');

      final mine = await service.listMine(owner);
      expect(mine.map((item) => item.name), ['A', 'B']);
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
    test('changes name, visibility and color', () async {
      final created = await service.create(owner, name: 'Old');

      final updated = await service.update(
        owner,
        created.id,
        name: 'New',
        visibility: 'public',
        color: '#42A5F5',
      );

      expect(updated.name, 'New');
      expect(updated.visibility, WishlistVisibility.public);
      expect(updated.color, '#42A5F5');
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
}
