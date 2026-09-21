import 'package:melist_backend/melist_backend.dart';
import 'package:melist_core/melist_core.dart';
import 'package:mocktail/mocktail.dart';

import 'memory_wishes.dart';

class MemoryWishlistData {
  final userIds = <int>{};
  final users = <int, UserModel>{};
  final wishlists = <int, WishlistModel>{};
  final wishStore = MemoryWishData();
  final items = <int, List<int>>{};
  final favorites = <int, List<int>>{};
  final wishlistSubs = <int, List<int>>{};
  final userSubs = <int, List<int>>{};
  int nextWishlistId = 1;

  Map<int, WishModel> get wishes => wishStore.wishes;
}

class MemoryUserRepository implements UserRepository {
  MemoryUserRepository(this.data);

  final MemoryWishlistData data;

  @override
  Future<void> ensure(AuthUser user) {
    return upsertTelegram(
      UserModel(
        id: user.id,
        firstName: user.firstName,
        lastName: user.lastName,
        username: user.username,
      ),
    );
  }

  @override
  Future<void> upsertTelegram(UserModel user) async {
    data.userIds.add(user.id);
    final current = data.users[user.id];
    data.users[user.id] = UserModel(
      id: user.id,
      firstName: user.firstName ?? current?.firstName,
      lastName: user.lastName ?? current?.lastName,
      username: user.username ?? current?.username,
      avatarUrl: user.avatarUrl ?? current?.avatarUrl,
      birthday: current?.birthday,
      theme: current?.theme ?? UiTheme.system,
      createdAt: current?.createdAt,
      updatedAt: current?.updatedAt,
    );
  }

  @override
  Future<UserModel?> findById(int id) async => data.users[id];

  @override
  Future<UserModel?> update({
    required int id,
    DateTime? birthday,
    bool clearBirthday = false,
    UiTheme? theme,
  }) async {
    final current = data.users[id];
    if (current == null) {
      return null;
    }
    final updated = UserModel(
      id: current.id,
      firstName: current.firstName,
      lastName: current.lastName,
      username: current.username,
      avatarUrl: current.avatarUrl,
      birthday: clearBirthday ? null : (birthday ?? current.birthday),
      theme: theme ?? current.theme,
      createdAt: current.createdAt,
      updatedAt: current.updatedAt,
    );
    data.users[id] = updated;
    return updated;
  }
}

class MemoryWishlistRepository implements WishlistRepository {
  MemoryWishlistRepository(this.data);

  final MemoryWishlistData data;

  @override
  Future<List<WishlistModel>> listByOwner(int ownerId) async {
    return data.wishlists.values
        .where((item) => item.ownerId == ownerId)
        .toList()
      ..sort((a, b) {
        final byPosition = a.position.compareTo(b.position);
        return byPosition != 0 ? byPosition : a.id.compareTo(b.id);
      });
  }

  @override
  Future<List<WishlistModel>> listPublicByOwner(int ownerId) async {
    return [
      for (final item in await listByOwner(ownerId))
        if (item.visibility == WishlistVisibility.public) item,
    ];
  }

  @override
  Future<WishlistModel?> findById(int id) async => data.wishlists[id];

  @override
  Future<WishlistModel?> findByShareToken(String token) async {
    for (final wishlist in data.wishlists.values) {
      if (wishlist.shareToken == token) {
        return wishlist;
      }
    }
    return null;
  }

  @override
  Future<int> maxPosition(int ownerId) async {
    final owned = data.wishlists.values.where(
      (item) => item.ownerId == ownerId,
    );
    if (owned.isEmpty) {
      return -1;
    }
    return owned.map((item) => item.position).reduce((a, b) => a > b ? a : b);
  }

  @override
  Future<WishlistModel> insert({
    required int ownerId,
    required String name,
    required String color,
    required WishlistVisibility visibility,
    required int position,
    String? description,
  }) async {
    final wishlist = WishlistModel(
      id: data.nextWishlistId++,
      ownerId: ownerId,
      name: name,
      description: description,
      color: color,
      visibility: visibility,
      position: position,
    );
    data.wishlists[wishlist.id] = wishlist;
    data.items[wishlist.id] = [];
    return wishlist;
  }

