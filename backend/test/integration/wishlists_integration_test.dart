@Tags(['integration'])
library;

import 'dart:io';

import 'package:melist_backend/melist_backend.dart';
import 'package:melist_core/melist_core.dart';
import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

void main() {
  final adminUrl = Platform.environment['TEST_DATABASE_URL'];

  group(
    'WishlistService on PostgreSQL',
    skip: adminUrl == null || adminUrl.isEmpty
        ? 'TEST_DATABASE_URL is not set'
        : null,
    () {
      late Database admin;
      late Database db;
      late String dbName;
      late WishlistService wishlists;

      setUpAll(() async {
        final adminConfig = DatabaseConfig.parse(adminUrl!);
        admin = Database.fromConfig(adminConfig);
        dbName =
            'melist_wishlists_test_${DateTime.now().millisecondsSinceEpoch}';
        await admin.executeScript('CREATE DATABASE $dbName');

        final endpoint = adminConfig.endpoint;
        db = Database.fromConfig(
          DatabaseConfig(
            endpoint: Endpoint(
              host: endpoint.host,
              port: endpoint.port,
              database: dbName,
              username: endpoint.username,
              password: endpoint.password,
            ),
            sslMode: adminConfig.sslMode,
            maxConnections: 2,
          ),
        );
        await Migrator(db).migrate();
        wishlists = WishlistService.fromDatabase(db);
      });

      tearDownAll(() async {
        await db.close(force: true);
        await admin.executeScript(
          'DROP DATABASE IF EXISTS $dbName WITH (FORCE)',
        );
        await admin.close();
      });

      const owner = AuthUser(id: 42, firstName: 'Ann');

      test('create, list, get, update and delete', () async {
        final created = await wishlists.create(
          owner,
          name: 'Birthday',
          visibility: 'public',
        );

        expect(created.id, greaterThan(0));
        expect(created.ownerId, 42);
        expect(created.visibility, WishlistVisibility.public);

        final listed = await wishlists.listMine(owner);
        expect(listed.single.name, 'Birthday');

        final card = await wishlists.getById(owner, created.id);
        expect(card.items, isEmpty);

        final updated = await wishlists.update(
          owner,
          created.id,
          name: 'New year',
          visibility: 'draft',
        );
        expect(updated.name, 'New year');
        expect(updated.visibility, WishlistVisibility.draft);

        await wishlists.deleteOne(owner, created.id);
        expect(await wishlists.listMine(owner), isEmpty);
      });

      test('bulk delete only own rows', () async {
        final first = await wishlists.create(owner, name: 'A');
        final second = await wishlists.create(owner, name: 'B');

        await wishlists.deleteMany(owner, [first.id, second.id]);
        expect(await wishlists.listMine(owner), isEmpty);
      });

      test('add, reorder, copy and detach wishes', () async {
        final wishes = WishService.fromDatabase(db);
        final list = await wishlists.create(owner, name: 'Birthday');
        final created = await wishlists.addWish(
          owner,
          list.id,
          wish: {'name': 'Book', 'price': 500},
        );
        expect(created.ownerId, 42);

        final second = await wishlists.addWish(
          owner,
          list.id,
          wish: {'name': 'Headphones'},
        );
        await wishlists.reorderWishes(owner, list.id, [
          second.id,
          created.id,
        ]);
        expect(
          (await wishlists.getById(owner, list.id)).items.map(
            (item) => item.id,
          ),
          [second.id, created.id],
        );

        const stranger = AuthUser(id: 43, firstName: 'Bob');
        final publicList = await wishlists.create(
          stranger,
          name: 'Public',
          visibility: 'public',
        );
        final source = await wishlists.addWish(
          stranger,
          publicList.id,
          wish: {'name': 'Camera'},
        );
        final copy = await wishlists.addWish(
          owner,
          list.id,
          copyFromWishId: source.id,
        );
        expect(copy.copiedFrom, source.id);
        expect(copy.ownerId, 42);

        await wishlists.removeWish(owner, list.id, created.id);
        expect(
          (await wishlists.getById(owner, list.id)).items.map(
            (item) => item.id,
          ),
          [second.id, copy.id],
        );
        expect((await wishes.getById(owner, created.id)).name, 'Book');
      });

      test('reorder wishlists and share a link list by token', () async {
        const sorter = AuthUser(id: 77, firstName: 'Cara');
        final first = await wishlists.create(
          sorter,
          name: 'A',
          visibility: 'link',
        );
        final second = await wishlists.create(sorter, name: 'B');
        await wishlists.reorder(sorter, [second.id, first.id]);
        expect(
          (await wishlists.listMine(sorter)).map((item) => item.name),
          ['B', 'A'],
        );

        await wishlists.addWish(
          sorter,
          first.id,
          wish: {'name': 'Secret'},
        );
        await wishlists.addWish(
          sorter,
          first.id,
          wish: {'name': 'Camera'},
        );
        final token = await wishlists.share(sorter, first.id);
        expect(token, isNotEmpty);
        expect(await wishlists.share(sorter, first.id), token);

        const stranger = AuthUser(id: 99, firstName: 'Guest');
        final shared = await wishlists.getShared(stranger, 'wl_$token');
        expect(shared.id, first.id);
        expect(shared.items.map((item) => item.name), ['Secret', 'Camera']);
      });
    },
  );
}
