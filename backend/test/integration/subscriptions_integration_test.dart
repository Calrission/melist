@Tags(['integration'])
library;

import 'dart:io';

import 'package:melist_backend/melist_backend.dart';
import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

void main() {
  final adminUrl = Platform.environment['TEST_DATABASE_URL'];

  group(
    'SubscriptionService on PostgreSQL',
    skip: adminUrl == null || adminUrl.isEmpty
        ? 'TEST_DATABASE_URL is not set'
        : null,
    () {
      late Database admin;
      late Database db;
      late String dbName;
      late WishlistService wishlists;
      late SubscriptionService subscriptions;

      setUpAll(() async {
        final adminConfig = DatabaseConfig.parse(adminUrl!);
        admin = Database.fromConfig(adminConfig);
        dbName = 'melist_subs_test_${DateTime.now().millisecondsSinceEpoch}';
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
        subscriptions = SubscriptionService.fromDatabase(db);
      });

      tearDownAll(() async {
        await db.close(force: true);
        await admin.executeScript(
          'DROP DATABASE IF EXISTS $dbName WITH (FORCE)',
        );
        await admin.close();
      });

      const owner = AuthUser(id: 42, firstName: 'Ann', username: 'ann');
      const guest = AuthUser(id: 43, firstName: 'Bob', username: 'bob');

      test('subscribe to public wishlist and profile', () async {
        final publicList = await wishlists.create(
          owner,
          name: 'Birthday',
          visibility: 'public',
        );
        await wishlists.create(owner, name: 'Draft', visibility: 'draft');

        final added = await subscriptions.subscribeWishlist(
          guest,
          publicList.id,
        );
        expect(added.name, 'Birthday');
        expect(
          (await subscriptions.listWishlists(guest)).single.id,
          publicList.id,
        );

        await expectLater(
          subscriptions.subscribeWishlist(guest, publicList.id),
          throwsA(isA<ConflictException>()),
        );

        final followee = await subscriptions.subscribeUser(guest, owner.id);
        expect(followee.username, 'ann');
        expect(
          (await subscriptions.listUsers(guest)).single.id,
          owner.id,
        );

        await subscriptions.unsubscribeWishlist(guest, publicList.id);
        expect(await subscriptions.listWishlists(guest), isEmpty);

        await subscriptions.unsubscribeUser(guest, owner.id);
        expect(await subscriptions.listUsers(guest), isEmpty);
      });
    },
  );
}
