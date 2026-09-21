import 'package:melist_backend/src/auth/auth_user.dart';
import 'package:melist_backend/src/data/database.dart';
import 'package:melist_backend/src/data/favorite_repository.dart';
import 'package:melist_backend/src/data/user_repository.dart';
import 'package:melist_backend/src/data/wishlist_repository.dart';
import 'package:melist_backend/src/http/app_exception.dart';
import 'package:melist_backend/src/wishlists/wishlist_share.dart';
import 'package:melist_core/melist_core.dart';

class FavoriteService {
  FavoriteService({
    required DbExecutor db,
    Future<R> Function<R>(
      Future<R> Function(DbExecutor tx) action,
    )?
    transaction,
    FavoriteRepository Function(DbExecutor db)? favorites,
    WishlistRepository Function(DbExecutor db)? wishlists,
    UserRepository Function(DbExecutor db)? users,
  }) : _db = db,
       _transaction = transaction ?? (<R>(action) => action(db)),
       _favorites = favorites ?? FavoriteRepository.new,
       _wishlists = wishlists ?? WishlistRepository.new,
       _users = users ?? UserRepository.new;

  factory FavoriteService.fromDatabase(Database database) {
    return FavoriteService(db: database, transaction: database.transaction);
  }

  final DbExecutor _db;
  final Future<R> Function<R>(Future<R> Function(DbExecutor tx) action)
  _transaction;
  final FavoriteRepository Function(DbExecutor db) _favorites;
  final WishlistRepository Function(DbExecutor db) _wishlists;
  final UserRepository Function(DbExecutor db) _users;

  FavoriteRepository get _repo => _favorites(_db);

  Future<List<WishlistModel>> list(AuthUser user) async {
    final lists = await _repo.listWishlists(user.id);
    return [
      for (final list in lists) await _withVisibleItems(list),
    ];
  }

  Future<WishlistModel> add(AuthUser user, String? shareToken) async {
    final parsed = normalizeShareToken(shareToken ?? '');
    if (parsed.isEmpty) {
      throw const BadRequestException('shareToken is required');
    }

    return _transaction((tx) async {
      final wishlists = _wishlists(tx);
      final favorites = _favorites(tx);
      final wishlist = await wishlists.findByShareToken(parsed);
      if (wishlist == null) {
        throw const NotFoundException('Wishlist not found');
      }
      if (wishlist.ownerId == user.id) {
        throw const BadRequestException('Cannot favorite your own wishlist');
      }
      if (wishlist.visibility == WishlistVisibility.draft) {
        throw const NotFoundException('Wishlist not found');
      }
      if (await favorites.isFavorited(
        userId: user.id,
        wishlistId: wishlist.id,
      )) {
        throw const ConflictException('Wishlist is already in favorites');
      }

      await _users(tx).ensure(user);
      final position = await favorites.maxPosition(user.id) + 1;
      await favorites.insert(
        userId: user.id,
        wishlistId: wishlist.id,
        position: position,
      );
      return _withVisibleItems(wishlist, wishlists: wishlists);
    });
  }

  Future<void> reorder(AuthUser user, List<int> order) async {
    final unique = _uniqueIds(order);
    if (unique.length != order.length) {
      throw const BadRequestException('order must not contain duplicates');
    }

    return _transaction((tx) async {
      final favorites = _favorites(tx);
      final total = await favorites.countByUser(user.id);
      final matched = await favorites.countFavorited(
        userId: user.id,
        ids: unique,
      );
      if (total != unique.length || matched != unique.length) {
        throw const BadRequestException(
          'order must list every favorite wishlist',
        );
      }

      await favorites.reorder(userId: user.id, wishlistIds: unique);
    });
  }

  Future<void> remove(AuthUser user, int wishlistId) async {
    final deleted = await _repo.delete(
      userId: user.id,
      wishlistId: wishlistId,
    );
    if (deleted == 0) {
      throw const NotFoundException('Wishlist is not in favorites');
    }
  }

  Future<WishlistModel> _withVisibleItems(
    WishlistModel wishlist, {
    WishlistRepository? wishlists,
  }) async {
    final items = await (wishlists ?? _wishlists(_db)).listItems(wishlist.id);
    return wishlist.copyWith(items: items);
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
