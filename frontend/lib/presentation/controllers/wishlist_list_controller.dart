import 'package:melist/domain/interfaces/i_wishlist_repository.dart';
import 'package:melist/presentation/controllers/base_controller.dart';
import 'package:melist_core/melist_core.dart';

class WishlistListController extends BaseController<List<WishlistModel>> {
  WishlistListController({required this._repository});

  final IWishlistRepository _repository;

  Future<void> loadMyWishlist() async {
    emit(ControllerState.loading);
    try {
      data = await _repository.getMyWishlists();
    } on Object catch (e) {
      error = e;
    }
  }

  Future<bool> refreshMyWishlist() async {
    try {
      data = await _repository.getMyWishlists();
      return true;
    } on Object catch (e) {
      setError(e, silence: true, changeState: false);
      return false;
    }
  }

  Future<void> deleteWishlists(List<int> ids) async {
    if (state != ControllerState.loaded || data == null) {
      return;
    }
    try {
      await _repository.deleteBulkWishlistsByIds(ids);
      data = data!.where((item) => !ids.contains(item.id)).toList();
    } on Object catch (e) {
      error = e;
    }
  }

  Future<void> reorderWishlists(List<int> order) async {
    if (state != ControllerState.loaded || data == null) {
      return;
    }
    try {
      await _repository.reorderWishlists(ReorderIdsBody(order: order));
      final next = [...data!]
        ..sort((a, b) => order.indexOf(a.id) - order.indexOf(b.id));
      data = next;
    } on Object catch (e) {
      error = e;
    }
  }
}
