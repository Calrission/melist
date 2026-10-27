import 'package:melist_backend/src/auth/auth_user.dart';
import 'package:melist_backend/src/data/database.dart';
import 'package:melist_backend/src/data/user_repository.dart';
import 'package:melist_backend/src/data/user_subscription_repository.dart';
import 'package:melist_backend/src/data/wishlist_repository.dart';
import 'package:melist_backend/src/data/wishlist_subscription_repository.dart';
import 'package:melist_backend/src/http/app_exception.dart';
import 'package:melist_core/melist_core.dart';

class SubscriptionService {
  SubscriptionService({
    required DbExecutor db,
    Future<R> Function<R>(
      Future<R> Function(DbExecutor tx) action,
    )?
    transaction,
    WishlistSubscriptionRepository Function(DbExecutor db)?
    wishlistSubscriptions,
    UserSubscriptionRepository Function(DbExecutor db)? userSubscriptions,
    WishlistRepository Function(DbExecutor db)? wishlists,
    UserRepository Function(DbExecutor db)? users,
  }) : _db = db,
       _transaction = transaction ?? (<R>(action) => action(db)),
       _wishlistSubscriptions =
           wishlistSubscriptions ?? WishlistSubscriptionRepository.new,
       _userSubscriptions = userSubscriptions ?? UserSubscriptionRepository.new,
       _wishlists = wishlists ?? WishlistRepository.new,
       _users = users ?? UserRepository.new;

  factory SubscriptionService.fromDatabase(Database database) {
    return SubscriptionService(
      db: database,
      transaction: database.transaction,
    );
  }

  final DbExecutor _db;
  final Future<R> Function<R>(Future<R> Function(DbExecutor tx) action)
  _transaction;
  final WishlistSubscriptionRepository Function(DbExecutor db)
  _wishlistSubscriptions;
  final UserSubscriptionRepository Function(DbExecutor db) _userSubscriptions;
  final WishlistRepository Function(DbExecutor db) _wishlists;
  final UserRepository Function(DbExecutor db) _users;

  Future<List<WishlistModel>> listWishlists(AuthUser user) async {
    final lists = await _wishlistSubscriptions(_db).listWishlists(user.id);
    if (lists.isEmpty) {
      return lists;
    }
    final itemsByList = await _wishlists(_db).listItemsFor([
      for (final list in lists) list.id,
    ]);
    return [
      for (final list in lists)
        list.copyWith(items: itemsByList[list.id] ?? const []),
    ];
  }

  Future<WishlistModel> subscribeWishlist(
    AuthUser user,
    int? wishlistId,
  ) async {
    if (wishlistId == null) {
      throw const BadRequestException('wishlistId is required');
    }

    return _transaction((tx) async {
      final wishlist = await _wishlists(tx).findById(wishlistId);
      if (wishlist == null ||
          wishlist.visibility != WishlistVisibility.public) {
        throw const NotFoundException('Wishlist not found');
      }
      if (wishlist.ownerId == user.id) {
        throw const BadRequestException(
          'Cannot subscribe to your own wishlist',
        );
      }

      final subscriptions = _wishlistSubscriptions(tx);
      if (await subscriptions.exists(
        userId: user.id,
        wishlistId: wishlist.id,
      )) {
        throw const ConflictException('Already subscribed to this wishlist');
      }

      await _users(tx).ensure(user);
      await subscriptions.insert(userId: user.id, wishlistId: wishlist.id);
      final items = await _wishlists(tx).listItems(wishlist.id);
      return wishlist.copyWith(items: items);
    });
  }

  Future<void> unsubscribeWishlist(AuthUser user, int wishlistId) async {
    final deleted = await _wishlistSubscriptions(_db).delete(
      userId: user.id,
      wishlistId: wishlistId,
    );
    if (deleted == 0) {
      throw const NotFoundException('Wishlist subscription not found');
    }
  }

  Future<List<UserModel>> listUsers(AuthUser user) {
    return _userSubscriptions(_db).listUsers(user.id);
  }

  Future<UserModel> subscribeUser(AuthUser user, int? userId) async {
    if (userId == null) {
      throw const BadRequestException('userId is required');
    }
    if (userId == user.id) {
      throw const BadRequestException('Cannot subscribe to yourself');
    }

    return _transaction((tx) async {
      final users = _users(tx);
      final followee = await users.findById(userId);
      if (followee == null) {
        throw const NotFoundException('User not found');
      }

      final subscriptions = _userSubscriptions(tx);
      if (await subscriptions.exists(
        followerId: user.id,
        followeeId: followee.id,
      )) {
        throw const ConflictException('Already subscribed to this user');
      }

      await users.ensure(user);
      await subscriptions.insert(
        followerId: user.id,
        followeeId: followee.id,
      );
      return followee;
    });
  }

  Future<void> unsubscribeUser(AuthUser user, int userId) async {
    final deleted = await _userSubscriptions(_db).delete(
      followerId: user.id,
      followeeId: userId,
    );
    if (deleted == 0) {
      throw const NotFoundException('User subscription not found');
    }
  }
}
