import 'package:melist/domain/interfaces/i_subscriptions_repository.dart';
import 'package:melist/presentation/controllers/base_controller.dart';
import 'package:melist_core/melist_core.dart';

class UserSubscriptionsController extends BaseController<List<UserModel>> {
  UserSubscriptionsController({required this._repository});

  final ISubscriptionsRepository _repository;

  bool isSubscribed(int userId) => data?.any((e) => e.id == userId) ?? false;

  Future<void> load() async {
    emit(ControllerState.loading);
    try {
      data = await _repository.getMyProfileSubscriptions();
    } on Object catch (e) {
      error = e;
    }
  }

  Future<void> ensureLoaded() async {
    if (state == ControllerState.init) {
      await load();
    }
  }

  Future<void> subscribe(int userId) async {
    final user = await _repository.subscribeToProfile(
      SubscribeUserBody(userId: userId),
    );
    data = [user, ...?data?.where((e) => e.id != user.id)];
  }

  Future<void> unsubscribe(int userId) async {
    await _repository.unsubscribeProfile(userId);
    data = [...?data?.where((e) => e.id != userId)];
  }
}
