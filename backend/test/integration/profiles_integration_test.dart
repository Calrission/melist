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
    'ProfileService on PostgreSQL',
    skip: adminUrl == null || adminUrl.isEmpty
        ? 'TEST_DATABASE_URL is not set'
        : null,
    () {
      late Database admin;
      late Database db;
      late String dbName;
      late ProfileService profiles;
      late WishlistService wishlists;

      setUpAll(() async {
        final adminConfig = DatabaseConfig.parse(adminUrl!);
        admin = Database.fromConfig(adminConfig);
        dbName =
            'melist_profiles_test_${DateTime.now().millisecondsSinceEpoch}';
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
        profiles = ProfileService.fromDatabase(db);
        wishlists = WishlistService.fromDatabase(db);
      });

      tearDownAll(() async {
        await db.close(force: true);
        await admin.executeScript(
          'DROP DATABASE IF EXISTS $dbName WITH (FORCE)',
        );
        await admin.close();
      });

      const owner = AuthUser(
        id: 42,
        firstName: 'Ann',
        lastName: 'Lee',
        username: 'ann',
      );

      test('me, update settings and public profile', () async {
        await UserRepository(db).upsertTelegram(
          const UserModel(
            id: 42,
            firstName: 'Ann',
            lastName: 'Lee',
            username: 'ann',
            avatarUrl: 'https://t.me/i/userpic/320/ann.png',
          ),
        );

        final me = await profiles.me(owner);
        expect(me.avatarUrl, 'https://t.me/i/userpic/320/ann.png');
        expect(me.theme, UiTheme.system);
        expect(me.birthday, isNull);

        final updated = await profiles.update(
          owner,
          birthday: '1990-05-12',
          theme: 'dark',
        );
        expect(updated.birthday?.year, 1990);
        expect(updated.birthday?.month, 5);
        expect(updated.birthday?.day, 12);
        expect(updated.theme, UiTheme.dark);

        final cleared = await profiles.update(owner, birthday: null);
        expect(cleared.birthday, isNull);
        expect(cleared.theme, UiTheme.dark);

        await wishlists.create(
          owner,
          name: 'Birthday',
          visibility: 'public',
        );
        await wishlists.create(owner, name: 'Draft', visibility: 'draft');

        final public = await profiles.getPublic(42);
        expect(public.user.id, 42);
        expect(public.wishlists.map((item) => item.name), ['Birthday']);
      });
    },
  );
}
