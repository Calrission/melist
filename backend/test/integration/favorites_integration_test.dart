@Tags(['integration'])
library;

import 'dart:io';

import 'package:melist_backend/melist_backend.dart';
import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

void main() {
  final adminUrl = Platform.environment['TEST_DATABASE_URL'];

  group(
    'FavoriteService on PostgreSQL',
    skip: adminUrl == null || adminUrl.isEmpty
        ? 'TEST_DATABASE_URL is not set'
        : null,
    () {
      late Database admin;
      late Database db;
      late String dbName;
      late WishlistService wishlists;
      late FavoriteService favorites;

      setUpAll(() async {
        final adminConfig = DatabaseConfig.parse(adminUrl!);
        admin = Database.fromConfig(adminConfig);
        dbName =
            'melist_favorites_test_${DateTime.now().millisecondsSinceEpoch}';
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
        favorites = FavoriteService.fromDatabase(db);
      });

      tearDownAll(() async {
        await db.close(force: true);
        await admin.executeScript(
          'DROP DATABASE IF EXISTS $dbName WITH (FORCE)',
        );
        await admin.close();
      });

      const owner = AuthUser(id: 42, firstName: 'Ann');
      const guest = AuthUser(id: 43, firstName: 'Bob');

      test('add by share token, reorder, hide private and remove', () async {
        final first = await wishlists.create(owner, name: 'A');
        await wishlists.addWish(
          owner,
          first.id,
          wish: {'name': 'Camera'},
        );
        await wishlists.addWish(
          owner,
          first.id,
          wish: {'name': 'Secret', 'visibility': 'private'},
        );
        final firstToken = await wishlists.share(owner, first.id);

        final second = await wishlists.create(owner, name: 'B');
        final secondToken = await wishlists.share(owner, second.id);

        final added = await favorites.add(guest, 'wl_$firstToken');
        expect(added.name, 'A');
        expect(added.items.map((item) => item.name), ['Camera']);

        final other = await favorites.add(guest, secondToken);
        await favorites.reorder(guest, [other.id, added.id]);
        expect(
          (await favorites.list(guest)).map((item) => item.name),
          ['B', 'A'],
        );

        await favorites.remove(guest, added.id);
        expect(
          (await favorites.list(guest)).single.id,
          other.id,
        );
        expect((await wishlists.getById(owner, first.id)).name, 'A');
      });
    },
  );
}
