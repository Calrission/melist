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
          color: '#FFB74D',
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
    },
  );
}
