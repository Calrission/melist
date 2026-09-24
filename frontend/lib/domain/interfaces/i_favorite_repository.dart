import 'package:melist_core/melist_core.dart';

abstract class IFavoriteRepository {
  Future<WishlistModel> addWishlistToFavorites(AddFavoriteBody body);
  Future<List<WishlistModel>> getMyFavoriteWishlists();
  Future<void> reorderFavorites(ReorderIdsBody body);
  Future<void> deleteFavoriteById(int wishlistId);
}
