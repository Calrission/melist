import 'package:melist_core/melist_core.dart';

abstract class IWishlistRepository {
  Future<WishlistModel> createWishlist(CreateWishlistBody body);
  Future<List<WishlistModel>> getMyWishlists();
  Future<WishlistModel> getMyWishlistById(int wishlistId);
  Future<WishlistModel> patchWishlistById(
    int wishlistId,
    PatchWishlistBody body,
  );
  Future<void> reorderWishlists(ReorderIdsBody body);
  Future<void> deleteBulkWishlistsByIds(List<int> ids);
  Future<void> deleteWishlistById(int wishlistId);
  Future<WishlistShareModel> shareWishlist(int wishlistId);
  Future<WishlistModel> getSharedWishlist(String token);
  Future<WishModel> reserveSharedWish(String token, int wishId);
  Future<WishModel> cancelSharedWishReservation(String token, int wishId);
}
