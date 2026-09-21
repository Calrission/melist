import 'package:melist_backend/src/auth/auth_user.dart';
import 'package:melist_backend/src/data/database.dart';
import 'package:melist_backend/src/data/user_repository.dart';
import 'package:melist_backend/src/data/wish_repository.dart';
import 'package:melist_backend/src/data/wishlist_repository.dart';
import 'package:melist_backend/src/http/app_exception.dart';
import 'package:melist_backend/src/http/parse.dart';
import 'package:melist_backend/src/wishes/wish_service.dart';
import 'package:melist_backend/src/wishlists/wishlist_palette.dart';
import 'package:melist_backend/src/wishlists/wishlist_share.dart';
import 'package:melist_core/melist_core.dart';

class WishlistService {
  WishlistService({
    required DbExecutor db,
    Future<R> Function<R>(
      Future<R> Function(DbExecutor tx) action,
    )?
    transaction,
    WishlistRepository Function(DbExecutor db)? wishlists,
    WishRepository Function(DbExecutor db)? wishes,
    UserRepository Function(DbExecutor db)? users,
    String Function()? newShareToken,
  }) : _db = db,
       _transaction = transaction ?? (<R>(action) => action(db)),
       _wishlists = wishlists ?? WishlistRepository.new,
       _wishes = wishes ?? WishRepository.new,
       _users = users ?? UserRepository.new,
       _newShareToken = newShareToken ?? generateShareToken;

  factory WishlistService.fromDatabase(Database database) {
    return WishlistService(db: database, transaction: database.transaction);
  }

  final DbExecutor _db;
  final Future<R> Function<R>(Future<R> Function(DbExecutor tx) action)
  _transaction;
  final WishlistRepository Function(DbExecutor db) _wishlists;
  final WishRepository Function(DbExecutor db) _wishes;
  final UserRepository Function(DbExecutor db) _users;
  final String Function() _newShareToken;

  WishlistRepository get _repo => _wishlists(_db);

  Future<List<WishlistModel>> listMine(AuthUser user) {
    return _repo.listByOwner(user.id);
  }

  Future<WishlistModel> getById(AuthUser user, int id) async {
    final wishlist = await _requireOwned(user.id, id);
    final items = await _repo.listItems(id);
    return wishlist.copyWith(items: items);
  }

  Future<WishlistModel> create(
    AuthUser user, {
    required String name,
    String? description,
    String? color,
    String? visibility,
    List<int> wishIds = const [],
  }) {
    final parsedName = _requireName(name);
    final parsedColor = _colorOrDefault(color);
    final parsedVisibility = _visibility(visibility);
    final uniqueWishIds = _uniqueIds(wishIds);
    final parsedDescription = _optionalText(description);

    return _transaction((tx) async {
      final users = _users(tx);
      final wishlists = _wishlists(tx);
      await users.ensure(user);

      if (uniqueWishIds.isNotEmpty) {
        final owned = await wishlists.countOwnedWishes(
          ownerId: user.id,
          ids: uniqueWishIds,
        );
        if (owned != uniqueWishIds.length) {
          throw const BadRequestException(
            'wishIds must refer to your own wishes',
          );
        }
      }

      final position = await wishlists.maxPosition(user.id) + 1;
      final created = await wishlists.insert(
        ownerId: user.id,
        name: parsedName,
        description: parsedDescription,
        color: parsedColor,
        visibility: parsedVisibility,
        position: position,
      );

      if (uniqueWishIds.isNotEmpty) {
        await wishlists.attachWishes(
          wishlistId: created.id,
          wishIds: uniqueWishIds,
        );
      }

      if (uniqueWishIds.isEmpty) {
        return created;
      }
      final items = await wishlists.listItems(created.id);
      return created.copyWith(items: items);
    });
  }

  Future<WishlistModel> update(
    AuthUser user,
    int id, {
    String? name,
    Object? description = unsetDescription,
    String? color,
    String? visibility,
  }) async {
    final hasDescription = !identical(description, unsetDescription);
    if (name == null &&
        !hasDescription &&
        color == null &&
        visibility == null) {
      throw const BadRequestException('No fields to update');
    }

    final parsedName = name == null ? null : _requireName(name);
    final parsedColor = color == null ? null : _requireColor(color);
    final parsedVisibility = visibility == null
        ? null
        : _visibility(visibility, required: true);

    String? parsedDescription;
    var clearDescription = false;
    if (hasDescription) {
      if (description == null) {
        clearDescription = true;
      } else if (description is String) {
        final trimmed = description.trim();
        if (trimmed.isEmpty) {
          clearDescription = true;
        } else {
          parsedDescription = trimmed;
        }
      } else {
        throw const BadRequestException('description must be a string or null');
      }
    }

    final updated = await _repo.update(
      id: id,
      ownerId: user.id,
      name: parsedName,
      description: parsedDescription,
      clearDescription: clearDescription,
      color: parsedColor,
      visibility: parsedVisibility,
    );
    if (updated != null) {
      return updated;
    }
    await _requireOwned(user.id, id);
    throw const NotFoundException();
  }

