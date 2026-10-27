import 'package:melist/domain/interfaces/i_subscriptions_repository.dart';
import 'package:melist/presentation/controllers/base_controller.dart';
import 'package:melist_core/melist_core.dart';

class WishlistSubscriptionsController
    extends BaseController<List<WishlistModel>> {
  WishlistSubscriptionsController({required this._repository});

  final ISubscriptionsRepository _repository;

  bool isSubscribed(int wishlistId) =>
      data?.any((e) => e.id == wishlistId) ?? false;

  Future<void> load() async {
    emit(ControllerState.loading);
    try {
      data = await _repository.getMyWishlistSubscriptions();
    } on Object catch (e) {
      error = e;
    }
  }

  Future<void> ensureLoaded() async {
    if (state == ControllerState.init) {
      await load();
    }
  }

  Future<void> subscribe(int wishlistId) async {
    final wishlist = await _repository.subscribeToWishlist(
      SubscribeWishlistBody(wishlistId: wishlistId),
    );
    data = [wishlist, ...?data?.where((e) => e.id != wishlist.id)];
  }

  Future<void> unsubscribe(int wishlistId) async {
    await _repository.unsubscribeWishlist(wishlistId);
    data = [...?data?.where((e) => e.id != wishlistId)];
  }
}
