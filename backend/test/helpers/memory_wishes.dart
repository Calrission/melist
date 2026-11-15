import 'package:melist_backend/melist_backend.dart';
import 'package:melist_core/melist_core.dart';
import 'package:mocktail/mocktail.dart';

class MemoryWishData {
  final userIds = <int>{};
  final wishes = <int, WishModel>{};
  int nextWishId = 1;
}

class MemoryWishUserRepository implements UserRepository {
  MemoryWishUserRepository(this.data);

  final MemoryWishData data;

  @override
  Future<void> ensure(AuthUser user) async {
    data.userIds.add(user.id);
  }

  @override
  Future<void> upsertTelegram(UserModel user) async {
    data.userIds.add(user.id);
  }

  @override
  Future<UserModel?> findById(int id) async => null;

  @override
  Future<UserModel?> update({
    required int id,
    DateTime? birthday,
    bool clearBirthday = false,
    String? nickname,
    bool clearNickname = false,
    UiTheme? theme,
  }) async {
    return null;
  }
}

class MemoryWishRepository implements WishRepository {
  MemoryWishRepository(this.data);

  final MemoryWishData data;

  @override
  Future<List<WishModel>> listByOwner({
    required int ownerId,
    required int limit,
    required int offset,
    String? query,
  }) async {
    var items =
        data.wishes.values.where((item) => item.ownerId == ownerId).toList()
          ..sort((a, b) => b.id.compareTo(a.id));
    if (query != null && query.isNotEmpty) {
      final needle = query.replaceAll('!', '').toLowerCase();
      items = [
        for (final item in items)
          if (item.name.toLowerCase().contains(needle)) item,
      ];
    }
    final start = offset.clamp(0, items.length);
    final end = (start + limit).clamp(0, items.length);
    return items.sublist(start, end);
  }

  @override
  Future<WishModel?> findById(int id) async => data.wishes[id];

  @override
  Future<WishModel> insert({
    required int ownerId,
    required String name,
    required WishStatus status,
    double? price,
    String? url,
    String? description,
    String? coverUrl,
    int? copiedFrom,
  }) async {
    final wish = WishModel(
      id: data.nextWishId++,
      ownerId: ownerId,
      name: name,
      price: price,
      url: url,
      description: description,
      coverUrl: coverUrl,
      status: status,
      copiedFrom: copiedFrom,
    );
    data.wishes[wish.id] = wish;
    return wish;
  }

  @override
  Future<WishModel?> update({
    required int id,
    required int ownerId,
    String? name,
    double? price,
    bool clearPrice = false,
    String? url,
    bool clearUrl = false,
    String? description,
    bool clearDescription = false,
    String? coverUrl,
    bool clearCoverUrl = false,
    WishStatus? status,
  }) async {
    final current = data.wishes[id];
    if (current == null || current.ownerId != ownerId) {
      return null;
    }
    final updated = WishModel(
      id: current.id,
      ownerId: current.ownerId,
      name: name ?? current.name,
      price: clearPrice ? null : (price ?? current.price),
      url: clearUrl ? null : (url ?? current.url),
      description: clearDescription
          ? null
          : (description ?? current.description),
      coverUrl: clearCoverUrl ? null : (coverUrl ?? current.coverUrl),
      status: status ?? current.status,
      copiedFrom: current.copiedFrom,
      createdAt: current.createdAt,
      updatedAt: current.updatedAt,
    );
    data.wishes[id] = updated;
    return updated;
  }

  @override
  Future<int> delete({required int id, required int ownerId}) async {
    final current = data.wishes[id];
    if (current == null || current.ownerId != ownerId) {
      return 0;
    }
    data.wishes.remove(id);
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
  Future<WishModel?> duplicate({
    required int id,
    required int ownerId,
  }) async {
    final current = data.wishes[id];
    if (current == null || current.ownerId != ownerId) {
      return null;
    }
    return insert(
      ownerId: current.ownerId,
      name: current.name,
      status: current.status,
      price: current.price,
      url: current.url,
      description: current.description,
      coverUrl: current.coverUrl,
      copiedFrom: current.id,
    );
  }
}

WishService memoryWishService(MemoryWishData data) {
  return WishService(
    db: _UnusedExecutor(),
    transaction: <R>(action) => action(_UnusedExecutor()),
    wishes: (_) => MemoryWishRepository(data),
    users: (_) => MemoryWishUserRepository(data),
  );
}

class _UnusedExecutor extends Fake implements DbExecutor {}