  Future<void> deleteOne(AuthUser user, int id) async {
    final deleted = await _repo.delete(id: id, ownerId: user.id);
    if (deleted > 0) {
      return;
    }
    await _requireOwned(user.id, id);
  }

  Future<void> deleteMany(AuthUser user, List<int> ids) async {
    final unique = _uniqueIds(ids);
    if (unique.isEmpty) {
      throw const BadRequestException('ids must not be empty');
    }

    final deleted = await _repo.deleteMany(ids: unique, ownerId: user.id);
    if (deleted != unique.length) {
      throw const NotFoundException('Some wishlists were not found');
    }
  }

  Future<void> reorder(AuthUser user, List<int> order) async {
    final unique = _uniqueIds(order);
    if (unique.length != order.length) {
      throw const BadRequestException('order must not contain duplicates');
    }

    return _transaction((tx) async {
      final lists = _wishlists(tx);
      final total = await lists.countByOwner(user.id);
      final owned = await lists.countOwnedWishlists(
        ownerId: user.id,
        ids: unique,
      );
      if (total != unique.length || owned != unique.length) {
        throw const BadRequestException(
          'order must list every wishlist',
        );
      }

      await lists.reorder(ownerId: user.id, ids: unique);
    });
  }

  Future<String> share(AuthUser user, int id) async {
    await _requireOwned(user.id, id);
    final token = await _repo.ensureShareToken(
      id: id,
      ownerId: user.id,
      nextToken: _newShareToken,
    );
    if (token == null) {
      throw const NotFoundException('Wishlist not found');
    }
    return token;
  }

  Future<WishlistModel> getShared(AuthUser user, String token) async {
    final parsed = normalizeShareToken(token);
    if (parsed.isEmpty) {
      throw const NotFoundException('Wishlist not found');
    }

    final wishlist = await _repo.findByShareToken(parsed);
    if (wishlist == null) {
      throw const NotFoundException('Wishlist not found');
    }

    var items = await _repo.listItems(wishlist.id);
    if (wishlist.ownerId != user.id) {
      items = [
        for (final item in items)
          if (item.visibility != WishVisibility.private) item,
      ];
    }
    return wishlist.copyWith(items: items);
  }

  Future<WishModel> addWish(
    AuthUser user,
    int wishlistId, {
    Map<String, dynamic>? wish,
    int? wishId,
    int? copyFromWishId,
  }) async {
    final variants = [
      if (wish != null) 'wish',
      if (wishId != null) 'wishId',
      if (copyFromWishId != null) 'copyFromWishId',
    ];
    if (variants.length != 1) {
      throw const BadRequestException(
        'Provide exactly one of wish, wishId or copyFromWishId',
      );
    }

    return _transaction((tx) async {
      final lists = _wishlists(tx);
      await _owned(lists, user.id, wishlistId);

      if (wish != null) {
        return _addNewWish(tx, user, lists, wishlistId, wish);
      }
      if (wishId != null) {
        return _attachOwnWish(tx, user, lists, wishlistId, wishId);
      }
      return _copyForeignWish(tx, user, lists, wishlistId, copyFromWishId!);
    });
  }

  Future<void> reorderWishes(
    AuthUser user,
    int wishlistId,
    List<int> order,
  ) async {
    final unique = _uniqueIds(order);
    if (unique.length != order.length) {
      throw const BadRequestException('order must not contain duplicates');
    }

    return _transaction((tx) async {
      final lists = _wishlists(tx);
      await _owned(lists, user.id, wishlistId);

      final total = await lists.itemCount(wishlistId);
      final attached = await lists.countAttached(
        wishlistId: wishlistId,
        ids: unique,
      );
      if (total != unique.length || attached != unique.length) {
        throw const BadRequestException(
          'order must list every wish in the wishlist',
        );
      }

      await lists.reorderItems(wishlistId: wishlistId, wishIds: unique);
    });
  }

  Future<void> removeWish(AuthUser user, int wishlistId, int wishId) async {
    await _requireOwned(user.id, wishlistId);
    final deleted = await _repo.detachWish(
      wishlistId: wishlistId,
      wishId: wishId,
    );
    if (deleted == 0) {
      throw const NotFoundException('Wish is not in the wishlist');
    }
  }

