import 'package:melist/domain/interfaces/i_favorite_repository.dart';
import 'package:melist/presentation/controllers/base_controller.dart';
import 'package:melist_core/melist_core.dart';

class FavoritesWishlistController extends BaseController<List<WishlistModel>> {
  final IFavoriteRepository _repository;

  FavoritesWishlistController({required this._repository});

  Future<void> loadMyFavoriteWishlists() async {
    emit(ControllerState.loading);
    try {
      data = await _repository.getMyFavoriteWishlists();
    } on Object catch (e) {
      error = e;
    }
  }

  Future<bool> refreshMyFavoriteWishlists() async {
    try {
      data = await _repository.getMyFavoriteWishlists();
      return true;
    } on Object catch (e) {
      setError(e, silence: true, changeState: false);
      return false;
    }
  }

  Future<bool> addWishlistToFavorites(AddFavoriteBody body) async {
    try {
      final wishlist = await _repository.addWishlistToFavorites(body);
      final wishlists = data ?? const <WishlistModel>[];
      if (wishlists.any((item) => item.id == wishlist.id)) {
        data = wishlists;
      } else {
        data = [...wishlists, wishlist];
      }
      return true;
    } on Object catch (e) {
      error = e;
      return false;
    }
  }

  Future<void> deleteFavoriteById(int wishlistId) async {
    try {
      await _repository.deleteFavoriteById(wishlistId);
      if (data != null) {
        data = data!.where((item) => item.id != wishlistId).toList();
      }
    } on Object catch (e) {
      error = e;
    }
  }

  Future<void> reorderFavorites(List<int> order) async {
    if (state != ControllerState.loaded || data == null) {
      return;
    }
    try {
      await _repository.reorderFavorites(ReorderIdsBody(order: order));
      final next = [...data!]
        ..sort((a, b) => order.indexOf(a.id) - order.indexOf(b.id));
      data = next;
    } on Object catch (e) {
      error = e;
    }
  }
}
