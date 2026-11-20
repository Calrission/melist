import 'package:melist/domain/interfaces/i_wish_repository.dart';
import 'package:melist/domain/interfaces/i_wishlist_repository.dart';
import 'package:melist/presentation/controllers/base_controller.dart';
import 'package:melist/presentation/controllers/wishes_controller.dart';
import 'package:melist/presentation/controllers/wishlist_list_controller.dart';
import 'package:melist_core/melist_core.dart';

/// Wishlist opened by a share token (`GET /api/v1/shared/{token}`).
class SharedWishlistController extends BaseController<WishlistModel> {
  SharedWishlistController({
    required this._wishlistRepository,
    required this._wishRepository,
    required this._wishlists,
    required this._wishes,
  });

  final IWishlistRepository _wishlistRepository;
  final IWishRepository _wishRepository;
  final WishlistListController _wishlists;
  final WishesController _wishes;

  String? _token;
  String? get token => _token;

  Future<void> reserveWish(int wishId) async {
    final token = _token;
    if (token == null || token.isEmpty) {
      return;
    }
    _replaceItem(await _wishlistRepository.reserveSharedWish(token, wishId));
  }

  Future<void> cancelReservation(int wishId) async {
    final token = _token;
    if (token == null || token.isEmpty) {
      return;
    }
    _replaceItem(
      await _wishlistRepository.cancelSharedWishReservation(token, wishId),
    );
  }

  void _replaceItem(WishModel wish) {
    final current = data;
    if (current == null) {
      return;
    }
    data = current.copyWith(
      items: [
        for (final item in current.items)
          if (item.id == wish.id) wish else item,
      ],
    );
  }

  Future<void> loadByToken(String token) async {
    _token = token;
    emit(ControllerState.loading);
    try {
      data = await _wishlistRepository.getSharedWishlist(token);
    } on Object catch (e) {
      error = e;
    }
  }

  /// Reloads the open list without replacing it with a spinner.
  Future<void> reload() async {
    final token = _token;
    if (token == null || token.isEmpty) {
      return;
    }
    try {
      final fresh = await _wishlistRepository.getSharedWishlist(token);
      if (_token != token) {
        return;
      }
      data = fresh;
    } on Object catch (error) {
      setError(error, silence: true, changeState: false);
    }
  }

  Future<void> copyWishTo(int wishId, int targetWishlistId) async {
    await _wishRepository.addWishToWishlist(
      targetWishlistId,
      AddWishlistWishBody.copy(wishId),
    );
    await _wishlists.refreshMyWishlist();
    await _wishes.refresh();
  }
}