  Future<WishModel> _addNewWish(
    DbExecutor tx,
    AuthUser user,
    WishlistRepository lists,
    int wishlistId,
    Map<String, dynamic> wish,
  ) async {
    final name = wish['name'];
    if (name is! String) {
      throw const BadRequestException('name is required');
    }

    final created = await _wishService(tx).create(
      user,
      name: name,
      price: optionalJsonNumber(wish['price'], 'price'),
      url: optionalJsonString(wish['url'], 'url'),
      description: optionalJsonString(wish['description'], 'description'),
      coverUrl: optionalJsonString(wish['coverUrl'], 'coverUrl'),
      visibility: optionalJsonString(wish['visibility'], 'visibility'),
      status: optionalJsonString(wish['status'], 'status'),
    );
    await _append(lists, wishlistId, created.id);
    return created;
  }

  Future<WishModel> _attachOwnWish(
    DbExecutor tx,
    AuthUser user,
    WishlistRepository lists,
    int wishlistId,
    int wishId,
  ) async {
    final owned = await lists.countOwnedWishes(
      ownerId: user.id,
      ids: [wishId],
    );
    if (owned != 1) {
      final existing = await _wishes(tx).findById(wishId);
      if (existing == null) {
        throw const NotFoundException('Wish not found');
      }
      throw const BadRequestException('wishId must refer to your own wish');
    }

    await _append(lists, wishlistId, wishId);
    return (await _wishes(tx).findById(wishId))!;
  }

  Future<WishModel> _copyForeignWish(
    DbExecutor tx,
    AuthUser user,
    WishlistRepository lists,
    int wishlistId,
    int copyFromWishId,
  ) async {
    final source = await _wishes(tx).findById(copyFromWishId);
    if (source == null) {
      throw const NotFoundException('Wish not found');
    }
    if (source.ownerId != user.id) {
      if (source.visibility == WishVisibility.private) {
        throw const ForbiddenException();
      }
      final appearances = await lists.countPublicAppearances(copyFromWishId);
      if (appearances == 0) {
        throw const ForbiddenException();
      }
    }

    await _users(tx).ensure(user);
    final copy = await _wishes(tx).insert(
      ownerId: user.id,
      name: source.name,
      price: source.price,
      url: source.url,
      description: source.description,
      coverUrl: source.coverUrl,
      visibility: source.visibility,
      status: source.status,
      copiedFrom: source.id,
    );
    await _append(lists, wishlistId, copy.id);
    return copy;
  }

  Future<void> _append(
    WishlistRepository lists,
    int wishlistId,
    int wishId,
  ) async {
    if (await lists.isAttached(wishlistId: wishlistId, wishId: wishId)) {
      throw const ConflictException('Wish is already in the wishlist');
    }
    final position = await lists.maxItemPosition(wishlistId) + 1;
    await lists.attachWish(
      wishlistId: wishlistId,
      wishId: wishId,
      position: position,
    );
  }

  WishService _wishService(DbExecutor db) {
    return WishService(
      db: db,
      transaction: <R>(action) => action(db),
      wishes: _wishes,
      users: _users,
    );
  }

  Future<WishlistModel> _requireOwned(int ownerId, int id) {
    return _owned(_repo, ownerId, id);
  }

  Future<WishlistModel> _owned(
    WishlistRepository lists,
    int ownerId,
    int id,
  ) async {
    final wishlist = await lists.findById(id);
    if (wishlist == null) {
      throw const NotFoundException('Wishlist not found');
    }
    if (wishlist.ownerId != ownerId) {
      throw const ForbiddenException();
    }
    return wishlist;
  }

  static const unsetDescription = Object();
  static const _maxNameLength = 100;

  String? _optionalText(String? raw) {
    final value = raw?.trim();
    if (value == null || value.isEmpty) {
      return null;
    }
    return value;
  }

  String _requireName(String raw) {
    final name = raw.trim();
    if (name.isEmpty) {
      throw const BadRequestException('name is required');
    }
    if (name.length > _maxNameLength) {
      throw const BadRequestException('name is too long');
    }
    return name;
  }

  String _colorOrDefault(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return defaultWishlistColor;
    }
    return _requireColor(raw);
  }

  String _requireColor(String raw) {
    final color = normalizeWishlistColor(raw);
    if (color == null) {
      throw const BadRequestException('color is not in the palette');
    }
    return color;
  }

  WishlistVisibility _visibility(String? raw, {bool required = false}) {
    if (raw == null || raw.trim().isEmpty) {
      if (required) {
        throw const BadRequestException('visibility is required');
      }
      return WishlistVisibility.draft;
    }
    try {
      return WishlistVisibility.fromName(raw.trim());
    } on FormatException {
      throw const BadRequestException(
        'visibility must be public or draft',
      );
    }
  }

  List<int> _uniqueIds(List<int> ids) {
    final seen = <int>{};
    final unique = <int>[];
    for (final id in ids) {
      if (seen.add(id)) {
        unique.add(id);
      }
    }
    return unique;
  }
}
