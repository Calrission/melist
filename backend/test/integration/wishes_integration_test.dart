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
    'WishService on PostgreSQL',
    skip: adminUrl == null || adminUrl.isEmpty
        ? 'TEST_DATABASE_URL is not set'
        : null,
    () {
      late Database admin;
      late Database db;
      late String dbName;
      late WishService wishes;

      setUpAll(() async {
        final adminConfig = DatabaseConfig.parse(adminUrl!);
        admin = Database.fromConfig(adminConfig);
        dbName =
            'melist_wishes_test_${DateTime.now().millisecondsSinceEpoch}';
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
        wishes = WishService.fromDatabase(db);
      });

      tearDownAll(() async {
        await db.close(force: true);
        await admin.executeScript(
          'DROP DATABASE IF EXISTS $dbName WITH (FORCE)',
        );
        await admin.close();
      });

      const owner = AuthUser(id: 42, firstName: 'Ann');

      test('create, list, search, update, duplicate and delete', () async {
        final created = await wishes.create(
          owner,
          name: 'Headphones',
          price: 12000,
          visibility: 'private',
          status: 'draft',
        );

        expect(created.id, greaterThan(0));
        expect(created.ownerId, 42);
        expect(created.visibility, WishVisibility.private);
        expect(created.status, WishStatus.draft);
        expect(created.price, 12000);

        final listed = await wishes.listMine(owner);
        expect(listed.single.name, 'Headphones');

        final found = await wishes.listMine(owner, query: 'head');
        expect(found.single.id, created.id);

        final missed = await wishes.listMine(owner, query: 'book');
        expect(missed, isEmpty);

        final updated = await wishes.update(
          owner,
          created.id,
          name: 'Studio headphones',
          status: 'free',
        );
        expect(updated.name, 'Studio headphones');
        expect(updated.status, WishStatus.free);

        final copy = await wishes.duplicate(owner, created.id);
        expect(copy.copiedFrom, created.id);
        expect(copy.name, 'Studio headphones');

        await wishes.deleteOne(owner, created.id);
        expect(
          (await wishes.listMine(owner)).single.id,
          copy.id,
        );

        await wishes.deleteMany(owner, [copy.id]);
        expect(await wishes.listMine(owner), isEmpty);
      });
    },
  );
}
