import 'package:melist/domain/interfaces/i_wishlist_repository.dart';
import 'package:melist/presentation/controllers/base_controller.dart';
import 'package:melist_core/melist_core.dart';

class WishlistController extends BaseController<WishlistModel> {
  WishlistController({required this._repository});

  final IWishlistRepository _repository;

  Future<void> loadById(int id) async {
    emit(ControllerState.loading);
    try {
      data = await _repository.getMyWishlistById(id);
    } on Object catch (e) {
      error = e;
    }
  }

  void show(WishlistModel wishlist) {
    data = wishlist;
  }
}
