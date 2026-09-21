import 'package:melist_backend/melist_backend.dart';
import 'package:melist_core/melist_core.dart';
import 'package:test/test.dart';

import '../../helpers/memory_wishes.dart';

void main() {
  const owner = AuthUser(id: 7, username: 'ann');
  const stranger = AuthUser(id: 8, username: 'bob');

  late MemoryWishData data;
  late WishService service;

  setUp(() {
    data = MemoryWishData();
    service = memoryWishService(data);
  });

  group('WishService.create', () {
    test('creates a free wish and upserts the user', () async {
      final created = await service.create(owner, name: ' Headphones ');

      expect(created.name, 'Headphones');
      expect(created.status, WishStatus.free);
      expect(created.ownerId, 7);
      expect(data.userIds, contains(7));
    });

    test('stores optional fields and enums', () async {
      final created = await service.create(
        owner,
        name: 'Book',
        price: 12000,
        url: ' https://shop.example/book ',
        description: ' Hardcover ',
        coverUrl: 'https://img.example/cover.png',
        status: 'draft',
      );

      expect(created.price, 12000);
      expect(created.url, 'https://shop.example/book');
      expect(created.description, 'Hardcover');
      expect(created.status, WishStatus.draft);
    });

    test('rejects empty name, negative price and unknown enums', () {
      expect(
        () => service.create(owner, name: '  '),
        throwsA(isA<BadRequestException>()),
      );
      expect(
        () => service.create(owner, name: 'A', price: -1),
        throwsA(isA<BadRequestException>()),
      );
      expect(
        () => service.create(owner, name: 'A', status: 'done'),
        throwsA(isA<BadRequestException>()),
      );
    });
  });

  group('WishService.get and list', () {
    test('lists own wishes newest first and filters by name', () async {
      await service.create(owner, name: 'Book');
      await service.create(owner, name: 'Headphones');
      await service.create(stranger, name: 'Headphones');

      final mine = await service.listMine(owner);
      expect(mine.map((item) => item.name), ['Headphones', 'Book']);

      final found = await service.listMine(owner, query: 'head');
      expect(found.single.name, 'Headphones');
    });

    test('paginates with limit and offset', () async {
      await service.create(owner, name: 'A');
      await service.create(owner, name: 'B');
      await service.create(owner, name: 'C');

      final page = await service.listMine(owner, limit: 2, offset: 1);
      expect(page.map((item) => item.name), ['B', 'A']);
    });

    test('rejects invalid limit and offset', () {
      expect(
        () => service.listMine(owner, limit: 0),
        throwsA(isA<BadRequestException>()),
      );
      expect(
        () => service.listMine(owner, offset: -1),
        throwsA(isA<BadRequestException>()),
      );
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
    });
  });

  group('WishService.update', () {
    test('changes fields and clears nullable ones', () async {
      final created = await service.create(
        owner,
        name: 'Old',
        price: 10,
        url: 'https://old.example',
      );

      final updated = await service.update(
        owner,
        created.id,
        name: 'New',
        status: 'reserved',
        price: null,
        url: '',
      );

      expect(updated.name, 'New');
      expect(updated.status, WishStatus.reserved);
      expect(updated.price, isNull);
      expect(updated.url, isNull);
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

  group('WishService.duplicate and delete', () {
    test('duplicates an own wish with copiedFrom', () async {
      final created = await service.create(
        owner,
        name: 'Book',
        price: 500,
      );

      final copy = await service.duplicate(owner, created.id);

      expect(copy.id, isNot(created.id));
      expect(copy.name, 'Book');
      expect(copy.price, 500);
      expect(copy.copiedFrom, created.id);
    });

    test('duplicate rejects missing and foreign wishes', () async {
      final created = await service.create(owner, name: 'A');

      await expectLater(
        service.duplicate(owner, 404),
        throwsA(isA<NotFoundException>()),
      );
      await expectLater(
        service.duplicate(stranger, created.id),
        throwsA(isA<ForbiddenException>()),
      );
    });

    test('deletes one own wish', () async {
      final created = await service.create(owner, name: 'A');
      await service.deleteOne(owner, created.id);

      expect(data.wishes, isEmpty);
    });

    test('bulk delete requires every id to be owned', () async {
      final first = await service.create(owner, name: 'A');
      final second = await service.create(owner, name: 'B');
      final other = await service.create(stranger, name: 'C');

      await service.deleteMany(owner, [first.id, second.id]);
      expect(data.wishes.keys, [other.id]);

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
