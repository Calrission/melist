import 'package:melist/domain/interfaces/i_wishlist_repository.dart';
import 'package:melist_core/melist_core.dart';

import 'base_controller.dart';

class WishlistFormController extends BaseController<WishlistModel> {

  final IWishlistRepository _repository;
  WishlistFormController({required this._repository});

  Future<WishlistModel?> loadById(int id) async {
    state = ControllerState.loading;
    try {
      final model = await _repository.getMyWishlistById(id);
      state = ControllerState.init;
      return model;
    } on Object catch(e) {
      error = e;
      return null;
    }
  }

  Future<void> create(CreateWishlistBody body) async {
    state = ControllerState.loading;
    try {
      data = await _repository.createWishlist(body);
    } on Object catch(e) {
      error = e;
    }
  }

  Future<void> update(int id, PatchWishlistBody body) async {
    state = ControllerState.loading;
    try {
      data = await _repository.patchWishlistById(id, body);
    } on Object catch(e) {
      error = e;
    }
  }
}