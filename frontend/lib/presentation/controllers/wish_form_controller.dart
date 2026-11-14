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

  Future<bool> create(CreateWishBody body, Set<int> wishlistIds) async {
    emit(ControllerState.loading);
    try {
      final created = await _repository.createWish(body);
      data = created;
      for (final wishlistId in wishlistIds) {
        await _repository.addWishToWishlist(
          wishlistId,
          AddWishlistWishBody.attach(created.id),
        );
      }
      await _refreshWishlists();
      await _wishes?.refresh();
      return true;
    } on Object catch (e) {
      error = e;
      return false;
    }
  }

  Future<bool> update(
    int wishId,
    PatchWishBody body,
    Set<int> selectedWishlistIds,
  ) async {
    emit(ControllerState.loading);
    try {
      final updatedWish = await _repository.patchWishById(wishId, body);
      data = updatedWish;
      final currentWishlistIds = (_wishlists.data ?? const <WishlistModel>[])
          .where((wishlist) => wishlist.items.any((item) => item.id == wishId))
          .map((wishlist) => wishlist.id)
          .toSet();
      for (final wishlistId in currentWishlistIds.difference(
        selectedWishlistIds,
      )) {
        await _repository.removeWishFromWishlist(wishlistId, wishId);
      }
      for (final wishlistId in selectedWishlistIds.difference(
        currentWishlistIds,
      )) {
        await _repository.addWishToWishlist(
          wishlistId,
          AddWishlistWishBody.attach(wishId),
        );
      }
      _wishlist.updateWish(updatedWish);
      await _refreshWishlists();
      await _wishes?.refresh();
      return true;
    } on Object catch (e) {
      error = e;
      return false;
    }
  }

  Future<void> _refreshWishlists() async {
    final refreshed = await _wishlists.refreshMyWishlist();
    if (refreshed) {
      final activeId = _wishlist.data?.id;
      final updated = _wishlists.data
          ?.where((item) => item.id == activeId)
          .firstOrNull;
      if (updated != null) {
        _wishlist.show(updated);
        return;
      }
    }
    final activeId = _wishlist.data?.id;
    if (activeId != null) {
      await _wishlist.loadById(activeId);
    }
  }
}