  @override
  Future<WishlistModel?> update({
    required int id,
    required int ownerId,
    String? name,
    String? description,
    bool clearDescription = false,
    String? color,
    WishlistVisibility? visibility,
  }) async {
    final current = data.wishlists[id];
    if (current == null || current.ownerId != ownerId) {
      return null;
    }
    final updated = WishlistModel(
      id: current.id,
      ownerId: current.ownerId,
      name: name ?? current.name,
      description: clearDescription
          ? null
          : (description ?? current.description),
      color: color ?? current.color,
      visibility: visibility ?? current.visibility,
      position: current.position,
      shareToken: current.shareToken,
      items: current.items,
    );
    data.wishlists[id] = updated;
    return updated;
  }

  @override
  Future<int> delete({required int id, required int ownerId}) async {
    final current = data.wishlists[id];
    if (current == null || current.ownerId != ownerId) {
      return 0;
    }
    data.wishlists.remove(id);
    data.items.remove(id);
    return 1;
  }

  @override
  Future<int> deleteMany({
    required List<int> ids,
    required int ownerId,
  }) async {
    var deleted = 0;
    for (final id in ids) {
      deleted += await delete(id: id, ownerId: ownerId);
    }
    return deleted;
  }

  @override
  Future<int> countByOwner(int ownerId) async {
    return data.wishlists.values
        .where((item) => item.ownerId == ownerId)
        .length;
  }

  @override
  Future<int> countOwnedWishlists({
    required int ownerId,
    required List<int> ids,
  }) async {
    return ids.where((id) => data.wishlists[id]?.ownerId == ownerId).length;
  }

  @override
  Future<void> reorder({
    required int ownerId,
    required List<int> ids,
  }) async {
    for (var i = 0; i < ids.length; i++) {
      final current = data.wishlists[ids[i]];
      if (current == null || current.ownerId != ownerId) {
        continue;
      }
      data.wishlists[current.id] = _copy(current, position: i);
    }
  }

  @override
  Future<String?> ensureShareToken({
    required int id,
    required int ownerId,
    required String Function() nextToken,
  }) async {
    final current = data.wishlists[id];
    if (current == null || current.ownerId != ownerId) {
      return null;
    }
    if (current.shareToken != null) {
      return current.shareToken;
    }
    for (var attempt = 0; attempt < 8; attempt++) {
      final token = nextToken();
      final taken = data.wishlists.values.any(
        (item) => item.shareToken == token,
      );
      if (taken) {
        continue;
      }
      data.wishlists[id] = _copy(current, shareToken: token);
      return token;
    }
    throw StateError('Could not allocate a share token');
  }

  WishlistModel _copy(
    WishlistModel current, {
    int? position,
    String? shareToken,
  }) {
    return WishlistModel(
      id: current.id,
      ownerId: current.ownerId,
      name: current.name,
      description: current.description,
      color: current.color,
      visibility: current.visibility,
      position: position ?? current.position,
      shareToken: shareToken ?? current.shareToken,
      items: current.items,
      createdAt: current.createdAt,
      updatedAt: current.updatedAt,
    );
  }

  @override
  Future<int> countOwnedWishes({
    required int ownerId,
    required List<int> ids,
  }) async {
    return ids.where((id) => data.wishes[id]?.ownerId == ownerId).length;
  }

  @override
  Future<void> attachWishes({
    required int wishlistId,
    required List<int> wishIds,
  }) async {
    data.items[wishlistId] = [...wishIds];
  }

  @override
  Future<List<WishModel>> listItems(int wishlistId) async {
    final ids = data.items[wishlistId] ?? const <int>[];
    return [
      for (final id in ids)
        if (data.wishes[id] case final wish?) wish,
    ];
  }

