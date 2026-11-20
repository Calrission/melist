import 'package:melist_core/melist_core.dart';

abstract class IWishRepository {
  Future<WishModel> createWish(CreateWishBody body);
  Future<WishModel> duplicateWishById(int wishId);
  Future<List<WishModel>> getMyWishes({String? query, int? limit, int? offset});
  Future<List<WishModel>> getMyReservations();
  Future<WishModel> getMyWishById(int wishId);
  Future<WishModel> patchWishById(int wishId, PatchWishBody body);
  Future<void> deleteBulkWishesByIds(List<int> ids);
  Future<void> deleteWishById(int wishId);
  Future<WishModel> addWishToWishlist(int wishlistId, AddWishlistWishBody body);
  Future<void> reorderWishesInWishlist(int wishlistId, ReorderIdsBody body);
  Future<void> removeWishFromWishlist(int wishlistId, int wishId);
}
