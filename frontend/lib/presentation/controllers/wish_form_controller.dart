import 'package:melist/domain/interfaces/i_wish_repository.dart';
import 'package:melist/presentation/controllers/base_controller.dart';
import 'package:melist/presentation/controllers/wishes_controller.dart';
import 'package:melist/presentation/controllers/wishlist_controller.dart';
import 'package:melist/presentation/controllers/wishlist_list_controller.dart';
import 'package:melist_core/melist_core.dart';

class WishFormController extends BaseController<WishModel> {
  WishFormController({
    required this._repository,
    required this._wishlists,
    required this._wishlist,
    this._wishes,
  });

  final IWishRepository _repository;
  final WishlistListController _wishlists;
  final WishlistController _wishlist;
  final WishesController? _wishes;

  Future<WishModel?> loadById(int wishId) async {
    emit(ControllerState.loading);
    try {
      final model = await _repository.getMyWishById(wishId);
      data = model;
      return model;
    } on Object catch (e) {
      error = e;
      return null;
    }
  }

  Future<bool> create(CreateWishBody body, [int? wishlistId]) async {
    emit(ControllerState.loading);
    try {
      final created = await _repository.createWish(body);
      if (wishlistId == null) {
        data = created;
        await _wishes?.refresh();
        return true;
      }
      data = await _repository.addWishToWishlist(
        wishlistId,
        AddWishlistWishBody.attach(created.id),
      );
      await _syncWishlist(wishlistId);
      await _wishes?.refresh();
      return true;
    } on Object catch (e) {
      error = e;
      return false;
    }
  }

  Future<bool> update(int wishId, PatchWishBody body) async {
    emit(ControllerState.loading);
    try {
      final updatedWish = await _repository.patchWishById(wishId, body);
      data = updatedWish;
      _wishlist.updateWish(updatedWish);
      await _wishlists.refreshMyWishlist();
      await _wishes?.refresh();
      return true;
    } on Object catch (e) {
      error = e;
      return false;
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
