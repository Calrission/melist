import 'package:melist_backend/melist_backend.dart';
import 'package:melist_core/melist_core.dart';
import 'package:mocktail/mocktail.dart';

class MemoryWishlistData {
  final userIds = <int>{};
  final wishlists = <int, WishlistModel>{};
  final wishes = <int, WishModel>{};
  final items = <int, List<int>>{};
  int nextWishlistId = 1;
}

class MemoryUserRepository implements UserRepository {
  MemoryUserRepository(this.data);

  final MemoryWishlistData data;

  @override
  Future<void> ensure(AuthUser user) async {
    data.userIds.add(user.id);
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
  Future<WishlistModel?> findById(int id) async => data.wishlists[id];

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
  Future<int> countOwnedWishes({
    required int ownerId,
    required List<int> ids,
  }) async {
    return ids
        .where((id) => data.wishes[id]?.ownerId == ownerId)
        .length;
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
}

WishlistService memoryWishlistService(MemoryWishlistData data) {
  return WishlistService(
    db: _UnusedExecutor(),
    transaction: <R>(action) => action(_UnusedExecutor()),
    wishlists: (_) => MemoryWishlistRepository(data),
    users: (_) => MemoryUserRepository(data),
  );
}

class _UnusedExecutor extends Fake implements DbExecutor {}
