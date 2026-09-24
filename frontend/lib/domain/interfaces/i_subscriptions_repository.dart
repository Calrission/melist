import 'package:melist_core/melist_core.dart';

abstract class ISubscriptionsRepository {
  Future<UserModel> subscribeToProfile(SubscribeUserBody body);
  Future<WishlistModel> subscribeToWishlist(SubscribeWishlistBody body);
  Future<List<UserModel>> getMyProfileSubscriptions();
  Future<List<WishlistModel>> getMyWishlistSubscriptions();
  Future<void> unsubscribeProfile(int userId);
  Future<void> unsubscribeWishlist(int wishlistId);
}