  List<int> _itemIds(int wishlistId) => data.items[wishlistId] ?? const <int>[];

  @override
  Future<int> maxItemPosition(int wishlistId) async {
    final ids = _itemIds(wishlistId);
    return ids.isEmpty ? -1 : ids.length - 1;
  }

  @override
  Future<int> itemCount(int wishlistId) async => _itemIds(wishlistId).length;

  @override
  Future<bool> isAttached({
    required int wishlistId,
    required int wishId,
  }) async {
    return _itemIds(wishlistId).contains(wishId);
  }

  @override
  Future<int> countAttached({
    required int wishlistId,
    required List<int> ids,
  }) async {
    final attached = _itemIds(wishlistId).toSet();
    return ids.where(attached.contains).length;
  }

  @override
  Future<int> countPublicAppearances(int wishId) async {
    var count = 0;
    for (final wishlist in data.wishlists.values) {
      if (wishlist.visibility != WishlistVisibility.public) {
        continue;
      }
      if (_itemIds(wishlist.id).contains(wishId)) {
        count++;
      }
    }
    return count;
  }

  @override
  Future<void> attachWish({
    required int wishlistId,
    required int wishId,
    required int position,
  }) async {
    final ids = [..._itemIds(wishlistId)];
    if (position >= ids.length) {
      ids.add(wishId);
    } else {
      ids.insert(position.clamp(0, ids.length), wishId);
    }
    data.items[wishlistId] = ids;
  }

  @override
  Future<int> detachWish({
    required int wishlistId,
    required int wishId,
  }) async {
    final ids = [..._itemIds(wishlistId)];
    final removed = ids.remove(wishId);
    if (!removed) {
      return 0;
    }
    data.items[wishlistId] = ids;
    return 1;
  }

  @override
  Future<void> reorderItems({
    required int wishlistId,
    required List<int> wishIds,
  }) async {
    data.items[wishlistId] = [...wishIds];
  }
}

WishlistService memoryWishlistService(MemoryWishlistData data) {
  return WishlistService(
    db: _UnusedExecutor(),
    transaction: <R>(action) => action(_UnusedExecutor()),
    wishlists: (_) => MemoryWishlistRepository(data),
    wishes: (_) => MemoryWishRepository(data.wishStore),
    users: (_) => MemoryUserRepository(data),
  );
}

WishService memoryWishServiceFromLists(MemoryWishlistData data) {
  return WishService(
    db: _UnusedExecutor(),
    transaction: <R>(action) => action(_UnusedExecutor()),
    wishes: (_) => MemoryWishRepository(data.wishStore),
    users: (_) => MemoryUserRepository(data),
  );
}

ProfileService memoryProfileService(MemoryWishlistData data) {
  return ProfileService(
    db: _UnusedExecutor(),
    users: (_) => MemoryUserRepository(data),
    wishlists: (_) => MemoryWishlistRepository(data),
  );
}

class MemoryFavoriteRepository implements FavoriteRepository {
  MemoryFavoriteRepository(this.data);

  final MemoryWishlistData data;

  List<int> _ids(int userId) => data.favorites[userId] ?? const <int>[];

  @override
  Future<List<WishlistModel>> listWishlists(int userId) async {
    return [
      for (final id in _ids(userId))
        if (data.wishlists[id] case final wishlist?) wishlist,
    ];
  }

  @override
  Future<int> maxPosition(int userId) async {
    final ids = _ids(userId);
    return ids.isEmpty ? -1 : ids.length - 1;
  }

  @override
  Future<int> countByUser(int userId) async => _ids(userId).length;

  @override
  Future<int> countFavorited({
    required int userId,
    required List<int> ids,
  }) async {
    final favorited = _ids(userId).toSet();
    return ids.where(favorited.contains).length;
  }

  @override
  Future<bool> isFavorited({
    required int userId,
    required int wishlistId,
  }) async {
    return _ids(userId).contains(wishlistId);
  }

