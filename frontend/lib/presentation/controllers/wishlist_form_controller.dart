import 'package:melist/domain/interfaces/i_wishlist_repository.dart';
import 'package:melist/presentation/controllers/base_controller.dart';
import 'package:melist/presentation/controllers/wishlist_controller.dart';
import 'package:melist/presentation/controllers/wishlist_list_controller.dart';
import 'package:melist_core/melist_core.dart';

class WishlistFormController extends BaseController<WishlistModel> {
  WishlistFormController({
    required this._repository,
    required this._wishlists,
    required this._wishlist,
  });

  final IWishlistRepository _repository;
  final WishlistListController _wishlists;
  final WishlistController _wishlist;

  Future<WishlistModel?> loadById(int id) async {
    emit(ControllerState.loading);
    try {
      final model = await _repository.getMyWishlistById(id);
      data = model;
      return model;
    } on Object catch (e) {
      error = e;
      return null;
    }
  }

  Future<bool> create(CreateWishlistBody body) async {
    emit(ControllerState.loading);
    try {
      data = await _repository.createWishlist(body);
      await _wishlists.refreshMyWishlist();
      return true;
    } on Object catch (e) {
      error = e;
      return false;
    }
  }

  Future<bool> update(int id, PatchWishlistBody body) async {
    emit(ControllerState.loading);
    try {
      data = await _repository.patchWishlistById(id, body);
      await _wishlists.refreshMyWishlist();
      final fresh = _wishlists.data?.where((item) => item.id == id).firstOrNull;
      if (fresh != null && _wishlist.data?.id == id) {
        _wishlist.show(fresh);
      }
      return true;
    } on Object catch (e) {
      error = e;
      return false;
    }
  }

  Future<bool> delete(int id) async {
    emit(ControllerState.loading);
    try {
      await _repository.deleteWishlistById(id);
      await _wishlists.refreshMyWishlist();
      if (_wishlist.data?.id == id) {
        _wishlist.reset();
      }
      return true;
    } on Object catch (e) {
      error = e;
      return false;
    }
  }
}
