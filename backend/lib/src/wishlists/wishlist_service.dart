import 'package:melist_backend/src/auth/auth_user.dart';
import 'package:melist_backend/src/data/database.dart';
import 'package:melist_backend/src/data/user_repository.dart';
import 'package:melist_backend/src/data/wishlist_repository.dart';
import 'package:melist_backend/src/http/app_exception.dart';
import 'package:melist_backend/src/wishlists/wishlist_palette.dart';
import 'package:melist_core/melist_core.dart';

class WishlistService {
  WishlistService({
    required DbExecutor db,
    Future<R> Function<R>(
      Future<R> Function(DbExecutor tx) action,
    )?
    transaction,
    WishlistRepository Function(DbExecutor db)? wishlists,
    UserRepository Function(DbExecutor db)? users,
  }) : _db = db,
       _transaction = transaction ?? (<R>(action) => action(db)),
       _wishlists = wishlists ?? WishlistRepository.new,
       _users = users ?? UserRepository.new;

  factory WishlistService.fromDatabase(Database database) {
    return WishlistService(db: database, transaction: database.transaction);
  }

  final DbExecutor _db;
  final Future<R> Function<R>(Future<R> Function(DbExecutor tx) action)
  _transaction;
  final WishlistRepository Function(DbExecutor db) _wishlists;
  final UserRepository Function(DbExecutor db) _users;

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

  Future<WishlistModel> _requireOwned(int ownerId, int id) async {
    final wishlist = await _repo.findById(id);
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
