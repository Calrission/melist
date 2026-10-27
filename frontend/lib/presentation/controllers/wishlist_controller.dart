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

  Future<void> refresh() async {
    final current = data;
    if (current == null) {
      return;
    }
    try {
      data = await _wishlistRepository.getMyWishlistById(current.id);
    } on Object catch (e) {
      setError(e, silence: true, changeState: false);
    }
  }

  /// Removes the wish from this wishlist only; the wish stays in the catalog.
  Future<void> removeWish(int wishId) async {
    final current = data!;
    await _wishRepository.removeWishFromWishlist(current.id, wishId);
    data = current.copyWith(
      items: current.items.where((item) => item.id != wishId).toList(),
    );
    await _wishlistListController.refreshMyWishlist();
  }

  Future<void> attachWish(int wishId) async {
    final current = data!;
    await _wishRepository.addWishToWishlist(
      current.id,
      AddWishlistWishBody.attach(wishId),
    );
    await refresh();
    await _wishlistListController.refreshMyWishlist();
  }

  Future<WishlistShareModel> share() async {
    final shared = await _wishlistRepository.shareWishlist(data!.id);
    await refresh();
    return shared;
  }

  Future<void> deleteWishlist() async {
    await _wishlistRepository.deleteWishlistById(data!.id);
    await _wishlistListController.refreshMyWishlist();
    reset();
  }

  /// Drops deleted catalog wishes from the loaded card without a request.
  void dropWishes(Set<int> wishIds) {
    final current = data;
    if (current == null || !current.items.any((e) => wishIds.contains(e.id))) {
      return;
    }
    data = current.copyWith(
      items: current.items.where((e) => !wishIds.contains(e.id)).toList(),
    );
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
