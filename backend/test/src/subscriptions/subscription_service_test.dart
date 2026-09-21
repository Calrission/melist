import 'package:melist_backend/melist_backend.dart';
import 'package:test/test.dart';

import '../../helpers/memory_wishlists.dart';

void main() {
  const owner = AuthUser(id: 7, username: 'ann');
  const guest = AuthUser(id: 8, username: 'bob');

  late MemoryWishlistData data;
  late WishlistService wishlists;
  late SubscriptionService subscriptions;

  setUp(() {
    data = MemoryWishlistData();
    wishlists = memoryWishlistService(data);
    subscriptions = memorySubscriptionService(data);
  });

  group('SubscriptionService wishlists', () {
    test('subscribes to a public wishlist and lists newest first', () async {
      final first = await wishlists.create(
        owner,
        name: 'Birthday',
        visibility: 'public',
      );
      final second = await wishlists.create(
        owner,
        name: 'New Year',
        visibility: 'public',
      );

      final added = await subscriptions.subscribeWishlist(guest, first.id);
      expect(added.name, 'Birthday');
      expect(data.userIds, contains(8));

      await subscriptions.subscribeWishlist(guest, second.id);
      expect(
        (await subscriptions.listWishlists(guest)).map((item) => item.name),
        ['New Year', 'Birthday'],
      );
    });

    test('rejects own, draft, missing and duplicate wishlists', () async {
      final publicList = await wishlists.create(
        owner,
        name: 'Public',
        visibility: 'public',
      );
      final draft = await wishlists.create(
        owner,
        name: 'Draft',
        visibility: 'draft',
      );

      await expectLater(
        subscriptions.subscribeWishlist(owner, publicList.id),
        throwsA(isA<BadRequestException>()),
      );
      await expectLater(
        subscriptions.subscribeWishlist(guest, null),
        throwsA(isA<BadRequestException>()),
      );
      await expectLater(
        subscriptions.subscribeWishlist(guest, draft.id),
        throwsA(isA<NotFoundException>()),
      );
      await expectLater(
        subscriptions.subscribeWishlist(guest, 99),
        throwsA(isA<NotFoundException>()),
      );

      await subscriptions.subscribeWishlist(guest, publicList.id);
      await expectLater(
        subscriptions.subscribeWishlist(guest, publicList.id),
        throwsA(isA<ConflictException>()),
      );
    });

    test('hides draft lists from GET and unsubscribes', () async {
      final list = await wishlists.create(
        owner,
        name: 'Party',
        visibility: 'public',
      );
      await subscriptions.subscribeWishlist(guest, list.id);

      await wishlists.update(owner, list.id, visibility: 'draft');
      expect(await subscriptions.listWishlists(guest), isEmpty);

      await subscriptions.unsubscribeWishlist(guest, list.id);
      await expectLater(
        subscriptions.unsubscribeWishlist(guest, list.id),
        throwsA(isA<NotFoundException>()),
      );
    });
  });

  group('SubscriptionService users', () {
    test('subscribes to another profile and lists newest first', () async {
      await wishlists.create(owner, name: 'Mine');
      const other = AuthUser(id: 9, username: 'cara');
      await wishlists.create(other, name: 'Cara');

      final added = await subscriptions.subscribeUser(guest, owner.id);
      expect(added.username, 'ann');

      await subscriptions.subscribeUser(guest, other.id);
      expect(
        (await subscriptions.listUsers(guest)).map((item) => item.username),
        ['cara', 'ann'],
      );
    });

    test('rejects self, missing and duplicate profiles', () async {
      await wishlists.create(owner, name: 'Mine');

      await expectLater(
        subscriptions.subscribeUser(guest, guest.id),
        throwsA(isA<BadRequestException>()),
      );
      await expectLater(
        subscriptions.subscribeUser(guest, null),
        throwsA(isA<BadRequestException>()),
      );
      await expectLater(
        subscriptions.subscribeUser(guest, 404),
        throwsA(isA<NotFoundException>()),
      );

      await subscriptions.subscribeUser(guest, owner.id);
      await expectLater(
        subscriptions.subscribeUser(guest, owner.id),
        throwsA(isA<ConflictException>()),
      );
    });

    test('unsubscribes from a profile', () async {
      await wishlists.create(owner, name: 'Mine');
      await subscriptions.subscribeUser(guest, owner.id);

      await subscriptions.unsubscribeUser(guest, owner.id);
      expect(await subscriptions.listUsers(guest), isEmpty);
      await expectLater(
        subscriptions.unsubscribeUser(guest, owner.id),
        throwsA(isA<NotFoundException>()),
      );
    });
  });
}
