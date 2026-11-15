import 'package:melist/domain/interfaces/i_favorite_repository.dart';
import 'package:melist/presentation/controllers/base_controller.dart';
import 'package:melist_core/melist_core.dart';

class FavoritesWishlistController extends BaseController<List<WishlistModel>> {
  final IFavoriteRepository _repository;
  Future<void>? _loadFuture;

  FavoritesWishlistController({required this._repository});

  List<int>? get currentOrder => data?.map((e) => e.id).toList();

  bool contains(int wishlistId) =>
      data?.any((item) => item.id == wishlistId) ?? false;

  Future<void> loadMyFavoriteWishlists() {
    final currentLoad = _loadFuture;
    if (currentLoad != null) {
      return currentLoad;
    }

    final load = _loadMyFavoriteWishlists();
    _loadFuture = load;
    return load.whenComplete(() => _loadFuture = null);
  }

  Future<void> _loadMyFavoriteWishlists() async {
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

  Future<void> addWishlistToFavorites(AddFavoriteBody body) async {
    final wishlist = await _repository.addWishlistToFavorites(body);
    final wishlists = data ?? const <WishlistModel>[];
    if (!wishlists.any((item) => item.id == wishlist.id)) {
      data = [...wishlists, wishlist];
    }
    await refreshMyFavoriteWishlists();
  }

  Future<void> deleteFavoriteById(int wishlistId) async {
    await _repository.deleteFavoriteById(wishlistId);
    if (data != null) {
      data = data!.where((item) => item.id != wishlistId).toList();
    }
  }

  Future<void> deleteFavoriteWithoutUpdating(int wishlistId) async {
    await _repository.deleteFavoriteById(wishlistId);
  }

  Future<void> reorderFavorites(List<int> order) async {
    if (state != ControllerState.loaded || data == null) {
      return;
    }
    final next = [...data!]
      ..sort((a, b) => order.indexOf(a.id) - order.indexOf(b.id));
    data = next;
    try {
      await _repository.reorderFavorites(ReorderIdsBody(order: order));
    } on Object catch (e) {
      error = e;
    }
  }
}