  @override
  Future<void> insert({
    required int userId,
    required int wishlistId,
    required int position,
  }) async {
    final ids = [..._ids(userId)];
    if (position >= ids.length) {
      ids.add(wishlistId);
    } else {
      ids.insert(position.clamp(0, ids.length), wishlistId);
    }
    data.favorites[userId] = ids;
  }

  @override
  Future<int> delete({
    required int userId,
    required int wishlistId,
  }) async {
    final ids = [..._ids(userId)];
    final removed = ids.remove(wishlistId);
    if (!removed) {
      return 0;
    }
    data.favorites[userId] = ids;
    return 1;
  }

  @override
  Future<void> reorder({
    required int userId,
    required List<int> wishlistIds,
  }) async {
    data.favorites[userId] = [...wishlistIds];
  }
}

FavoriteService memoryFavoriteService(MemoryWishlistData data) {
  return FavoriteService(
    db: _UnusedExecutor(),
    transaction: <R>(action) => action(_UnusedExecutor()),
    favorites: (_) => MemoryFavoriteRepository(data),
    wishlists: (_) => MemoryWishlistRepository(data),
    users: (_) => MemoryUserRepository(data),
  );
}

class MemoryWishlistSubscriptionRepository
    implements WishlistSubscriptionRepository {
  MemoryWishlistSubscriptionRepository(this.data);

  final MemoryWishlistData data;

  List<int> _ids(int userId) => data.wishlistSubs[userId] ?? const <int>[];

  @override
  Future<List<WishlistModel>> listWishlists(int userId) async {
    return [
      for (final id in _ids(userId).reversed)
        if (data.wishlists[id] case final wishlist?
            when wishlist.visibility == WishlistVisibility.public)
          wishlist,
    ];
  }

  @override
  Future<bool> exists({
    required int userId,
    required int wishlistId,
  }) async {
    return _ids(userId).contains(wishlistId);
  }

  @override
  Future<void> insert({
    required int userId,
    required int wishlistId,
  }) async {
    data.wishlistSubs[userId] = [..._ids(userId), wishlistId];
  }

  @override
  Future<int> delete({
    required int userId,
    required int wishlistId,
  }) async {
    final ids = [..._ids(userId)];
    final removed = ids.remove(wishlistId);
    if (!removed) {
      return 0;
    }
    data.wishlistSubs[userId] = ids;
    return 1;
  }
}

class MemoryUserSubscriptionRepository implements UserSubscriptionRepository {
  MemoryUserSubscriptionRepository(this.data);

  final MemoryWishlistData data;

  List<int> _ids(int followerId) => data.userSubs[followerId] ?? const <int>[];

  @override
  Future<List<UserModel>> listUsers(int followerId) async {
    return [
      for (final id in _ids(followerId).reversed)
        if (data.users[id] case final user?) user,
    ];
  }

  @override
  Future<bool> exists({
    required int followerId,
    required int followeeId,
  }) async {
    return _ids(followerId).contains(followeeId);
  }

  @override
  Future<void> insert({
    required int followerId,
    required int followeeId,
  }) async {
    data.userSubs[followerId] = [..._ids(followerId), followeeId];
  }

  @override
  Future<int> delete({
    required int followerId,
    required int followeeId,
  }) async {
    final ids = [..._ids(followerId)];
    final removed = ids.remove(followeeId);
    if (!removed) {
      return 0;
    }
    data.userSubs[followerId] = ids;
    return 1;
  }
}

SubscriptionService memorySubscriptionService(MemoryWishlistData data) {
  return SubscriptionService(
    db: _UnusedExecutor(),
    transaction: <R>(action) => action(_UnusedExecutor()),
    wishlistSubscriptions: (_) => MemoryWishlistSubscriptionRepository(data),
    userSubscriptions: (_) => MemoryUserSubscriptionRepository(data),
    wishlists: (_) => MemoryWishlistRepository(data),
    users: (_) => MemoryUserRepository(data),
  );
}

class _UnusedExecutor extends Fake implements DbExecutor {}
