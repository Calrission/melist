import 'package:melist_backend/melist_backend.dart';
import 'package:melist_core/melist_core.dart';
import 'package:test/test.dart';

import '../../helpers/memory_wishlists.dart';

void main() {
  const owner = AuthUser(
    id: 7,
    firstName: 'Ann',
    lastName: 'Lee',
    username: 'ann',
  );
  const guest = AuthUser(id: 8, username: 'bob');

  late MemoryWishlistData data;
  late WishlistService wishlists;
  late ProfileService profiles;

  setUp(() {
    data = MemoryWishlistData();
    wishlists = memoryWishlistService(data);
    profiles = memoryProfileService(data);
  });

  group('ProfileService.me', () {
    test('upserts the current user and returns defaults', () async {
      final me = await profiles.me(owner);

      expect(me.id, 7);
      expect(me.firstName, 'Ann');
      expect(me.lastName, 'Lee');
      expect(me.username, 'ann');
      expect(me.nickname, isNull);
      expect(me.displayName, 'Ann Lee');
      expect(me.birthday, isNull);
      expect(me.theme, UiTheme.system);
      expect(data.userIds, contains(7));
    });

    test('keeps avatar from Telegram upsert', () async {
      await MemoryUserRepository(data).upsertTelegram(
        const UserModel(
          id: 7,
          firstName: 'Ann',
          avatarUrl: 'https://t.me/i/userpic/320/ann.png',
        ),
      );

      final me = await profiles.me(owner);

      expect(me.avatarUrl, 'https://t.me/i/userpic/320/ann.png');
    });
  });

  group('ProfileService.update', () {
    test('sets birthday and theme', () async {
      final updated = await profiles.update(
        owner,
        birthday: '1990-05-12',
        theme: 'dark',
      );

      expect(updated.birthday, DateTime.utc(1990, 5, 12));
      expect(updated.theme, UiTheme.dark);

      final me = await profiles.me(owner);
      expect(me.birthday, DateTime.utc(1990, 5, 12));
      expect(me.theme, UiTheme.dark);
    });

    test('clears birthday when null is sent', () async {
      await profiles.update(owner, birthday: '1990-05-12');

      final updated = await profiles.update(owner, birthday: null);

      expect(updated.birthday, isNull);
    });

    test('sets and clears a nickname', () async {
      final renamed = await profiles.update(owner, nickname: ' Annie ');

      expect(renamed.nickname, 'Annie');
      expect(renamed.displayName, 'Annie');
      expect(renamed.firstName, 'Ann');

      final cleared = await profiles.update(owner, nickname: null);
      expect(cleared.nickname, isNull);
      expect(cleared.displayName, 'Ann Lee');

      final blank = await profiles.update(owner, nickname: '  ');
      expect(blank.displayName, 'Ann Lee');
    });

    test('rejects a nickname that is not a string', () async {
      await expectLater(
        profiles.update(owner, nickname: 1),
        throwsA(isA<BadRequestException>()),
      );
    });

    test('rejects empty patch, invalid birthday and theme', () async {
      await expectLater(
        profiles.update(owner),
        throwsA(isA<BadRequestException>()),
      );
      await expectLater(
        profiles.update(owner, birthday: '12-05-1990'),
        throwsA(isA<BadRequestException>()),
      );
      await expectLater(
        profiles.update(owner, birthday: '1990-02-31'),
        throwsA(isA<BadRequestException>()),
      );
      await expectLater(
        profiles.update(owner, theme: 'neon'),
        throwsA(isA<BadRequestException>()),
      );
    });
  });

  group('ProfileService.getPublic', () {
    test('returns the user and only public wishlists', () async {
      await wishlists.create(owner, name: 'Birthday', visibility: 'public');
      await wishlists.create(owner, name: 'Draft', visibility: 'draft');

      final profile = await profiles.getPublic(owner.id, viewer: guest);

      expect(profile.user.username, 'ann');
      expect(profile.wishlists.map((item) => item.name), ['Birthday']);
      expect(profile.wishlists.single.shareToken, isNotNull);
    });

    test('shows a link wishlist only to a viewer who favorited it', () async {
      await wishlists.create(owner, name: 'Birthday', visibility: 'public');
      final link = await wishlists.create(
        owner,
        name: 'Secret',
        visibility: 'link',
      );
      await wishlists.create(owner, name: 'Draft', visibility: 'draft');
      data.favorites[guest.id] = [link.id];

      final forGuest = await profiles.getPublic(owner.id, viewer: guest);
      final forStranger = await profiles.getPublic(
        owner.id,
        viewer: const AuthUser(id: 9, username: 'cara'),
      );

      expect(forGuest.wishlists.map((item) => item.name), [
        'Birthday',
        'Secret',
      ]);
      expect(forStranger.wishlists.map((item) => item.name), ['Birthday']);
    });

    test('returns 404 when the user does not exist', () async {
      await expectLater(
        profiles.getPublic(guest.id, viewer: owner),
        throwsA(isA<NotFoundException>()),
      );
    });
  });
}
