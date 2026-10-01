import 'package:melist/domain/interfaces/i_wish_repository.dart';
import 'package:melist/presentation/controllers/base_controller.dart';
import 'package:melist/presentation/controllers/wishlist_controller.dart';
import 'package:melist/presentation/controllers/wishlist_list_controller.dart';
import 'package:melist_core/melist_core.dart';

class WishFormController extends BaseController<WishModel> {
  WishFormController({
    required this._repository,
    required this._wishlists,
    required this._wishlist,
  });

  final IWishRepository _repository;
  final WishlistListController _wishlists;
  final WishlistController _wishlist;

  Future<void> loadById(int wishId) async {
    emit(ControllerState.loading);
    try {
      data = await _repository.getMyWishById(wishId);
    } on Object catch (e) {
      error = e;
    }
  }

  Future<bool> create(CreateWishBody body, [int? wishlistId]) async {
    emit(ControllerState.loading);
    try {
      final created = await _repository.createWish(body);
      if (wishlistId == null) {
        data = created;
        return true;
      }
      data = await _repository.addWishToWishlist(
        wishlistId,
        AddWishlistWishBody.attach(created.id),
      );
      await _syncWishlist(wishlistId);
      return true;
    } on Object catch (e) {
      error = e;
      return false;
    }
  }

  Future<void> update(int wishId, PatchWishBody body) async {
    emit(ControllerState.loading);
    try {
      data = await _repository.patchWishById(wishId, body);
    } on Object catch (e) {
      error = e;
    }
  }

  Future<void> _syncWishlist(int wishlistId) async {
    final refreshed = await _wishlists.refreshMyWishlist();
    if (refreshed) {
      final updated = _wishlists.data
          ?.where((item) => item.id == wishlistId)
          .firstOrNull;
      if (updated != null) {
        _wishlist.show(updated);
        return;
      }
    }
    await _wishlist.loadById(wishlistId);
  }
}
