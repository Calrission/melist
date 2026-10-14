import 'package:melist/domain/interfaces/i_wish_repository.dart';
import 'package:melist/domain/interfaces/i_wishlist_repository.dart';
import 'package:melist/presentation/controllers/base_controller.dart';
import 'package:melist/presentation/controllers/wishlist_list_controller.dart';
import 'package:melist_core/melist_core.dart';

class WishlistController extends BaseController<WishlistModel> {
  WishlistController({
    required this._wishlistRepository,
    required this._wishRepository,
    required this._wishlistListController
  });

  final WishlistListController _wishlistListController;
  final IWishlistRepository _wishlistRepository;
  final IWishRepository _wishRepository;

  List<int> get currentOrder => data!.items.map((e) => e.id).toList();

  Future<void> loadById(int id) async {
    emit(ControllerState.loading);
    try {
      data = await _wishlistRepository.getMyWishlistById(id);
    } on Object catch (e) {
      error = e;
    }
  }

  Future<void> deleteWish(int wishId) async {
    try {
      await _wishRepository.deleteWishById(wishId);
      await _wishlistListController.refreshMyWishlist();
      if (data != null){
        data = data!.copyWith(
          items: data!.items.where((item) => item.id != wishId).toList()
        );
      }
    } on Object catch (e) {
      error = e;
    }
  }

  Future<void> reorderWishes(int wishlistId, List<int> order) async {
    if (state != ControllerState.loaded || data == null ||
        data!.id != wishlistId) {
      return;
    }
    final next = [...data!.items]
      ..sort((a, b) => order.indexOf(a.id) - order.indexOf(b.id));
    data = data!.copyWith(items: next);
    try {
      await _wishRepository.reorderWishesInWishlist(
        wishlistId,
        ReorderIdsBody(order: order),
      );
    } on Object catch (e) {
      error = e;
    }
  }

  void show(WishlistModel wishlist) {
    data = wishlist;
  }
}
